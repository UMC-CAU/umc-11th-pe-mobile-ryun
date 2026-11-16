import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'core/session/auth_session.dart';
import 'core/config/study_config.dart';
import 'theme/week6_style.dart';
import 'widgets/movielog_button.dart';

class SessionSplashScreen extends StatelessWidget {
  const SessionSplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthSession>();
    return Scaffold(
      backgroundColor: Week6Style.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'FLUTTER ${week8 ? 8 : 9}주차',
                              style: Week6Style.text(
                                11,
                                16,
                                color: Week6Style.body,
                                weight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 64),
                            SvgPicture.asset(
                              'assets/logos/movielog_logo.svg',
                              width: 84,
                              height: 84,
                              semanticsLabel: 'MovieLog 로고',
                            ),
                            const SizedBox(height: 32),
                            Text(
                              '영화의 순간을\n기록하세요',
                              textAlign: TextAlign.center,
                              style: Week6Style.text(
                                28,
                                36,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                              textAlign: TextAlign.center,
                              style: Week6Style.text(
                                14,
                                22,
                                color: Week6Style.body,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: session.restoreFailed
                              ? Column(
                                  children: [
                                    Text(
                                      session.notice ?? '로그인 상태를 확인하지 못했어요.',
                                      textAlign: TextAlign.center,
                                      style: Week6Style.text(
                                        12,
                                        18,
                                        color: Week6Style.body,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    MovieLogButton(
                                      label: '다시 시도',
                                      width: double.infinity,
                                      onPressed: session.restore,
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
