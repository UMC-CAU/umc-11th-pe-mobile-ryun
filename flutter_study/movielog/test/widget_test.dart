import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/auth/sign_up_screen.dart';
import 'package:movielog/common/movie_log_text_form_field.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(home: SignUpScreen());
  }

  testWidgets('회원가입 화면의 필수 입력 요소를 표시한다', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byKey(const Key('nicknameField')), findsOneWidget);
    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('termsCheckbox')), findsOneWidget);
    expect(find.byKey(const Key('signUpButton')), findsOneWidget);
    expect(find.byType(MovieLogTextFormField), findsNWidgets(3));
  });

  testWidgets('비밀번호 표시 버튼으로 입력값을 표시하고 다시 숨긴다', (tester) async {
    await tester.pumpWidget(buildSubject());

    final passwordField = find.byKey(const Key('passwordField'));
    final visibilityButton = find.byKey(const Key('passwordVisibilityButton'));

    EditableText passwordInput = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(passwordInput.obscureText, isTrue);

    await tester.tap(visibilityButton);
    await tester.pump();

    passwordInput = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(passwordInput.obscureText, isFalse);

    await tester.tap(visibilityButton);
    await tester.pump();

    passwordInput = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(EditableText)),
    );
    expect(passwordInput.obscureText, isTrue);
  });

  testWidgets('너비 700 이상에서는 Form 최대 너비를 560으로 제한한다', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());

    expect(tester.getSize(find.byType(Form)).width, 560);
    expect(tester.getCenter(find.byType(Form)).dx, 600);
  });

  testWidgets('잘못된 입력에 한국어 오류 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.enterText(find.byKey(const Key('nicknameField')), 'a');
    await tester.enterText(find.byKey(const Key('emailField')), 'test@');
    await tester.enterText(find.byKey(const Key('passwordField')), '123');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식이 아닙니다.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('모든 조건이 유효할 때 가입 버튼을 활성화한다', (tester) async {
    await tester.pumpWidget(buildSubject());

    ElevatedButton button = tester.widget(
      find.byKey(const Key('signUpButton')),
    );
    expect(button.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('nicknameField')), '무비러버');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'movie@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password1234',
    );
    await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pump();

    button = tester.widget(find.byKey(const Key('signUpButton')));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('작은 화면에서도 스크롤해 가입 버튼에 접근할 수 있다', (tester) async {
    tester.view.physicalSize = const Size(390, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSubject());
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('signUpButton')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('스크롤은 Focus를 유지하고 바깥 탭은 Focus를 해제한다', (tester) async {
    await tester.pumpWidget(buildSubject());

    final nicknameField = find.byKey(const Key('nicknameField'));
    await tester.tap(nicknameField);
    await tester.pump();

    EditableText editableText = tester.widget(
      find.descendant(of: nicknameField, matching: find.byType(EditableText)),
    );
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pump();

    editableText = tester.widget(
      find.descendant(of: nicknameField, matching: find.byType(EditableText)),
    );
    expect(editableText.focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(20, 200));
    await tester.pump();

    expect(editableText.focusNode.hasFocus, isFalse);
  });

  testWidgets('Form 제출 시 전체 입력값을 다시 검증한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    await tester.enterText(find.byKey(const Key('nicknameField')), '무비러버');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'movie@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password1234',
    );
    await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('signUpButton')));
    await tester.tap(find.byKey(const Key('signUpButton')));
    await tester.pump();

    expect(find.text('가입 정보가 확인되었습니다.'), findsOneWidget);
  });
}
