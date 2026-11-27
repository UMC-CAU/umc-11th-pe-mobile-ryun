import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:movielog/data/services/app_info_service.dart';
import 'package:movielog/view_models/about_view_model.dart';
import 'package:movielog/profile/about_screen.dart';
import 'package:movielog/theme/app_theme.dart';

class DelayedAppInfo extends AppInfoService {
  final response = Completer<String>();
  @override
  Future<String> getVersionLabel() => response.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'version comes from platform metadata rather than a screen constant',
    () async {
      PackageInfo.setMockInitialValues(
        appName: 'MovieLog',
        packageName: 'dev.umc.movielog',
        version: '2.3.4',
        buildNumber: '17',
        buildSignature: '',
      );
      expect(await AppInfoService().getVersionLabel(), '2.3.4 (17)');
    },
  );

  test('version failure leaves attribution available and dispose ignores completion', () async {
    final service = DelayedAppInfo();
    final model = AboutViewModel(service);
    var notifications = 0;
    model.addListener(() => notifications++);
    final pending = model.load();
    model.dispose();
    service.response.completeError(StateError('platform unavailable'));
    await pending;
    expect(notifications, 0);
    expect(model.versionLabel, '확인할 수 없음');
  });

  testWidgets('about remains scrollable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = DelayedAppInfo();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AboutViewModel(service)..load(),
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: const AboutScreen(),
        ),
      ),
    );
    service.response.complete('1.0.0 (1)');
    await tester.pumpAndSettle();
    expect(find.text('버전 1.0.0 (1)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AboutScreen.attribution),
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text(AboutScreen.attribution), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(AboutScreen.attribution).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
