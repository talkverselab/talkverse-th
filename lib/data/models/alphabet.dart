/// 태국어 자음 한 글자.
///
/// 태국어 자음은 고(สูง)/중(กลาง)/저(ต่ำ) 3분류로 나뉘며, 이 분류가
/// 음절의 성조를 결정하는 핵심 요소다. (성조 화면에서 함께 다룬다.)
class ThaiConsonant {
  final String char; // 글자 (예: ก)
  final String acrophonic; // 두문자 이름 (예: ก ไก่)
  final String roman; // 로마자 이름 (예: ko kai)
  final String meaning; // 두문자 단어 뜻 (예: 닭)
  final String initial; // 초성 음가 (예: ㄲ k)
  final String finalSound; // 종성 음가 (예: ㄱ k), 없으면 '-'
  final String cls; // 'mid' | 'high' | 'low'
  final String ko; // 한국어 근사음
  final String audio;

  const ThaiConsonant({
    required this.char,
    required this.acrophonic,
    required this.roman,
    required this.meaning,
    required this.initial,
    required this.finalSound,
    required this.cls,
    required this.ko,
    this.audio = '',
  });

  bool get isMid => cls == 'mid';
  bool get isHigh => cls == 'high';
  bool get isLow => cls == 'low';

  factory ThaiConsonant.fromJson(Map<String, dynamic> j) => ThaiConsonant(
        char: j['char'] as String? ?? '',
        acrophonic: j['acrophonic'] as String? ?? '',
        roman: j['roman'] as String? ?? '',
        meaning: j['meaning'] as String? ?? '',
        initial: j['initial'] as String? ?? '',
        finalSound: j['final'] as String? ?? '-',
        cls: j['cls'] as String? ?? 'low',
        ko: j['ko'] as String? ?? '',
        audio: j['audio'] as String? ?? '',
      );
}

/// 태국어 모음 한 글자.
class ThaiVowel {
  final String form; // 표기형 (– 는 자음 자리). 예: –ะ
  final String roman; // 로마자 (예: a)
  final String ko; // 한국어 근사음
  final String length; // 'short' | 'long'
  final String example; // 예시 단어 (태국어)
  final String exampleKo; // 예시 뜻
  final String audio;

  const ThaiVowel({
    required this.form,
    required this.roman,
    required this.ko,
    required this.length,
    required this.example,
    required this.exampleKo,
    this.audio = '',
  });

  bool get isLong => length == 'long';

  factory ThaiVowel.fromJson(Map<String, dynamic> j) => ThaiVowel(
        form: j['form'] as String? ?? '',
        roman: j['roman'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        length: j['length'] as String? ?? 'short',
        example: j['example'] as String? ?? '',
        exampleKo: j['exampleKo'] as String? ?? '',
        audio: j['audio'] as String? ?? '',
      );
}

/// 알파벳 데이터 묶음 (자음 + 모음).
class AlphabetData {
  final List<ThaiConsonant> consonants;
  final List<ThaiVowel> vowels;

  const AlphabetData({required this.consonants, required this.vowels});

  List<ThaiConsonant> get mid =>
      consonants.where((c) => c.isMid).toList(growable: false);
  List<ThaiConsonant> get high =>
      consonants.where((c) => c.isHigh).toList(growable: false);
  List<ThaiConsonant> get low =>
      consonants.where((c) => c.isLow).toList(growable: false);
}
