import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'widgets/week6_app_bar.dart';
import 'theme/week6_style.dart';
import 'common/movie_log_text_form_field.dart';

import 'core/network/movie_log_client.dart';
import 'data/services/sign_up_service.dart';
import 'data/models/create_member_request.dart';
import 'view_models/learning_member_session.dart';
import 'view_models/sign_up_view_model.dart';
import 'widgets/movielog_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.memberService});
  final MemberAvailabilityService? memberService;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
  late final _ownedClient = widget.memberService == null
      ? createMovieLogClient()
      : null;
  late final SignUpViewModel _viewModel = SignUpViewModel(
    widget.memberService ?? SignUpService(_ownedClient!),
  );
  bool get _nicknameChecking =>
      _viewModel.nicknameCheckStatus == CheckStatus.checking;
  bool get _emailChecking =>
      _viewModel.emailCheckStatus == CheckStatus.checking;
  bool? _available(CheckStatus status) => switch (status) {
    CheckStatus.available => true,
    CheckStatus.duplicated => false,
    _ => null,
  };
  bool? get _nicknameAvailable => _available(_viewModel.nicknameCheckStatus);
  bool? get _emailAvailable => _available(_viewModel.emailCheckStatus);
  String? get _nicknameMessage => _nicknameAvailable == true
      ? '사용 가능한 닉네임입니다.'
      : _viewModel.nicknameErrorText;
  String? get _emailMessage =>
      _emailAvailable == true ? '사용 가능한 이메일입니다.' : _viewModel.emailErrorText;

  void _dismissSubmitError() {
    if (_viewModel.snackbarMessage != null) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
    }
  }

  Future<void> _checkAvailability(bool isNickname) async {
    final value = (isNickname ? _nicknameController : _emailController).text;
    setState(() {
      if (isNickname) {
        _nicknameTouched = true;
      } else {
        _emailTouched = true;
      }
    });
    if ((isNickname ? _nicknameError(value) : _emailError(value)) != null) {
      return;
    }
    if (isNickname) {
      await _viewModel.checkNickname(value);
    } else {
      await _viewModel.checkEmail(value);
    }
  }

  bool get _canSubmit =>
      _nicknameError(_nicknameController.text) == null &&
      _emailError(_emailController.text) == null &&
      _passwordError(_passwordController.text) == null &&
      _viewModel.passwordErrorText == null &&
      _agreedToTerms &&
      _viewModel.canSubmit &&
      !_nicknameChecking &&
      !_emailChecking;

  @override
  void dispose() {
    _viewModel.dispose();
    _ownedClient?.close(force: true);
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_canSubmit) return;

    FocusScope.of(context).unfocus();
    await _viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        password: _passwordController.text,
        nickname: _nicknameController.text,
      ),
    );
    if (!mounted) return;
    if (_viewModel.submitStatus == SubmitStatus.success &&
        _viewModel.createdMemberId != null) {
      context.read<LearningMemberSession>().setMemberId(
        _viewModel.createdMemberId!,
      );
      _passwordController.clear();
      context.go('/movies');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입을 완료했습니다. 영화에 평점을 남겨보세요.')),
      );
    } else if (_viewModel.snackbarMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_viewModel.snackbarMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: _viewModel,
    child: Consumer<SignUpViewModel>(
      builder: (context, viewModel, child) => _buildScreen(context),
    ),
  );

  Widget _buildScreen(BuildContext context) {
    return PopScope(
      canPop: !_viewModel.isSubmitting,
      child: Scaffold(
        backgroundColor: Week6Style.background,
        appBar: Week6AppBar(
          title: '회원가입',
          onBack: () {
            if (_viewModel.isSubmitting) return;
            context.canPop() ? context.pop() : context.go('/start');
          },
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 700;
                final horizontalPadding = isWideScreen ? 48.0 : 18.0;
                final verticalPadding = isWideScreen ? 64.0 : 45.0;
                final minimumContentHeight =
                    constraints.maxHeight - verticalPadding - 40;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    40,
                  ),
                  child: Align(
                    alignment: isWideScreen
                        ? Alignment.topCenter
                        : Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWideScreen ? 560 : constraints.maxWidth,
                        minHeight: minimumContentHeight > 585
                            ? minimumContentHeight
                            : 585,
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
                                const RegisterHeader(),
                                const SizedBox(height: 30),
                                AbsorbPointer(
                                  absorbing: _viewModel.isSubmitting,
                                  child: RegisterFields(
                                    nicknameController: _nicknameController,
                                    emailController: _emailController,
                                    passwordController: _passwordController,
                                    emailFocusNode: _emailFocusNode,
                                    passwordFocusNode: _passwordFocusNode,
                                    nicknameError: _nicknameError,
                                    emailError: _emailError,
                                    passwordError: _passwordError,
                                    passwordErrorText:
                                        _viewModel.passwordErrorText,
                                    nicknameShowsValidation:
                                        _nicknameTouched || _submitted,
                                    emailShowsValidation:
                                        _emailTouched || _submitted,
                                    passwordShowsValidation:
                                        _passwordTouched || _submitted,
                                    onCheckNickname: _viewModel.canCheckNickname
                                        ? () => _checkAvailability(true)
                                        : null,
                                    onCheckEmail: _viewModel.canCheckEmail
                                        ? () => _checkAvailability(false)
                                        : null,
                                    nicknameChecking: _nicknameChecking,
                                    emailChecking: _emailChecking,
                                    nicknameMessage: _nicknameMessage,
                                    emailMessage: _emailMessage,
                                    nicknameAvailable: _nicknameAvailable,
                                    emailAvailable: _emailAvailable,
                                    onNicknameChanged: (value) {
                                      _dismissSubmitError();
                                      setState(() {
                                        _nicknameTouched = true;
                                        _viewModel.onNicknameChanged(value);
                                      });
                                    },
                                    onEmailChanged: (value) {
                                      _dismissSubmitError();
                                      setState(() {
                                        _emailTouched = true;
                                        _viewModel.onEmailChanged(value);
                                      });
                                    },
                                    onPasswordChanged: (_) {
                                      _dismissSubmitError();
                                      setState(() => _passwordTouched = true);
                                      _viewModel.onPasswordChanged();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 72),
                              child: TermsAndSubmitSection(
                                agreedToTerms: _agreedToTerms,
                                canSubmit: _canSubmit,
                                isLoading: _viewModel.isSubmitting,
                                onAgreementChanged: (value) {
                                  if (_viewModel.isSubmitting) return;
                                  setState(() => _agreedToTerms = value);
                                },
                                onSubmit: _submit,
                                onLogin: () {
                                  if (!_viewModel.isSubmitting) {
                                    context.go('/home');
                                  }
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
      ),
    );
  }
}

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          '환영합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            color: Week6Style.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 22 / 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '간단한 정보만 입력하고 시작해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Manrope',
            color: Week6Style.ink,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 19 / 14,
          ),
        ),
      ],
    );
  }
}

class RegisterFields extends StatelessWidget {
  const RegisterFields({
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
    this.onCheckNickname,
    this.onCheckEmail,
    this.nicknameChecking = false,
    this.emailChecking = false,
    this.nicknameMessage,
    this.emailMessage,
    this.nicknameAvailable,
    this.emailAvailable,
    this.passwordErrorText,
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
  final VoidCallback? onCheckNickname;
  final VoidCallback? onCheckEmail;
  final bool nicknameChecking;
  final bool emailChecking;
  final String? nicknameMessage;
  final String? emailMessage;
  final bool? nicknameAvailable;
  final bool? emailAvailable;
  final String? passwordErrorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _checkField(
          label: '닉네임',
          fieldKey: const Key('nicknameField'),
          controller: nicknameController,
          validator: nicknameError,
          showValidation: nicknameShowsValidation,
          onChanged: onNicknameChanged,
          onSubmitted: (_) => emailFocusNode.requestFocus(),
          onCheck: onCheckNickname,
          busy: nicknameChecking,
          message: nicknameMessage,
          available: nicknameAvailable,
        ),
        const SizedBox(height: 7),
        _checkField(
          label: '이메일',
          fieldKey: const Key('emailField'),
          controller: emailController,
          validator: emailError,
          showValidation: emailShowsValidation,
          onChanged: onEmailChanged,
          onSubmitted: (_) => passwordFocusNode.requestFocus(),
          focusNode: emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          onCheck: onCheckEmail,
          busy: emailChecking,
          message: emailMessage,
          available: emailAvailable,
        ),
        const SizedBox(height: 7),
        MovieLogTextFormField(
          fieldKey: const Key('passwordField'),
          label: '비밀번호',
          hintText: '비밀번호를 입력해주세요',
          controller: passwordController,
          focusNode: passwordFocusNode,
          isPassword: true,
          textInputAction: TextInputAction.done,
          validator: passwordError,
          errorText: passwordErrorText,
          showValidation: passwordShowsValidation,
          onChanged: onPasswordChanged,
          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ],
    );
  }

  Widget _checkField({
    required String label,
    required Key fieldKey,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    required bool showValidation,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
    required VoidCallback? onCheck,
    required bool busy,
    required String? message,
    required bool? available,
    FocusNode? focusNode,
    TextInputType? keyboardType,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MovieLogTextFormField(
              fieldKey: fieldKey,
              label: label,
              hintText: label == '닉네임' ? '닉네임을 입력해주세요' : '이메일을 입력해주세요',
              controller: controller,
              validator: validator,
              showValidation: showValidation,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction: TextInputAction.next,
              showSuccessIcon: available == true && !busy,
              errorText: available == true ? null : message,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 26),
            child: Semantics(
              label: '$label 중복 확인',
              child: MovieLogButton(
                key: Key(
                  '${fieldKey == const Key('nicknameField') ? 'nickname' : 'email'}CheckButton',
                ),
                label: '중복 확인',
                isLoading: busy,
                onPressed: onCheck,
              ),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          height: 16,
          child: busy
              ? Text(
                  '$label 사용 가능 여부를 확인 중입니다.',
                  style: Week6Style.text(
                    12,
                    16,
                    color: Week6Style.checking,
                    weight: FontWeight.w700,
                  ),
                )
              : available == true && message != null
              ? Text(
                  message,
                  style: Week6Style.text(
                    12,
                    16,
                    color: Week6Style.success,
                    weight: FontWeight.w700,
                  ),
                )
              : null,
        ),
      ),
    ],
  );
}

class TermsAndSubmitSection extends StatelessWidget {
  const TermsAndSubmitSection({
    super.key,
    required this.agreedToTerms,
    required this.canSubmit,
    required this.onAgreementChanged,
    required this.onSubmit,
    required this.onLogin,
    this.isLoading = false,
  });

  final bool agreedToTerms;
  final bool canSubmit;
  final ValueChanged<bool> onAgreementChanged;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;
  final bool isLoading;

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
              SizedBox(
                width: 26,
                height: 26,
                child: Checkbox(
                  key: const Key('termsCheckbox'),
                  value: agreedToTerms,
                  onChanged: (value) => onAgreementChanged(value ?? false),
                  activeColor: Week6Style.primary,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  '필수 약관에 동의합니다',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Week6Style.ink,
                    fontSize: 14,
                    height: 19 / 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        MovieLogButton(
          key: const Key('registerButton'),
          label: '가입하기',
          isLoading: isLoading,
          fontSize: 14,
          width: double.infinity,
          disabledColor: Week6Style.disabled,
          onPressed: canSubmit ? onSubmit : null,
        ),
        const SizedBox(height: 54),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Flexible(
              child: Text(
                '이미 계정이 있나요?',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: Week6Style.ink,
                  fontSize: 14,
                  height: 19 / 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onLogin,
              child: const Text(
                '로그인',
                style: TextStyle(
                  color: Week6Style.primary,
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
  if (nickname.length > 12) return '닉네임은 12자 이하여야 합니다.';
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
  if (!RegExp(r'[a-z]').hasMatch(password) ||
      !RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password) ||
      !RegExp(r'[!@#$%^&*]').hasMatch(password)) {
    return '대문자·소문자·숫자·특수문자(!@#\$%^&*)를 포함해 주세요.';
  }
  return null;
}
