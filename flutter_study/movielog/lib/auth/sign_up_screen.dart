import 'package:flutter/material.dart';

import '../common/common_app_bar.dart';
import '../common/movie_log_text_form_field.dart';
import '../theme/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;
  bool _nicknameTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _submitted = false;

  bool get _canSubmit =>
      _nicknameError(_nicknameController.text) == null &&
      _emailError(_emailController.text) == null &&
      _passwordError(_passwordController.text) == null &&
      _agreedToTerms;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = true);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_agreedToTerms) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('가입 정보가 확인되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth >= 700;
              final horizontalPadding = isWideScreen ? 48.0 : 16.0;
              final verticalPadding = isWideScreen ? 64.0 : 24.0;
              final minimumContentHeight =
                  constraints.maxHeight - (verticalPadding * 2);

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  horizontalPadding,
                  isWideScreen ? verticalPadding : 32,
                ),
                child: Align(
                  alignment: isWideScreen
                      ? Alignment.topCenter
                      : Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 560 : constraints.maxWidth,
                      minHeight: minimumContentHeight > 0
                          ? minimumContentHeight
                          : 0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: isWideScreen
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SignUpHeader(),
                              const SizedBox(height: 48),
                              SignUpFields(
                                nicknameController: _nicknameController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                emailFocusNode: _emailFocusNode,
                                passwordFocusNode: _passwordFocusNode,
                                nicknameError: _nicknameError,
                                emailError: _emailError,
                                passwordError: _passwordError,
                                nicknameShowsValidation:
                                    _nicknameTouched || _submitted,
                                emailShowsValidation:
                                    _emailTouched || _submitted,
                                passwordShowsValidation:
                                    _passwordTouched || _submitted,
                                onNicknameChanged: (_) {
                                  setState(() => _nicknameTouched = true);
                                },
                                onEmailChanged: (_) {
                                  setState(() => _emailTouched = true);
                                },
                                onPasswordChanged: (_) {
                                  setState(() => _passwordTouched = true);
                                },
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 72),
                            child: TermsAndSubmitSection(
                              agreedToTerms: _agreedToTerms,
                              canSubmit: _canSubmit,
                              onAgreementChanged: (value) {
                                setState(() => _agreedToTerms = value);
                              },
                              onSubmit: _submit,
                              onLogin: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('로그인 화면은 다음 단계에서 연결합니다.'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '환영합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.bodyText,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.bodyText,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class SignUpFields extends StatelessWidget {
  const SignUpFields({
    super.key,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.nicknameError,
    required this.emailError,
    required this.passwordError,
    required this.nicknameShowsValidation,
    required this.emailShowsValidation,
    required this.passwordShowsValidation,
    required this.onNicknameChanged,
    required this.onEmailChanged,
    required this.onPasswordChanged,
  });

  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final String? Function(String?) nicknameError;
  final String? Function(String?) emailError;
  final String? Function(String?) passwordError;
  final bool nicknameShowsValidation;
  final bool emailShowsValidation;
  final bool passwordShowsValidation;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MovieLogTextFormField(
          fieldKey: const Key('nicknameField'),
          label: '닉네임',
          hintText: '닉네임을 입력해주세요',
          controller: nicknameController,
          textInputAction: TextInputAction.next,
          validator: nicknameError,
          showValidation: nicknameShowsValidation,
          onChanged: onNicknameChanged,
          onSubmitted: (_) => emailFocusNode.requestFocus(),
        ),
        const SizedBox(height: 20),
        MovieLogTextFormField(
          fieldKey: const Key('emailField'),
          label: '이메일',
          hintText: '이메일 주소를 입력해주세요',
          controller: emailController,
          focusNode: emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: emailError,
          showValidation: emailShowsValidation,
          onChanged: onEmailChanged,
          onSubmitted: (_) => passwordFocusNode.requestFocus(),
        ),
        const SizedBox(height: 20),
        MovieLogTextFormField(
          fieldKey: const Key('passwordField'),
          label: '비밀번호',
          hintText: '비밀번호를 입력해주세요',
          controller: passwordController,
          focusNode: passwordFocusNode,
          isPassword: true,
          textInputAction: TextInputAction.done,
          validator: passwordError,
          showValidation: passwordShowsValidation,
          onChanged: onPasswordChanged,
          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ],
    );
  }
}

class TermsAndSubmitSection extends StatelessWidget {
  const TermsAndSubmitSection({
    super.key,
    required this.agreedToTerms,
    required this.canSubmit,
    required this.onAgreementChanged,
    required this.onSubmit,
    required this.onLogin,
  });

  final bool agreedToTerms;
  final bool canSubmit;
  final ValueChanged<bool> onAgreementChanged;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          key: const Key('termsRow'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => onAgreementChanged(!agreedToTerms),
          child: Row(
            children: [
              Checkbox(
                key: const Key('termsCheckbox'),
                value: agreedToTerms,
                onChanged: (value) => onAgreementChanged(value ?? false),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  '필수 약관에 동의합니다',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            key: const Key('signUpButton'),
            onPressed: canSubmit ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFFD0C4E0),
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '가입하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Flexible(
              child: Text(
                '이미 계정이 있나요?',
                style: TextStyle(color: AppColors.bodyText, fontSize: 14),
              ),
            ),
            TextButton(
              onPressed: onLogin,
              child: const Text(
                '로그인',
                style: TextStyle(
                  color: AppColors.violet,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String? _nicknameError(String? value) {
  final nickname = value?.trim() ?? '';
  if (nickname.isEmpty) return '닉네임을 입력해주세요.';
  if (nickname.length < 2) return '닉네임은 2자 이상이어야 합니다.';
  return null;
}

String? _emailError(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return '이메일을 입력해주세요.';

  final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!emailPattern.hasMatch(email)) return '올바른 이메일 형식이 아닙니다.';
  return null;
}

String? _passwordError(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return '비밀번호를 입력해주세요.';
  if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
  return null;
}
