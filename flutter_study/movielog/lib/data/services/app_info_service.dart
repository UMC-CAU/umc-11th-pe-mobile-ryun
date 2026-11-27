import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  Future<String> getVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }
}
