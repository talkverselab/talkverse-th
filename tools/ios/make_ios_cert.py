"""App Store Connect API 키로 iOS 배포 준비를 한 번에 한다 (맥 없이, Windows 에서).

    python -X utf8 make_ios_cert.py --key-id XXXX --issuer-id UUID --p8 AuthKey_XXXX.p8 \
        --bundle-id com.talkverse.thaiUniverse --app-name "태국어유니버스" --out ./out

하는 일
  1. 번들 ID 등록 (없으면)  — POST /v1/bundleIds
  2. 배포 인증서 발급        — openssl 로 개인키+CSR 생성 → POST /v1/certificates (IOS_DISTRIBUTION)
  3. .p12 로 묶기 (비밀번호 자동 생성) + GitHub 시크릿용 base64 파일들
결과물: out/dist.p12, out/secrets.txt (시크릿 이름=값), out/private_key.pem (보관용)
"""
import argparse
import base64
import io
import json
import os
import secrets
import subprocess
import sys
import time

import jwt
import requests

API = "https://api.appstoreconnect.apple.com/v1"


def token(key_id, issuer_id, p8_path):
    key = io.open(p8_path, encoding="utf-8").read()
    now = int(time.time())
    return jwt.encode({"iss": issuer_id, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": key_id, "typ": "JWT"})


def call(tok, method, path, body=None):
    r = requests.request(method, API + path, headers={"Authorization": "Bearer " + tok,
                                                      "Content-Type": "application/json"},
                         data=json.dumps(body) if body else None, timeout=60)
    if r.status_code >= 400:
        sys.exit(f"{method} {path} → {r.status_code}\n{r.text[:800]}")
    return r.json() if r.text else {}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--key-id", required=True)
    ap.add_argument("--issuer-id", required=True)
    ap.add_argument("--p8", required=True)
    ap.add_argument("--bundle-id", required=True)
    ap.add_argument("--app-name", required=True)
    ap.add_argument("--out", default="out")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    tok = token(a.key_id, a.issuer_id, a.p8)

    # 0) 팀 확인
    me = call(tok, "GET", "/users?limit=1")
    print("API 연결 OK")

    # 1) 번들 ID
    found = call(tok, "GET", f"/bundleIds?filter[identifier]={a.bundle_id}&filter[platform]=IOS")
    if found.get("data"):
        bid = found["data"][0]
        print("번들 ID 이미 있음:", bid["attributes"]["identifier"], "seed", bid["attributes"].get("seedId"))
    else:
        bid = call(tok, "POST", "/bundleIds", {"data": {"type": "bundleIds", "attributes": {
            "identifier": a.bundle_id, "name": a.app_name.replace(" ", ""), "platform": "IOS"}}})["data"]
        print("번들 ID 등록:", a.bundle_id)
    team_id = bid["attributes"].get("seedId", "")

    # 2) 개인키 + CSR
    pem = os.path.join(a.out, "private_key.pem")
    csr = os.path.join(a.out, "request.csr")
    subprocess.run(["openssl", "genrsa", "-out", pem, "2048"], check=True, capture_output=True)
    subprocess.run(["openssl", "req", "-new", "-key", pem, "-out", csr,
                    "-subj", "/CN=Talkverse iOS Distribution/O=Talkverse/C=KR"], check=True, capture_output=True)
    csr_txt = io.open(csr, encoding="utf-8").read()
    body = "".join(l for l in csr_txt.splitlines() if not l.startswith("-----"))

    # 3) 배포 인증서
    cert = call(tok, "POST", "/certificates", {"data": {"type": "certificates", "attributes": {
        "certificateType": "IOS_DISTRIBUTION", "csrContent": body}}})["data"]
    cer = os.path.join(a.out, "distribution.cer")
    io.open(cer, "wb").write(base64.b64decode(cert["attributes"]["certificateContent"]))
    print("배포 인증서 발급:", cert["attributes"]["name"], "만료", cert["attributes"]["expirationDate"][:10])

    # 4) .p12
    p12 = os.path.join(a.out, "dist.p12")
    pw = secrets.token_urlsafe(18)
    subprocess.run(["openssl", "x509", "-inform", "DER", "-in", cer, "-out", cer + ".pem"], check=True, capture_output=True)
    subprocess.run(["openssl", "pkcs12", "-export", "-legacy", "-inkey", pem, "-in", cer + ".pem", "-out", p12,
                    "-passout", "pass:" + pw, "-name", "Apple Distribution"], check=True, capture_output=True)

    # 5) 시크릿 파일
    p8_b64 = base64.b64encode(io.open(a.p8, "rb").read()).decode()
    p12_b64 = base64.b64encode(io.open(p12, "rb").read()).decode()
    lines = [
        f"APPLE_TEAM_ID={team_id}",
        f"ASC_KEY_ID={a.key_id}",
        f"ASC_ISSUER_ID={a.issuer_id}",
        f"ASC_KEY_P8_BASE64={p8_b64}",
        f"IOS_DIST_P12_PASSWORD={pw}",
        f"IOS_DIST_P12_BASE64={p12_b64}",
    ]
    io.open(os.path.join(a.out, "secrets.txt"), "w", encoding="utf-8", newline="").write("\n".join(lines) + "\n")
    print("완료 →", a.out, "(secrets.txt · dist.p12 · private_key.pem)  팀ID:", team_id)


if __name__ == "__main__":
    main()
