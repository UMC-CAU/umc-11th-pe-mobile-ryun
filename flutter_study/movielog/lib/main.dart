import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'data/mock_movies.dart';
import 'movielog_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  LicenseRegistry.addLicense(() async* {
    for (final asset in {
      'Manrope': 'assets/licenses/Manrope-OFL.txt',
      'Material Symbols': 'assets/licenses/Material-Symbols-Apache-2.0.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks([
        asset.key,
      ], await rootBundle.loadString(asset.value));
    }
  });

  for (final movie in movies) {
    debugPrint(movie.title);
  }

  final nickname = safeNickname(null);
  debugPrint('안녕하세요, $nickname님!');

  runApp(const MovieLogApp());
}

String safeNickname(String? nickname) => nickname ?? '륜';
