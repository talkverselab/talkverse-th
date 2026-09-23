import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/content_store.dart';
import '../services/dev_notes.dart';

/// 개발자 메모 설정 + 내가 보낸 메모와 처리 결과.
class DevNotesScreen extends StatefulWidget {
  const DevNotesScreen({super.key});

  @override
  State<DevNotesScreen> createState() => _DevNotesScreenState();
}

class _DevNotesScreenState extends State<DevNotesScreen> {
  final _dn = DevNotes.instance;
  List<Map<String, dynamic>>? _rows;
  String? _error;
  int _queued = 0;
  String _content = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _dn.flushQueue();
    _queued = await _dn.queued();
    try {
      _rows = await _dn.mine();
      _error = null;
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() {});
  }

  Future<void> _checkContent() async {
    setState(() => _content = tr('확인 중'));
    await ContentStore.instance.refresh();
    if (mounted) setState(() => _content = ContentStore.instance.lastResult);
  }

  static const _status = {'open': '📥 접수', 'doing': '🔧 작업 중', 'done': '✅ 반영', 'wontfix': '↩️ 보류'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(tr('개발자 메모'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 24 + bottomInset(context)),
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _dn.enabled,
              builder: (_, on, _) => SwitchListTile(
                value: on,
                onChanged: _dn.setEnabled,
                title: Text(tr('모든 화면에 메모 버튼 띄우기')),
                subtitle: Text(tr('버튼을 누르면 지금 화면을 캡처해 메모와 같이 보내요. 끌어서 옮길 수 있어요.')),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(tr('콘텐츠 업데이트 확인')),
              subtitle: Text(_content.isEmpty
                  ? trf('스크립트·문법 문장은 APK 없이 받아요 · 지금 판 {0}', [ContentStore.instance.activeVersion])
                  : _content),
              onTap: _checkContent,
            ),
            if (_queued > 0)
              ListTile(
                leading: const Icon(Icons.schedule_send),
                title: Text(trf('못 보낸 메모 {0}개', [_queued])),
                subtitle: Text(tr('로그인하고 당겨서 새로고침하면 보내요')),
              ),
            const Divider(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(trf('불러오지 못했어요 (로그인 필요)\n{0}', [_error]),
                    style: const TextStyle(fontSize: 12, color: AppColors.khramLight)),
              )
            else if (_rows == null)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_rows!.isEmpty)
              Padding(padding: const EdgeInsets.all(16), child: Text(tr('아직 보낸 메모가 없어요')))
            else
              for (final r in _rows!)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.thong, width: 0.6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_status[r['status']] ?? '${r['status']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Text('#${r['id']} · ${(r['created_at'] as String).substring(5, 16).replaceFirst('T', ' ')}',
                              style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${r['screen'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.khramLight)),
                      const SizedBox(height: 4),
                      Text('${r['note']}', style: const TextStyle(fontSize: 13.5, height: 1.4)),
                      if ((r['resolution'] as String?)?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: AppColors.creamDeep,
                          child: Text('→ ${r['resolution']}',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.morakot, height: 1.4)),
                        ),
                      ],
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
