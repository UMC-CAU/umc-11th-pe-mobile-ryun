import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/session/auth_session.dart';
import '../core/config/study_config.dart';

import '../theme/week6_style.dart';
import '../widgets/week8_ui.dart';
import '../widgets/movielog_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    if (!session.authenticated) {
      return Scaffold(
        appBar: Week8Ui.appBar('내 프로필', centered: false),
        body: Center(
          child: MovieLogButton(
            label: '로그인',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
    }
    return _buildProfile(context, session);
  }

  Widget _buildProfile(BuildContext context, AuthSession session) => Scaffold(
    backgroundColor: Week6Style.background,
    appBar: Week8Ui.appBar(
      '내 프로필',
      centered: false,
      actions: [
        TextButton(
          onPressed: () async {
            try {
              await session.logout();
            } on Object {
              /* Retry on login. */
            }
            if (context.mounted) context.go('/login');
          },
          child: Text(
            '로그아웃',
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
    body: SafeArea(
      top: false,
      child: switch (session.memberStatus) {
        MemberLoadStatus.loading => const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
        MemberLoadStatus.error => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '내 정보를 불러오지 못했어요.',
                  style: Week6Style.text(14, 20, color: Week6Style.body),
                ),
                const SizedBox(height: 24),
                MovieLogButton(
                  label: '다시 시도',
                  width: 218,
                  onPressed: session.loadMember,
                ),
              ],
            ),
          ),
        ),
        _ => SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 25, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Week6Style.primary,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Transform.scale(
                            scale: 1.15,
                            child: Image.asset(
                              'assets/images/profile/profile_movielog.jpg',
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -0.45),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      session.nickname ?? '',
                      textAlign: TextAlign.center,
                      style: Week6Style.text(20, 27, weight: FontWeight.w700),
                    ),
                    if (session.createdAt case final date?) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} 가입',
                        textAlign: TextAlign.center,
                        style: Week6Style.text(11, 16, color: Week6Style.hint),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      session.email ?? '',
                      textAlign: TextAlign.center,
                      style: Week6Style.text(12, 18, color: Week6Style.body),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: SizedBox(
                        width: 128,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () => context.push('/my/profile/edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Week6Style.primary,
                            side: const BorderSide(color: Week6Style.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            textStyle: Week6Style.text(
                              15,
                              20,
                              weight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('프로필 수정'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // v7 has no statistics contract. Preserve the frame without inventing totals.
                    Row(
                      children: [
                        _stat('본 영화', '—'),
                        const SizedBox(width: 8),
                        _stat('평점', '—'),
                        const SizedBox(width: 8),
                        _stat('즐겨찾기', '—'),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Week6Style.entryBorder,
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push('/my/ratings'),
                        child: SizedBox(
                          height: 64,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '내가 등록한 평점',
                                    style: Week6Style.text(
                                      16,
                                      22,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Week6Style.primary,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!week8) ...[
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Week6Style.entryBorder,
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push('/my/favorites'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '내 즐겨찾기',
                                    style: Week6Style.text(
                                      17,
                                      24,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Week6Style.primary,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Text(
                      '선호하는 장르',
                      style: Week6Style.text(17, 23, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['드라마', 'SF', '애니메이션']
                          .map(
                            (label) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Week6Style.chip,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: Week6Style.text(
                                  12,
                                  17,
                                  color: Week6Style.primary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      },
    ),
  );

  Widget _stat(String label, String value) => Expanded(
    child: Container(
      height: 86,
      decoration: BoxDecoration(
        color: Week6Style.background,
        border: Border.all(color: Week6Style.statBorder),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Week6Style.text(
              12,
              16,
              color: Week6Style.body,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Week6Style.text(
              23,
              31,
              color: Week6Style.primary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
