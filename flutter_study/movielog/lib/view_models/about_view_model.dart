import 'package:flutter/foundation.dart';

import '../data/services/app_info_service.dart';

class AboutViewModel extends ChangeNotifier {
  AboutViewModel(this._service);

  final AppInfoService _service;
  String versionLabel = '확인 중...';
  bool _disposed = false;

  Future<void> load() async {
    try {
      versionLabel = await _service.getVersionLabel();
    } on Object {
      versionLabel = '확인할 수 없음';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
