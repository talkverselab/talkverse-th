#!/usr/bin/env python3
"""두 화면 확인 스크린샷: integration_test/two_pane_test.dart 를 flutter drive 로 돌리며
'SHOT:<이름>' 줄이 나올 때마다 xcrun simctl io screenshot 으로 찍는다(한자유니버스 tools/store_shots.py 와 같음).
사용: python3 tools/pane_shots.py <UDID> <출력폴더> [대상 테스트]"""
import os, subprocess, sys

udid, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
env = dict(os.environ, PATH='/opt/homebrew/bin:' + os.environ.get('PATH', ''))
cmd = ['flutter', 'drive', '--driver=test_driver/integration_test.dart',
       '--target=' + (sys.argv[3] if len(sys.argv) > 3 else 'integration_test/two_pane_test.dart'), '-d', udid]
p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env, text=True, bufsize=1,
                     cwd=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
for line in p.stdout:
    sys.stdout.write(line); sys.stdout.flush()
    if 'SHOT:' in line:
        name = line.split('SHOT:', 1)[1].strip()
        path = os.path.join(out, name + '.png')
        subprocess.run(['xcrun', 'simctl', 'io', udid, 'screenshot', '--type=png', path], check=False)
        print(f'>>> saved {path}', flush=True)
sys.exit(p.wait())
