import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['WEEK7_CAPTURE_DIR'] ?? 'docs/week7/screenshots',
  );
  await output.create(recursive: true);
  await integrationDriver(
    responseDataCallback: (data) async {
      final report = Map<String, dynamic>.from(data ?? {});
      final screens = report.remove('renderedScreens') as Map? ?? {};
      for (final entry in screens.entries) {
        final name = entry.key as String;
        if (!RegExp(r'^[a-z0-9-]+$').hasMatch(name)) {
          throw StateError('Invalid capture name');
        }
        await File('${output.path}/$name.png')
            .writeAsBytes(base64Decode(entry.value as String));
        stdout.writeln('Saved Android app capture: $name');
      }
      await File('${output.path}/capture-result.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    },
    writeResponseOnFailure: true,
  );
}
