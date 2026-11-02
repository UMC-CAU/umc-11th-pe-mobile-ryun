import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['MISSION_CAPTURE_DIR'] ??
        r'C:\umc-11th\flutter_study\movielog\docs\week6\figma-screenshots',
  );
  await output.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(name) || bytes.length < 1000) {
        return false;
      }
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      stdout.writeln(
        'Saved emulator screenshot: $name (${bytes.length} bytes)',
      );
      return true;
    },
    responseDataCallback: (data) async {
      final summary = Map<String, dynamic>.from(data ?? {});
      summary.remove('screenshots');
      final renderedScreens = summary.remove('renderedScreens') as Map?;
      for (final entry in renderedScreens?.entries ?? const <MapEntry>[]) {
        final name = entry.key as String;
        if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(name)) {
          throw StateError('Invalid capture name');
        }
        await File('${output.path}/$name.png')
            .writeAsBytes(base64Decode(entry.value as String));
        stdout.writeln('Saved full Flutter render: $name');
      }
      summary['captureMethod'] =
          'Android app full Flutter RepaintBoundary render';
      await File('${output.path}/capture-result.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
      // Also preserve the original Android display, including system bars.
      final result = await Process.run(
        r'C:\Users\cksgu\AppData\Local\Android\sdk\platform-tools\adb.exe',
        ['-s', 'emulator-5554', 'exec-out', 'screencap', '-p'],
        stdoutEncoding: null,
      );
      if (result.exitCode == 0) {
        await File('${output.path}/10-android-full-display.png')
            .writeAsBytes(result.stdout as List<int>);
      }
    },
    writeResponseOnFailure: true,
  );
}
