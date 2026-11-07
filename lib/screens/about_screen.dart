import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../widgets/thai_decor.dart';
import '../services/cliff_service.dart';

/// 앱 소개 — 이 앱의 뼈대인 **절벽구간**을 설명한다(사용자 지시 2026-11-07, 모든 언어앱 공통: 왼쪽 레일 맨 아래 「앱 소개」, 폰은 프로필 → 정보).
/// 1. 단어 기준  2. 산출 방식  3. 앱에서 쓰는 곳. 태국어는 글자 하나로 세는 문자 기준이 없어 그 절은 뺐다.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('앱 소개'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(tr('절벽구간 — 이 앱이 단어를 나누는 기준'), style: const TextStyle(fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
        children: [
          _Lead(text: tr('태국 드라마 대사에서 자주 나오는 말은 아주 적습니다. 처음 109개 단어가 대사의 55%를 차지하고, 642개면 80%입니다. 그 뒤로는 단어를 아무리 더 외워도 들리는 비율이 조금씩만 늘어납니다. 이 꺾이는 지점을 「절벽」이라 부르고, 앱의 단어와 회화를 이 구간으로 나눕니다.')),
          const SizedBox(height: 18),
          _H(tr('1. 단어 기준')),
          const _CliffTable(),
          const SizedBox(height: 18),
          _H(tr('2. 산출 방식')),
          _Para(tr('말뭉치 — 태국에서 제작한 드라마의 대사 50편(26만 토큰). 소리 설명·기호·숫자는 뺐습니다.')),
          _Para(tr('빈도 — 각 단어의 등장 횟수 ÷ 전체 등장 횟수. 가중치 없음.')),
          _Para(tr('구간 — 빈도순으로 누적해 55%·60%·70%·80%에 닿는 순위가 R1·R2·R3·R4 의 끝. 80% 밖은 R5. 이 네 비율은 Talkverse 19개 언어 공통 기준입니다.')),
          const SizedBox(height: 18),
          _H(tr('3. 앱에서 쓰는 곳')),
          _Para(tr('절벽 단어 — R1→R5 순서로 20어씩 한 단원. 「회화 단어 포함」을 누르면 이 앱의 회화에 나오는 단어가 「회화」 구간으로 뒤에 붙습니다.')),
          _Para(tr('회화 — 레벨을 이 구간에 맞췄습니다. 낮은 레벨일수록 앞 구간의 단어로 말합니다.')),
          const SizedBox(height: 24),
          const SilkDivider(),
        ],
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  final String text;
  const _Lead({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.creamDeep,
          border: Border.all(color: AppColors.thong),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(color: AppColors.khram, fontSize: 14, height: 1.6)),
      );
}

class _H extends StatelessWidget {
  final String text;
  const _H(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.khram, fontSize: 16, fontWeight: FontWeight.w800)),
      );
}

class _Para extends StatelessWidget {
  final String text;
  const _Para(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.khramLight, fontSize: 13, height: 1.55)),
      );
}

/// 구간표 — 5줄(R1~R5): 순위 범위 · 개수 · 누적 %. 막대는 구간 등폭 5칸.
class _CliffTable extends StatelessWidget {
  const _CliffTable();

  static const _pct = [55, 60, 70, 80];

  @override
  Widget build(BuildContext context) {
    final colors = [for (var i = 1; i <= 5; i++) CliffService.colorOf('R$i')];
    final unit = tr('어');
    final rows = <(String, String, String, String)>[];
    var prev = 0;
    for (var i = 0; i < 4; i++) {
      final end = kWordCliffs[i];
      rows.add(('R${i + 1}', '${prev + 1}-$end', '${end - prev}$unit', '${_pct[i]}%'));
      prev = end;
    }
    rows.add(('R5', '${prev + 1}-$kWordCap', '${kWordCap - prev}$unit', '$kWordCapPct%'));
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.thong), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: Container(
                      height: 10,
                      margin: EdgeInsets.only(right: i < 4 ? 2 : 0),
                      decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.thong, width: i == 0 ? 0 : 0.6))),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(3)),
                    child: Text(rows[i].$1, style: TextStyle(color: AppColors.onFill(colors[i]), fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(rows[i].$2, style: const TextStyle(color: AppColors.khram, fontSize: 13, fontWeight: FontWeight.w700))),
                  SizedBox(width: 64, child: Text(rows[i].$3, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.khramLight, fontSize: 12))),
                  SizedBox(
                    width: 72,
                    child: Text(trf('누적 {0}', [rows[i].$4]), textAlign: TextAlign.right, style: const TextStyle(color: AppColors.khram, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Text(tr('띄어쓰기가 없는 태국어를 낱말로 나눠 셉니다. R5 는 2,000위에서 끊습니다(누적 91.6%).'),
                style: const TextStyle(color: AppColors.khramLight, fontSize: 11, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
