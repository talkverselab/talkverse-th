import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/art_service.dart';
import '../services/content_sync.dart';

/// 단어 목록·타일용 uk 단어 그림(점토 톤, 512 webp) 썸네일 — 일본어앱 word_art_thumb.dart 이식(2026-11-02).
/// 그림 DB 에 있으면 둥근 그림, 없으면 [fallback](이모지 등)이나 빈 자리. 실패해도 화면은 멀쩡해야 한다.
class WordArtThumb extends StatelessWidget {
  final String word;
  final int? rank;
  final double size;
  final Widget? fallback;
  final BoxFit fit;
  const WordArtThumb({super.key, required this.word, this.rank, this.size = 44, this.fallback, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ArtService.instance.urlFor(word, rank: rank),
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) return fallback ?? SizedBox(width: size, height: size);
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Container(
            width: size,
            height: size,
            color: AppColors.creamDeep,
            child: Image(image: artProvider(url), fit: fit, errorBuilder: (_, _, _) => fallback ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
