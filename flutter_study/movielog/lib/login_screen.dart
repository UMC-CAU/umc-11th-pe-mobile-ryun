import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/study_config.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/session/auth_session.dart';
import 'data/services/sign_up_service.dart';
import 'widgets/movielog_button.dart';
import 'widgets/week8_ui.dart';
import 'theme/week6_style.dart';

import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _rememberEmail = false;
  final _preferences = SharedPreferencesAsync();
  @override
  void initState() {
    super.initState();
    if (week8) _loadEmail();
  }

  Future<void> _loadEmail() async {
    final saved = await _preferences.getString('movielog.rememberedEmail');
    if (mounted && _email.text.isEmpty && saved != null) {
      setState(() {
        _email.text = saved;
        _rememberEmail = true;
      });
    }
  }

  AuthSession? _session;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.read<AuthSession>();
    if (!identical(_session, session)) {
      _session?.removeListener(_expired);
      _session = session;
      session.addListener(_expired);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _expired());
  }

  void _expired() {
    if (!mounted || _session?.sessionExpired != true) return;
    _session!.consumeSessionExpired();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _session?.removeListener(_expired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력해 주세요.');
      return;
    }
    final session = context.read<AuthSession>();
    setState(() => _error = null);
    try {
      await session.login(_email.text, _password.text);
      if (!mounted || !session.authenticated) return;
      if (week8) {
        try {
          if (_rememberEmail) {
            await _preferences.setString(
              'movielog.rememberedEmail',
              _email.text.trim(),
            );
          } else {
            await _preferences.remove('movielog.rememberedEmail');
          }
        } on Object {
          /* Email preference does not change authentication. */
        }
      }
      if (!mounted) return;
      _password.clear();
      context.go('/movies');
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => _error = apiErrorMessage(
            error,
            fallback: '로그인하지 못했습니다. 연결을 확인해 주세요.',
          ),
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _error = '로그인 정보를 안전하게 저장하지 못했습니다. 다시 시도해 주세요.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    final enabled =
        !session.busy &&
        !session.storageCleanupInProgress &&
        !session.cleanupFailed;
    return PopScope(
      canPop: !session.busy,
      child: Scaffold(
        backgroundColor: Week6Style.background,
        appBar: Week8Ui.appBar('로그인'),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/logos/movielog_logo.svg',
                      width: 84,
                      height: 84,
                      semanticsLabel: 'MovieLog 로고',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MovieLog에 로그인',
                    textAlign: TextAlign.center,
                    style: Week6Style.text(24, 32, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 32),
                  Week8Field(
                    fieldKey: const Key('loginEmail'),
                    label: '이메일',
                    hint: '이메일을 입력해 주세요',
                    controller: _email,
                    enabled: enabled,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  Week8Field(
                    fieldKey: const Key('loginPassword'),
                    label: '비밀번호',
                    hint: '비밀번호를 입력해 주세요',
                    controller: _password,
                    enabled: enabled,
                    obscureText: true,
                    error: _error,
                    onSubmitted: (_) {
                      if (enabled) _login();
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 24,
                    child: week8
                        ? Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberEmail,
                                  onChanged: enabled
                                      ? (value) async {
                                          setState(
                                            () =>
                                                _rememberEmail = value ?? false,
                                          );
                                          if (!_rememberEmail) {
                                            try {
                                              await _preferences.remove(
                                                'movielog.rememberedEmail',
                                              );
                                            } on Object {
                                              /* Optional preference. */
                                            }
                                          }
                                        }
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: enabled
                                    ? () async {
                                        setState(
                                          () =>
                                              _rememberEmail = !_rememberEmail,
                                        );
                                        if (!_rememberEmail) {
                                          try {
                                            await _preferences.remove(
                                              'movielog.rememberedEmail',
                                            );
                                          } on Object {
                                            /* Optional preference. */
                                          }
                                        }
                                      }
                                    : null,
                                child: Text(
                                  '이메일 저장',
                                  style: Week6Style.text(
                                    12,
                                    18,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                  if (session.notice != null && _error == null) ...[
                    const SizedBox(height: 12),
                    Text(
                      session.notice!,
                      style: Week6Style.text(
                        12,
                        18,
                        color: const Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                  const SizedBox(height: 48),
                  MovieLogButton(
                    label: '로그인',
                    width: double.infinity,
                    fontSize: 14,
                    isLoading: session.busy,
                    onPressed: enabled ? _login : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '계정이 없나요?',
                        style: Week6Style.text(12, 18, color: Week6Style.body),
                      ),
                      TextButton(
                        onPressed: enabled
                            ? () => context.push('/register')
                            : null,
                        child: Text(
                          '회원가입',
                          style: Week6Style.text(
                            12,
                            18,
                            color: Week6Style.primary,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (session.cleanupFailed)
                    TextButton(
                      onPressed: session.busy ? null : session.restore,
                      child: const Text('저장된 세션 다시 확인'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
