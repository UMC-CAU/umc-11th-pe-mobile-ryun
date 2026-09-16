import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hello MovieLog! 텍스트를 표시한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Hello MovieLog!'))),
      ),
    );

    expect(find.text('Hello MovieLog!'), findsOneWidget);
  });
}
