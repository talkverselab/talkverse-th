/// 태국어 5성조 중 하나.
class ThaiTone {
  final String id; // 'mid' | 'low' | 'falling' | 'high' | 'rising'
  final String thai; // 태국어 이름 (예: สามัญ)
  final String roman; // 로마자 (예: saman)
  final String nameKo; // 한국어 이름 (예: 평성)
  final String sample; // 예시 음절 (예: คา)
  final String sampleKo; // 예시 한글 근사
  final String meaning; // 예시 단어 뜻
  final String desc; // 설명
  final String descShort; // 짧은 라벨
  final List<double> contour; // 성조 곡선 (0~1, 음높이) — 그래프용
  final String audio;

  const ThaiTone({
    required this.id,
    required this.thai,
    required this.roman,
    required this.nameKo,
    required this.sample,
    required this.sampleKo,
    required this.meaning,
    required this.desc,
    required this.descShort,
    required this.contour,
    this.audio = '',
  });

  factory ThaiTone.fromJson(Map<String, dynamic> j) => ThaiTone(
        id: j['id'] as String? ?? '',
        thai: j['thai'] as String? ?? '',
        roman: j['roman'] as String? ?? '',
        nameKo: j['nameKo'] as String? ?? '',
        sample: j['sample'] as String? ?? '',
        sampleKo: j['sampleKo'] as String? ?? '',
        meaning: j['meaning'] as String? ?? '',
        desc: j['desc'] as String? ?? '',
        descShort: j['descShort'] as String? ?? '',
        contour: (j['contour'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toDouble())
            .toList(growable: false),
        audio: j['audio'] as String? ?? '',
      );
}

/// 성조 부호 (4개).
class ToneMark {
  final String mark; // 결합 부호 (예: ่)
  final String display; // 표시용 (자음에 얹은 형태, 예: ก่)
  final String thai; // 태국어 이름 (예: ไม้เอก)
  final String roman; // 로마자
  final String ko; // 한국어 설명

  const ToneMark({
    required this.mark,
    required this.display,
    required this.thai,
    required this.roman,
    required this.ko,
  });

  factory ToneMark.fromJson(Map<String, dynamic> j) => ToneMark(
        mark: j['mark'] as String? ?? '',
        display: j['display'] as String? ?? '',
        thai: j['thai'] as String? ?? '',
        roman: j['roman'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
      );
}

/// 성조 규칙 한 행 (자음 분류 × 음절 종류 → 성조).
class ToneRule {
  final String cls; // 'mid' | 'high' | 'low'
  final String clsKo; // 중자음/고자음/저자음
  final String live; // 평음절(생음절) 무표시 성조
  final String deadShort; // 사음절(단모음) 성조
  final String deadLong; // 사음절(장모음) 성조
  final String mai1; // 1성부호(ไม้เอก) 성조
  final String mai2; // 2성부호(ไม้โท) 성조

  const ToneRule({
    required this.cls,
    required this.clsKo,
    required this.live,
    required this.deadShort,
    required this.deadLong,
    required this.mai1,
    required this.mai2,
  });

  factory ToneRule.fromJson(Map<String, dynamic> j) => ToneRule(
        cls: j['cls'] as String? ?? '',
        clsKo: j['clsKo'] as String? ?? '',
        live: j['live'] as String? ?? '',
        deadShort: j['deadShort'] as String? ?? '',
        deadLong: j['deadLong'] as String? ?? '',
        mai1: j['mai1'] as String? ?? '',
        mai2: j['mai2'] as String? ?? '',
      );
}

/// 성조 데이터 묶음.
class ToneData {
  final List<ThaiTone> tones;
  final List<ToneMark> marks;
  final List<ToneRule> rules;

  const ToneData({
    required this.tones,
    required this.marks,
    required this.rules,
  });
}
