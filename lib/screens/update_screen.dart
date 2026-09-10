import 'dart:io';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/update_service.dart';
import '../widgets/thai_decor.dart';

/// 앱 업데이트 — GitHub 릴리스(master 푸시마다 갱신)에서 최신 빌드를 받아 설치.
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

enum _Stage { idle, checking, upToDate, available, downloading, ready }

class _UpdateScreenState extends State<UpdateScreen> {
  final _svc = UpdateService.instance;
  _Stage _stage = _Stage.idle;
  UpdateInfo? _latest;
  String? _error;
  String? _apkPath;
  int _received = 0;
  int _total = -1;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _svc.loadCurrent();
    if (!mounted) return;
    setState(() {});
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _stage = _Stage.checking;
      _error = null;
    });
    try {
      final info = await _svc.fetchLatest();
      if (!mounted) return;
      setState(() {
        _latest = info;
        _stage =
            UpdateService.isNewer(
              current: _svc.currentBuild,
              latest: info.build,
            )
            ? _Stage.available
            : _Stage.upToDate;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = _message(e);
      });
    }
  }

  Future<void> _download() async {
    setState(() {
      _stage = _Stage.downloading;
      _error = null;
      _received = 0;
      _total = _latest?.size ?? -1;
    });
    try {
      final file = await _svc.download(
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            if (total > 0) _total = total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _apkPath = file.path;
        _stage = _Stage.ready;
      });
      _install();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.available;
        _error = _message(e);
      });
    }
  }

  Future<void> _install() async {
    final path = _apkPath;
    if (path == null) return;
    try {
      final r = await _svc.install(path);
      if (!mounted) return;
      if (r == InstallResult.needPermission) {
        setState(
          () => _error =
              '「출처를 알 수 없는 앱 설치」를 허용해 주세요. 방금 연 설정에서 태국어유니버스를 켠 뒤 아래 「설치」를 다시 누르면 됩니다.',
        );
      } else if (r == InstallResult.missing) {
        setState(() {
          _stage = _Stage.available;
          _error = '내려받은 파일을 찾지 못했습니다. 다시 받아 주세요.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _message(e));
    }
  }

  String _message(Object e) {
    if (e is SocketException) {
      return '네트워크에 연결하지 못했습니다. 와이파이·데이터를 확인해 주세요.';
    }
    if (e is HttpException) return '릴리스를 읽지 못했습니다 — ${e.message}';
    return '$e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          '앱 업데이트',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const LaiThaiDivider(height: 8),
          const SizedBox(height: 10),
          _Panel(
            title: '지금 이 앱',
            color: AppColors.khram,
            lines: ['버전 ${_svc.currentText}'],
          ),
          const SizedBox(height: 12),
          _latestPanel(),
          const SizedBox(height: 14),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.creamDeep,
                border: Border.all(color: AppColors.kluayMai, width: 1.2),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.kluayMaiDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _actions(),
          const SizedBox(height: 20),
          const Text(
            '업데이트는 master에 푸시할 때마다 GitHub Actions가 서명해 올린 APK입니다.\n'
            '처음 설치할 때 한 번 「출처를 알 수 없는 앱 설치」 허용이 필요합니다.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: AppColors.khramLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _latestPanel() {
    final l = _latest;
    if (_stage == _Stage.checking) {
      return const _Panel(
        title: '최신 빌드',
        color: AppColors.thongDeep,
        lines: ['확인하는 중…'],
      );
    }
    if (l == null) {
      return const _Panel(
        title: '최신 빌드',
        color: AppColors.thongDeep,
        lines: ['아직 확인하지 않았습니다.'],
      );
    }
    final when = l.builtAt;
    return _Panel(
      title: _stage == _Stage.upToDate ? '최신 상태입니다' : '새 빌드가 있습니다',
      color: _stage == _Stage.upToDate ? AppColors.morakot : AppColors.kluayMai,
      lines: [
        '버전 ${l.version} · 빌드 ${l.build}'
            '${l.sha.isEmpty ? '' : ' · ${l.sha}'}',
        if (when != null)
          '${when.year}-${_two(when.month)}-${_two(when.day)} '
              '${_two(when.hour)}:${_two(when.minute)}'
              '${l.sizeText.isEmpty ? '' : ' · ${l.sizeText}'}',
        if (l.notes.isNotEmpty) l.notes,
      ],
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  Widget _actions() {
    switch (_stage) {
      case _Stage.downloading:
        final ratio = _total > 0 ? _received / _total : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppColors.creamDeep,
              color: AppColors.kluayMai,
            ),
            const SizedBox(height: 8),
            Text(
              ratio == null
                  ? '${(_received / 1024 / 1024).toStringAsFixed(1)} MB 받는 중…'
                  : '${(ratio * 100).toStringAsFixed(0)}% · '
                        '${(_received / 1024 / 1024).toStringAsFixed(1)} / '
                        '${(_total / 1024 / 1024).toStringAsFixed(1)} MB',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.khram,
              ),
            ),
          ],
        );
      case _Stage.ready:
        return _Button(label: '설치', color: AppColors.kluayMai, onTap: _install);
      case _Stage.available:
        return _Button(
          label: '내려받아 설치',
          color: AppColors.kluayMai,
          onTap: _download,
        );
      case _Stage.checking:
        return const SizedBox(
          height: 46,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.kluayMai),
          ),
        );
      case _Stage.idle:
      case _Stage.upToDate:
        return _Button(label: '다시 확인', color: AppColors.khram, onTap: _check);
    }
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> lines;
  const _Panel({required this.title, required this.color, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          for (final t in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                t,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: AppColors.khram,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Button({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppColors.thong, width: 1.2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.cream,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
