import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/tts_service.dart';
import '../widgets/thai_decor.dart';

/// 키보드연습 — 태국어 Kedmanee 자판.
///
/// 목표 텍스트를 보고 입력하면 다음에 눌러야 할 키가
/// 화면 자판에서 하이라이트된다 (Shift 층 포함).
class KeyboardPracticeScreen extends StatefulWidget {
  const KeyboardPracticeScreen({super.key});

  @override
  State<KeyboardPracticeScreen> createState() =>
      _KeyboardPracticeScreenState();
}

/// Kedmanee 표준 배열 — [normal, shift] per physical key.
class _Key {
  final String label; // 물리 키 (표시용, 라틴)
  final String normal;
  final String shift;
  const _Key(this.label, this.normal, this.shift);
}

const List<List<_Key>> _kedmanee = [
  [
    _Key('`', '_', '%'),
    _Key('1', 'ๅ', '+'),
    _Key('2', '/', '๑'),
    _Key('3', '-', '๒'),
    _Key('4', 'ภ', '๓'),
    _Key('5', 'ถ', '๔'),
    _Key('6', 'ุ', 'ู'),
    _Key('7', 'ึ', '฿'),
    _Key('8', 'ค', '๕'),
    _Key('9', 'ต', '๖'),
    _Key('0', 'จ', '๗'),
    _Key('-', 'ข', '๘'),
    _Key('=', 'ช', '๙'),
  ],
  [
    _Key('Q', 'ๆ', '๐'),
    _Key('W', 'ไ', '"'),
    _Key('E', 'ำ', 'ฎ'),
    _Key('R', 'พ', 'ฑ'),
    _Key('T', 'ะ', 'ธ'),
    _Key('Y', 'ั', 'ํ'),
    _Key('U', 'ี', '๊'),
    _Key('I', 'ร', 'ณ'),
    _Key('O', 'น', 'ฯ'),
    _Key('P', 'ย', 'ญ'),
    _Key('[', 'บ', 'ฐ'),
    _Key(']', 'ล', ','),
    _Key('\\', 'ฃ', 'ฅ'),
  ],
  [
    _Key('A', 'ฟ', 'ฤ'),
    _Key('S', 'ห', 'ฆ'),
    _Key('D', 'ก', 'ฏ'),
    _Key('F', 'ด', 'โ'),
    _Key('G', 'เ', 'ฌ'),
    _Key('H', '้', '็'),
    _Key('J', '่', '๋'),
    _Key('K', 'า', 'ษ'),
    _Key('L', 'ส', 'ศ'),
    _Key(';', 'ว', 'ซ'),
    _Key("'", 'ง', '.'),
  ],
  [
    _Key('Z', 'ผ', '('),
    _Key('X', 'ป', ')'),
    _Key('C', 'แ', 'ฉ'),
    _Key('V', 'อ', 'ฮ'),
    _Key('B', 'ิ', 'ฺ'),
    _Key('N', 'ื', '์'),
    _Key('M', 'ท', '?'),
    _Key(',', 'ม', 'ฒ'),
    _Key('.', 'ใ', 'ฬ'),
    _Key('/', 'ฝ', 'ฦ'),
  ],
];

/// 연습 코스.
class _Course {
  final String name;
  final String desc;
  final List<String> targets;
  const _Course(this.name, this.desc, this.targets);
}

const List<_Course> _courses = [
  _Course('자리 익히기', '기본 열(홈 로우)부터 자모 위치', [
    'ฟหกด',
    'สวาง',
    'เ้่า',
    'พะัี',
    'รนยบ',
    'ผปแอ',
    'ิืทม',
    'คตจข',
  ]),
  _Course('필수 단어', '여행·일상 최다 빈출 단어', [
    'สวัสดี',
    'ขอบคุณ',
    'อร่อย',
    'เท่าไหร่',
    'ไม่เป็นไร',
    'รถติด',
    'กินข้าว',
    'คิดถึง',
  ]),
  _Course('실전 문장', 'L1 다이얼로그 문장 그대로', [
    'สวัสดีครับ',
    'ผมชื่อมินโฮครับ',
    'ยินดีที่ได้รู้จักนะคะ',
    'ผัดไทยหนึ่งจานครับ',
    'ทั้งหมดเท่าไหร่ครับ',
    'ช่วยเปิดมิเตอร์ด้วยนะครับ',
  ]),
];

class _KeyboardPracticeScreenState extends State<KeyboardPracticeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  int _courseIdx = 0;
  int _targetIdx = 0;
  int _typedTotal = 0;
  int _errorTotal = 0;
  bool _hadErrorThisChar = false;

  // Thai char → (keyLabel, shift?)
  static final Map<String, (String, bool)> _reverse = () {
    final m = <String, (String, bool)>{};
    for (final row in _kedmanee) {
      for (final k in row) {
        m.putIfAbsent(k.normal, () => (k.label, false));
        m.putIfAbsent(k.shift, () => (k.label, true));
      }
    }
    return m;
  }();

  String get _target => _courses[_courseIdx].targets[_targetIdx];

  String? get _nextChar {
    final input = _controller.text;
    var i = 0;
    while (i < input.length &&
        i < _target.length &&
        input[i] == _target[i]) {
      i++;
    }
    return i < _target.length ? _target[i] : null;
  }

  int get _correctLen {
    final input = _controller.text;
    var i = 0;
    while (i < input.length &&
        i < _target.length &&
        input[i] == _target[i]) {
      i++;
    }
    return i;
  }

  bool get _hasError => _controller.text.length > _correctLen;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInput);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onInput() {
    if (_hasError && !_hadErrorThisChar) {
      _hadErrorThisChar = true;
      _errorTotal++;
    }
    if (!_hasError) _hadErrorThisChar = false;

    if (_controller.text == _target) {
      _typedTotal += _target.length;
      TtsService.instance.speak(_target);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _controller.clear();
          if (_targetIdx < _courses[_courseIdx].targets.length - 1) {
            _targetIdx++;
          } else {
            _showCourseDone();
            _targetIdx = 0;
          }
        });
      });
    }
    setState(() {});
  }

  void _showCourseDone() {
    final acc = _typedTotal + _errorTotal == 0
        ? 100
        : (_typedTotal * 100 / (_typedTotal + _errorTotal)).round();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '🎉 「${_courses[_courseIdx].name}」 코스 완료! 정확도 $acc%'),
        backgroundColor: AppColors.morakot,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('키보드연습',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('แป้นพิมพ์ เกษมณี',
                style: TextStyle(fontSize: 10, letterSpacing: 2)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _courseChips(),
          const SizedBox(height: 12),
          _targetCard(),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.khram,
              fontFamilyFallback: AppTheme.fontFallback,
            ),
            decoration: InputDecoration(
              hintText: '태국어 자판으로 입력하세요…',
              hintStyle: const TextStyle(
                  fontSize: 14, color: AppColors.khramLight),
              filled: true,
              fillColor: AppColors.creamDeep,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: _hasError
                        ? const Color(0xFFE53935)
                        : AppColors.thong),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _hasError
                      ? const Color(0xFFE53935)
                      : AppColors.kluayMai,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _statsRow(),
          const SizedBox(height: 12),
          const LaiThaiDivider(height: 10),
          const SizedBox(height: 8),
          _keyboard(),
          const SizedBox(height: 10),
          const Text(
            '💡 Windows: 한/영 전환처럼 Win+Space 로 태국어 자판을 추가·전환할 수 있어요.\n'
            '모바일: 키보드 설정에서 태국어(Kedmanee)를 추가하세요.',
            style: TextStyle(
                fontSize: 11, color: AppColors.khramLight, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _courseChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _courses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _courseIdx;
          return GestureDetector(
            onTap: () => setState(() {
              _courseIdx = i;
              _targetIdx = 0;
              _controller.clear();
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.kluayMai : AppColors.cream,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: selected
                      ? AppColors.kluayMaiDeep
                      : AppColors.thong.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                _courses[i].name,
                style: TextStyle(
                  color: selected ? AppColors.cream : AppColors.khram,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _targetCard() {
    final target = _target;
    final correct = _correctLen;
    final course = _courses[_courseIdx];
    return ThaiCard(
      title: '${course.name} · ${_targetIdx + 1}/${course.targets.length}',
      emblemText: 'พิมพ์',
      accent: AppColors.morakot,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.5,
                      fontFamilyFallback: AppTheme.fontFallback,
                    ),
                    children: [
                      TextSpan(
                        text: target.substring(0, correct),
                        style: const TextStyle(color: AppColors.morakot),
                      ),
                      TextSpan(
                        text: target.substring(correct),
                        style: TextStyle(
                          color: _hasError
                              ? const Color(0xFFE53935)
                              : AppColors.khram,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up,
                    color: AppColors.kluayMai),
                onPressed: () => TtsService.instance.speak(target),
              ),
            ],
          ),
          Text(
            course.desc,
            style: const TextStyle(
                fontSize: 11, color: AppColors.khramLight),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    final acc = _typedTotal + _errorTotal == 0
        ? 100
        : (_typedTotal * 100 / (_typedTotal + _errorTotal)).round();
    final next = _nextChar;
    final hint = next == null ? null : _reverse[next];
    return Row(
      children: [
        _chip('정확도 $acc%', AppColors.morakot),
        const SizedBox(width: 6),
        _chip('입력 $_typedTotal자', AppColors.thongDeep),
        const Spacer(),
        if (next != null)
          _chip(
            hint == null
                ? '다음: $next'
                : '다음: $next  (${hint.$2 ? 'Shift+' : ''}${hint.$1})',
            AppColors.kluayMai,
          ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800, color: color,
            fontFamilyFallback: AppTheme.fontFallback),
      ),
    );
  }

  Widget _keyboard() {
    final next = _nextChar;
    final hint = next == null ? null : _reverse[next];
    final needShift = hint?.$2 ?? false;

    return Column(
      children: [
        for (var r = 0; r < _kedmanee.length; r++)
          Padding(
            padding: EdgeInsets.only(bottom: 4, left: r * 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final k in _kedmanee[r])
                  _KeyCap(
                    keyDef: k,
                    showShift: needShift,
                    highlighted: hint != null && hint.$1 == k.label,
                  ),
              ],
            ),
          ),
        // Shift + Space 행
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 34,
              margin: const EdgeInsets.all(1.5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: needShift && next != null
                    ? AppColors.kluayMai
                    : AppColors.creamDeep,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: needShift && next != null
                      ? AppColors.kluayMaiDeep
                      : AppColors.thong.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'Shift',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: needShift && next != null
                      ? AppColors.cream
                      : AppColors.khramLight,
                ),
              ),
            ),
            Container(
              width: 170,
              height: 34,
              margin: const EdgeInsets.all(1.5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: next == ' '
                    ? AppColors.kluayMai
                    : AppColors.creamDeep,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: next == ' '
                        ? AppColors.kluayMaiDeep
                        : AppColors.thong.withValues(alpha: 0.5)),
              ),
              child: Text(
                'Space',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: next == ' '
                      ? AppColors.cream
                      : AppColors.khramLight,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  final _Key keyDef;
  final bool showShift; // shift 층 표시 여부
  final bool highlighted;
  const _KeyCap({
    required this.keyDef,
    required this.showShift,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final thai = showShift && highlighted ? keyDef.shift : keyDef.normal;
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.kluayMai : AppColors.cream,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: highlighted
                ? AppColors.kluayMaiDeep
                : AppColors.thong.withValues(alpha: 0.5),
            width: highlighted ? 1.5 : 0.8,
          ),
          boxShadow: highlighted
              ? [
                  BoxShadow(
                    color: AppColors.kluayMai.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                thai,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color:
                      highlighted ? AppColors.cream : AppColors.khram,
                  fontFamilyFallback: AppTheme.fontFallback,
                ),
              ),
            ),
            Positioned(
              top: 2,
              left: 3,
              child: Text(
                keyDef.label,
                style: TextStyle(
                  fontSize: 7,
                  color: highlighted
                      ? AppColors.cream.withValues(alpha: 0.8)
                      : AppColors.khramLight.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
