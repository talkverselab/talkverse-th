import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/thai_font.dart';
import '../core/theme.dart';
import '../screens/dialogue_card_screen.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';
import '../services/dialogue_service.dart';
import '../services/learner_prefs.dart';
import '../services/tts_service.dart';
import 'learner_setup_dialog.dart';
import '../services/ko_reading.dart';
import 'lemma_chips.dart';
import 'lemma_text.dart';

/// 태국어 본문 글꼴(설정의 태국어 폰트 적용) — 다른 위젯도 같은 헬퍼를 쓴다.
TextStyle thStyle({double fontSize = 16, FontWeight fontWeight = FontWeight.w800, Color color = AppColors.khram, double height = 1.35}) =>
    TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color, height: height, fontFamily: ThaiFontPrefs.family, fontFamilyFallback: AppTheme.fontFallback);

const List<BoxShadow> kCutShadow = [BoxShadow(color: Color(0x1A5A3E28), blurRadius: 8, offset: Offset(0, 3), spreadRadius: -1)];

/// 「모든 문장 듣기」 재생 패널 — Grok UXUI 시안 02 「만화책 읽기형」(일본어앱에서 이식, 2026-11-03).
///
/// 장면 컷이 주인공. 아이패드(가로 720 이상): 왼쪽 = 대화 스크립트 목록, 오른쪽 = 큰 장면 컷(말풍선) + 현재 문장 캡션.
/// 폰: 장면 컷이 위, 스크립트가 아래. 하단 고정 컨트롤 = ▶ 재생 · 진행 슬라이더 · 속도 · 자막 단계(ไทย/독음/한국어).
/// 그림: uk 장면 컷(`/art/th/scene`) → 턴 `art` → 핵심 단어 그림 → 장면 카드.
/// `autoPlay: false` 면 편 화면(읽기 모드)으로도 쓴다 — 같은 레이아웃에서 ▶ 를 누르면 순차 재생.
class EpisodePlayPane extends StatefulWidget {
  final Dialogue dialogue;
  final int initialIndex;
  final bool autoPlay;
  const EpisodePlayPane({super.key, required this.dialogue, this.initialIndex = 0, this.autoPlay = true});

  @override
  State<EpisodePlayPane> createState() => _EpisodePlayPaneState();
}

class _EpisodePlayPaneState extends State<EpisodePlayPane> {
  late int _i = widget.initialIndex;
  bool _playing = false;
  double _rate = 1.0; // 0.75 / 1.0 / 1.25
  bool get _showRd => KoReadingPrefs.show.value; // 전역 독음 설정(기본 미표시)
  bool _showKo = true;
  int _session = 0; // 재생 루프 세대(중단 판별)
  bool _done = false; // 완주 연출 표시
  bool _firstDone = false;
  late final List<GlobalKey> _keys = List.generate(widget.dialogue.turns.length, (_) => GlobalKey());

  Dialogue get d => widget.dialogue;
  DialogueTurn get turn => d.turns[_i];

  void _onReading() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    KoReadingPrefs.show.addListener(_onReading);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 대사에 {name} 자리가 있는데 이름이 없으면 먼저 묻는다(앱 켠 뒤 한 번, 2026-11-04)
      await ensureLearnerName(context, needed: widget.dialogue.turns.any((t) => t.th.contains('{name}')));
      if (mounted) setState(() {});
      if (widget.autoPlay && mounted) _play();
    });
  }

  @override
  void dispose() {
    KoReadingPrefs.show.removeListener(_onReading);
    _session++;
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _play() async {
    final my = ++_session;
    setState(() => _playing = true);
    while (mounted && my == _session && _i < d.turns.length) {
      final t = d.turns[_i];
      _scrollTo(_i);
      final text = _ttsText(t);
      if (text.isNotEmpty) {
        await TtsService.instance.speakAndWait(text, gender: _gender(t.speaker), rate: _rate * 0.45);
      } else {
        await Future.delayed(const Duration(milliseconds: 900)); // 침묵 턴
      }
      if (!mounted || my != _session) return;
      await Future.delayed(Duration(milliseconds: (650 / _rate).round())); // 턴 사이 숨
      if (!mounted || my != _session) return;
      if (_i >= d.turns.length - 1) {
        final first = await DialogueService.instance.markDone(d.id);
        if (mounted && my == _session) setState(() { _done = true; _firstDone = first; });
        break;
      }
      setState(() => _i++);
    }
    if (mounted && my == _session) setState(() => _playing = false);
  }

  void _pause() {
    _session++;
    TtsService.instance.stop();
    setState(() => _playing = false);
  }

  void _goto(int n, {bool play = false}) {
    n = n.clamp(0, d.turns.length - 1);
    _session++;
    TtsService.instance.stop();
    setState(() {
      _i = n;
      _playing = false;
    });
    _scrollTo(n);
    if (play) _play();
  }

  void _speakOne(DialogueTurn t) {
    final s = _ttsText(t);
    if (s.isNotEmpty) TtsService.instance.speakAs(s, gender: _gender(t.speaker), rate: _rate * 0.45);
  }

  void _scrollTo(int i) {
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.3);
  }

  /// TTS 용 본문: 괄호 지시·{name} 자리·555(웃음) 제거.
  static String _ttsText(DialogueTurn t) {
    var s = LearnerPrefs.fill(t.th).replaceAll(RegExp(r'[（(][^)）]*[)）]'), '');
    s = s.replaceAll(RegExp(r'5{3,}'), 'ฮ่าๆ').replaceAll(RegExp(r'[…~]+'), ' ').trim();
    return s;
  }

  String _gender(String sp) => LearnerPrefs.voiceGender(sp); // A = 학습자 프로필 성별

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final script = _Script(
      d: d,
      current: _i,
      keys: _keys,
      showRd: _showRd,
      showKo: _showKo,
      onTap: (i) => _goto(i, play: true),
      onSpeak: _speakOne,
    );
    final cut = _CutPanel(d: d, turn: turn, showRd: _showRd, showKo: _showKo, onSpeak: () => _speakOne(turn));
    final controls = _ControlBar(
      playing: _playing,
      index: _i,
      total: d.turns.length,
      rate: _rate,
      showRd: _showRd,
      showKo: _showKo,
      onPlay: _playing ? _pause : _play,
      onSeek: (v) => _goto(v),
      onRate: () => setState(() => _rate = _rate >= 1.25 ? 0.75 : (_rate + 0.25)),
      onRd: () => KoReadingPrefs.switchShown(context),
      onKo: () => setState(() => _showKo = !_showKo),
    );
    return LayoutBuilder(builder: (context, c) {
      final sideBySide = wide && c.maxWidth >= 900;
      final body = Column(children: [
        Expanded(
          child: sideBySide
              ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 4, child: script),
                  const VerticalDivider(width: 1, color: AppColors.thong),
                  Expanded(flex: 6, child: cut),
                ])
              : Column(children: [
                  SizedBox(height: (c.maxHeight * 0.44).clamp(240, 520), child: cut),
                  const Divider(height: 1, color: AppColors.thong),
                  Expanded(child: script),
                ]),
        ),
        controls,
      ]);
      if (!_done) return body;
      return Stack(fit: StackFit.expand, children: [
        body,
        _DoneOverlay(
          dialogue: d,
          firstTime: _firstDone,
          onCards: () {
            setState(() => _done = false);
            openFull(context, (_) => DialogueCardScreen(dialogue: d));
          },
          onClose: () => setState(() => _done = false),
        ),
      ]);
    });
  }
}

/// 완주 연출(시안 02: 확대·구리빛, 폭죽 없음).
class _DoneOverlay extends StatelessWidget {
  final Dialogue dialogue;
  final bool firstTime;
  final VoidCallback onCards, onClose;
  const _DoneOverlay({required this.dialogue, required this.firstTime, required this.onCards, required this.onClose});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onClose,
        child: Container(
          color: AppColors.khram.withValues(alpha: 0.35),
          alignment: Alignment.center,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.kluayMai, width: 1.6), boxShadow: kCutShadow),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(dialogue.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(tr(firstTime ? '첫 완주!' : '완주'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.kluayMaiDeep)),
                const SizedBox(height: 4),
                Text(dialogue.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.khram)),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onCards,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.kluayMai, foregroundColor: Colors.white, shape: const StadiumBorder()),
                  icon: const Icon(Icons.style_outlined, size: 18),
                  label: Text(tr('그림 카드로 복습'), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                TextButton(onPressed: onClose, child: Text(tr('닫기'), style: const TextStyle(color: AppColors.thongDeep))),
              ]),
            ),
          ),
        ),
      );
}

/// 왼쪽 「대화 스크립트」 목록.
class _Script extends StatelessWidget {
  final Dialogue d;
  final int current;
  final List<GlobalKey> keys;
  final bool showRd, showKo;
  final void Function(int) onTap;
  final void Function(DialogueTurn) onSpeak;
  const _Script({required this.d, required this.current, required this.keys, required this.showRd, required this.showKo, required this.onTap, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(children: [
          const Icon(Icons.volume_up_outlined, size: 16, color: AppColors.khram),
          const SizedBox(width: 6),
          Text(tr('대화 스크립트'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.khram)),
          const Spacer(),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.khram, width: 1.2)),
            child: Text('${d.turns.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.khram)),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 12 + bottomInset(context)),
          itemCount: d.turns.length,
          itemBuilder: (context, i) {
            final t = d.turns[i];
            final on = i == current;
            final me = t.speaker == 'A';
            return Padding(
              key: keys[i],
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                  decoration: BoxDecoration(
                    color: on ? AppColors.kluayMai.withValues(alpha: 0.09) : AppColors.cream,
                    border: Border.all(color: on ? AppColors.kluayMai : AppColors.thong, width: on ? 1.6 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${t.num}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: on ? AppColors.kluayMai : AppColors.thongDeep, height: 1.5)),
                    const SizedBox(width: 8),
                    _SpeakerDot(name: d.speakerName(t.speaker), me: me, on: on),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        LemmaText(turn: t, text: LearnerPrefs.fill(t.th), style: thStyle(fontSize: on ? 17 : 15.5)),
                        if (showRd && t.rd.isNotEmpty) KoReadingText(LearnerPrefs.fill(t.rd, ko: true), th: t.th, style: const TextStyle(fontSize: 11.5, color: AppColors.thongDeep)),
                        if (showKo) Text(LearnerPrefs.fill(t.ko, ko: true), style: const TextStyle(fontSize: 12.5, color: AppColors.khramLight, height: 1.35)),
                        if (on && t.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('💡 ${t.note}', style: const TextStyle(fontSize: 11, color: AppColors.kluayMaiDeep, height: 1.35))),
                      ]),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onSpeak(t),
                      icon: Icon(Icons.volume_up_outlined, size: 18, color: on ? AppColors.kluayMai : AppColors.khram),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _SpeakerDot extends StatelessWidget {
  final String name;
  final bool me, on;
  const _SpeakerDot({required this.name, required this.me, required this.on});
  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: me ? AppColors.kluayMai : AppColors.khram),
        child: Text(me ? 'A' : (name.isEmpty ? '?' : name.characters.first), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: ThaiFontPrefs.family, fontFamilyFallback: AppTheme.fontFallback)),
      );
}

/// 오른쪽(또는 위) 장면 컷 + 캡션.
class _CutPanel extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn turn;
  final bool showRd, showKo;
  final VoidCallback onSpeak;
  const _CutPanel({required this.d, required this.turn, required this.showRd, required this.showKo, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 16 : 12, 10, wide ? 16 : 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (wide)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.image_outlined, size: 16, color: AppColors.khram),
              const SizedBox(width: 6),
              Text(tr('회화 장면'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.khram)),
              const Spacer(),
              Text(d.speakerName(turn.speaker), style: TextStyle(fontSize: 11, color: AppColors.thongDeep, fontWeight: FontWeight.w700, fontFamily: ThaiFontPrefs.family, fontFamilyFallback: AppTheme.fontFallback)),
            ]),
          ),
        Expanded(child: SceneCut(dialogue: d, turn: turn)), // 문장은 아래 _Caption 에(그림을 덮지 않음, 2026-11-04)
        const SizedBox(height: 10),
        _Caption(d: d, turn: turn, showRd: showRd, showKo: showKo, onSpeak: onSpeak),
      ]),
    );
  }
}

/// 현재 문장 캡션.
class _Caption extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn turn;
  final bool showRd, showKo;
  final VoidCallback onSpeak;
  const _Caption({required this.d, required this.turn, required this.showRd, required this.showKo, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(turn.num),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, wide ? 12 : 10, 12, wide ? 12 : 10),
        decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.kluayMai, width: 1.3), borderRadius: BorderRadius.circular(14), boxShadow: kCutShadow),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LemmaText(turn: turn, text: LearnerPrefs.fill(turn.th), style: thStyle(fontSize: wide ? 21 : 18)),
              if (showRd && turn.rd.isNotEmpty) KoReadingText(LearnerPrefs.fill(turn.rd, ko: true), th: turn.th, style: const TextStyle(fontSize: 12.5, color: AppColors.thongDeep)),
              if (showKo) Padding(padding: const EdgeInsets.only(top: 2), child: Text(LearnerPrefs.fill(turn.ko, ko: true), style: const TextStyle(fontSize: 13.5, color: AppColors.khramLight, height: 1.35))),
              if (turn.lemmas.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: LemmaChips(turn: turn, compact: !wide)),
            ]),
          ),
          IconButton(onPressed: onSpeak, icon: const Icon(Icons.volume_up, color: AppColors.kluayMai, size: 26)),
        ]),
      ),
    );
  }
}

/// 하단 고정 컨트롤: ▶ 재생 · 진행 슬라이더 · 속도 · 자막 단계.
class _ControlBar extends StatelessWidget {
  final bool playing, showRd, showKo;
  final int index, total;
  final double rate;
  final VoidCallback onPlay, onRate, onRd, onKo;
  final ValueChanged<int> onSeek;
  const _ControlBar({
    required this.playing,
    required this.index,
    required this.total,
    required this.rate,
    required this.showRd,
    required this.showKo,
    required this.onPlay,
    required this.onSeek,
    required this.onRate,
    required this.onRd,
    required this.onKo,
  });

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    Widget chip(String t, bool on, VoidCallback? tap, {bool fixed = false}) => Padding(
          padding: const EdgeInsets.only(left: 6),
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: fixed ? AppColors.kluayMai : (on ? AppColors.sunset.withValues(alpha: 0.12) : Colors.transparent),
                border: Border.all(color: fixed ? AppColors.kluayMai : (on ? AppColors.sunset : AppColors.thong)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fixed ? Colors.white : (on ? AppColors.sunsetDeep : AppColors.thongDeep), fontFamily: ThaiFontPrefs.family, fontFamilyFallback: AppTheme.fontFallback)),
            ),
          ),
        );
    final rateLabel = '${rate.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}x';
    final playBtn = Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: playing ? AppColors.kluayMai : AppColors.cream, border: Border.all(color: AppColors.kluayMai, width: 1.6)),
          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: playing ? Colors.white : AppColors.kluayMai, size: 28),
        ),
      ),
      const SizedBox(width: 8),
      Text(playing ? tr('일시정지') : tr('재생'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.khram)),
    ]);
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbColor: AppColors.kluayMai, activeTrackColor: AppColors.kluayMai, inactiveTrackColor: AppColors.thong, overlayShape: SliderComponentShape.noOverlay, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
      child: Slider(value: index.toDouble(), min: 0, max: (total - 1).clamp(1, 999).toDouble(), divisions: total > 1 ? total - 1 : 1, onChanged: (v) => onSeek(v.round())),
    );
    final subs = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(tr('자막'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.khram)),
      const SizedBox(width: 4),
      chip('ไทย', true, null, fixed: true),
      chip(tr('독음'), showRd, onRd),
      chip(tr('한국어'), showKo, onKo),
    ]);
    final speed = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(tr('속도'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.khram)),
      chip(rateLabel, true, onRate),
    ]);
    return LayoutBuilder(builder: (context, c) => Container(
      padding: EdgeInsets.fromLTRB(16, 8, 12, 8 + bottomInset(context)),
      decoration: const BoxDecoration(color: AppColors.cream, border: Border(top: BorderSide(color: AppColors.thong))),
      child: wide && c.maxWidth >= 900
          ? Row(children: [
              playBtn,
              const SizedBox(width: 10),
              Expanded(child: slider),
              Text('${index + 1}/$total', style: const TextStyle(fontSize: 11, color: AppColors.thongDeep)),
              const SizedBox(width: 12),
              speed,
              const SizedBox(width: 10),
              subs,
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [playBtn, const SizedBox(width: 6), Expanded(child: slider), Text('${index + 1}/$total', style: const TextStyle(fontSize: 11, color: AppColors.thongDeep))]),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [speed, const SizedBox(width: 8), subs])),
            ]),
    ));
  }
}

/// 장면 컷: 장면 그림 → 단어 그림 → 장면 카드. 둥근 틀, 컷 전환 400ms 페이드. `bubble` 이면 현재 대사를 그림 **아래 띠**로(그림을 덮지 않음 — 사용자 지시 2026-11-04).
class SceneCut extends StatelessWidget {
  final Dialogue dialogue;
  final DialogueTurn turn;
  final bool bubble;
  const SceneCut({super.key, required this.dialogue, required this.turn, this.bubble = false});

  Future<_ArtPick?> _pick() async {
    // 1) 장면 컷(uk /art/th/scene, A·B 한 쌍당 1장) → 2) 턴 art → 3) 단어 그림 → 4) 장면 카드
    final scene = await ArtService.instance.sceneCut(dialogue.id, turn.num, large: true);
    if (scene != null) return _ArtPick(scene, null);
    if (turn.art != null) return _ArtPick(turn.art!, null);
    for (final w in turn.pictureWords) {
      final u = await ArtService.instance.urlFor(w);
      if (u != null) return _ArtPick(u, w);
    }
    final inText = await ArtService.instance.urlInText(turn.th);
    if (inText != null) return _ArtPick(inText.value, inText.key);
    if (dialogue.art != null) return _ArtPick(dialogue.art!, null);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final me = turn.speaker == 'A';
    return FutureBuilder<_ArtPick?>(
      key: ValueKey('${dialogue.id}:${turn.num}'),
      future: _pick(),
      builder: (context, snap) {
        final p = snap.data;
        final pic = Stack(fit: StackFit.expand, children: [
          if (p == null)
            _SceneCard(dialogue: dialogue, turn: turn)
          else
            Image(image: artProvider(p.url), fit: p.word == null ? BoxFit.cover : BoxFit.contain, errorBuilder: (_, _, _) => _SceneCard(dialogue: dialogue, turn: turn)),
          if (p?.word != null)
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.cream.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.thong)),
                child: Text(p!.word!, style: thStyle(fontSize: 14)),
              ),
            ),
        ]);
        return LayoutBuilder(builder: (context, c) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey('${turn.num}:${p?.url}'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.creamDeep, border: Border.all(color: AppColors.thong), borderRadius: BorderRadius.circular(18), boxShadow: kCutShadow),
            child: bubble && turn.th.trim().isNotEmpty
                ? Column(children: [
                    Expanded(child: pic),
                    _LineStrip(speaker: dialogue.speakerName(turn.speaker), me: me, text: LearnerPrefs.fill(turn.th), small: c.maxHeight < 220),
                  ])
                : pic,
          ),
        ));
      },
    );
  }
}

/// 그림 아래 대사 띠 — 화자 이름(학습자 = 포인트색) + 한 줄. 그림을 덮지 않는다(오버레이 말풍선 금지, 2026-11-04).
class _LineStrip extends StatelessWidget {
  final String speaker;
  final bool me;
  final String text;
  final bool small;
  const _LineStrip({required this.speaker, required this.me, required this.text, this.small = false});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, small ? 6 : 8, 12, small ? 6 : 8),
        decoration: const BoxDecoration(color: AppColors.cream, border: Border(top: BorderSide(color: AppColors.thong))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 3, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: me ? AppColors.kluayMai : AppColors.khram, borderRadius: BorderRadius.circular(8)),
            child: Text(speaker, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: ThaiFontPrefs.family, fontFamilyFallback: AppTheme.fontFallback)),
          ),
          Expanded(child: Text(text, maxLines: small ? 2 : 3, overflow: TextOverflow.ellipsis, style: thStyle(fontSize: small ? 12.5 : 15))),
        ]),
      );
}

class _ArtPick {
  final String url;
  final String? word;
  const _ArtPick(this.url, this.word);
}

/// 그림이 없을 때의 장면 카드(이모지 + 장면 한 줄 + 화자).
class _SceneCard extends StatelessWidget {
  final Dialogue dialogue;
  final DialogueTurn turn;
  const _SceneCard({required this.dialogue, required this.turn});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final small = c.maxHeight < 220; // 홈 「오늘의 컷」 같은 작은 틀
      return Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFF8F3), Color(0xFFF4E4C8)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        padding: EdgeInsets.fromLTRB(14, small ? 44 : 18, 14, 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(turn.stamp ?? dialogue.emoji, style: TextStyle(fontSize: small ? 34 : 56)),
          SizedBox(height: small ? 4 : 10),
          Flexible(child: Text(dialogue.scene, textAlign: TextAlign.center, maxLines: small ? 2 : 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: small ? 11 : 13, color: AppColors.khramLight, height: 1.4))),
          if (!small) ...[
            const SizedBox(height: 6),
            Text(dialogue.speakerName(turn.speaker), style: thStyle(fontSize: 12, color: AppColors.kluayMai)),
          ],
        ]),
      );
    });
  }
}
