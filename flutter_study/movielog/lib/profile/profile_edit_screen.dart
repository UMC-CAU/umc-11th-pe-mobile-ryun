import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/session/auth_session.dart';
import '../data/services/sign_up_service.dart';
import '../widgets/week8_ui.dart';
import '../widgets/movielog_button.dart';
import '../theme/week6_style.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final _nickname = TextEditingController(
    text: context.read<AuthSession>().nickname,
  );
  late final _email = TextEditingController(
    text: context.read<AuthSession>().email,
  );
  bool _saving = false;
  bool _allowPop = false;
  String? _error;
  bool get _dirty =>
      _nickname.text.trim() != context.read<AuthSession>().nickname;
  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '변경 내용을 버릴까요?',
                  textAlign: TextAlign.center,
                  style: Week6Style.text(20, 28, weight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                Text(
                  '저장하지 않은 내용은 사라집니다.',
                  style: Week6Style.text(13, 20, color: Week6Style.body),
                ),
                const SizedBox(height: 64),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF0EAF8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('계속 수정'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MovieLogButton(
                        label: '나가기',
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) {
      setState(() => _allowPop = true);
      context.go('/my');
    }
  }

  Future<void> _save() async {
    final name = _nickname.text.trim();
    if (name.length < 2 || name.length > 12) {
      setState(() => _error = '닉네임은 2~12자로 입력해 주세요.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final session = context.read<AuthSession>();
    final version = session.generation;
    try {
      await session.updateNickname(context.read<ProfileAuthClient>().dio, name);
      if (!mounted || !session.current(version)) return;
      setState(() => _allowPop = true);
      context.go('/my');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('닉네임을 수정했습니다.')));
    } on DioException catch (e) {
      if (mounted && session.current(version)) {
        setState(
          () => _error = apiErrorMessage(
            e,
            fallback: '닉네임을 저장하지 못했어요. 연결 확인 후 다시 시도해 주세요.',
          ),
        );
      }
    } on Object {
      if (mounted && session.current(version)) {
        setState(() => _error = '닉네임을 저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      backgroundColor: Week6Style.background,
      appBar: Week8Ui.appBar('프로필 수정', onBack: _saving ? null : _leave),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              children: [
                Week8Field(
                  fieldKey: const Key('profileEmail'),
                  label: '이메일 (변경할 수 없습니다)',
                  controller: _email,
                  readOnly: true,
                ),
                const SizedBox(height: 96),
                Week8Field(
                  fieldKey: const Key('profileNickname'),
                  label: '닉네임',
                  controller: _nickname,
                  hint: '닉네임을 입력해 주세요',
                  enabled: !_saving,
                  error: _error,
                  characterLimit: 12,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 16, 24, 56),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 342),
            child: MovieLogButton(
              label: '저장',
              fontSize: 14,
              width: double.infinity,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ),
      ),
    ),
  );
}

class ProfileAuthClient {
  ProfileAuthClient(this.dio);
  final Dio dio;
}
