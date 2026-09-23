import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/dev_notes.dart';

/// 앱 전체를 감싸는 층 — 캡처용 RepaintBoundary + (개발자 메모가 켜져 있으면) 떠 있는 메모 버튼.
class DevNoteOverlay extends StatefulWidget {
  final Widget child;
  const DevNoteOverlay({super.key, required this.child});

  @override
  State<DevNoteOverlay> createState() => _DevNoteOverlayState();
}

class _DevNoteOverlayState extends State<DevNoteOverlay> {
  final _dn = DevNotes.instance;
  Offset? _pos;
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    _busy = true;
    final shot = await _dn.capture(); // 시트를 띄우기 전 화면
    final screen = _dn.currentScreen;
    final ctx = _dn.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      _busy = false;
      return;
    }
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      builder: (_) => _NoteSheet(shot: shot, screen: screen),
    );
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          RepaintBoundary(key: _dn.boundaryKey, child: widget.child),
          ValueListenableBuilder<bool>(
            valueListenable: _dn.enabled,
            builder: (context, on, _) {
              if (!on) return const SizedBox.shrink();
              final size = MediaQuery.of(context).size;
              final pos = _pos ?? Offset(size.width - 62, size.height - 170);
              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: GestureDetector(
                  onPanUpdate: (d) => setState(() => _pos = Offset(
                        (pos.dx + d.delta.dx).clamp(0, size.width - 50),
                        (pos.dy + d.delta.dy).clamp(40, size.height - 60),
                      )),
                  onTap: _open,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD84315).withValues(alpha: 0.88),
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.edit_note, color: Colors.white, size: 26),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NoteSheet extends StatefulWidget {
  final Uint8List? shot;
  final String screen;
  const _NoteSheet({required this.shot, required this.screen});

  @override
  State<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<_NoteSheet> {
  final _ctl = TextEditingController();
  bool _withShot = true;
  bool _sending = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await DevNotes.instance.submit(text, _withShot ? widget.shot : null);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.pop(context);
    messenger?.showSnackBar(SnackBar(
      content: Text(ok ? tr('메모를 보냈어요') : tr('폰에 저장했어요 — 로그인·연결되면 보내요')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFFD84315)),
              const SizedBox(width: 6),
              Text(tr('개발자 메모'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              Flexible(
                child: Text(widget.screen,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (widget.shot != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(widget.shot!, height: 120, fit: BoxFit.contain),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _withShot,
                    onChanged: (v) => setState(() => _withShot = v ?? true),
                    title: Text(tr('화면 캡처 같이 보내기'), style: const TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctl,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            maxLength: 4000,
            decoration: InputDecoration(
              hintText: tr('무엇을 어떻게 고칠까요? (예: 3번째 줄 뜻이 어색함 → …)'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send, size: 18),
            label: Text(tr('보내기')),
          ),
        ],
      ),
    );
  }
}
