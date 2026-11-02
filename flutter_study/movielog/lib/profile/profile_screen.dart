import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/week6_style.dart';
import '../widgets/week6_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Week6Style.background,
    appBar: const Week6AppBar(title: '내 프로필', centerTitle: false),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 25, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Week6Style.primary, width: 2),
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
                    '무비러버',
                    textAlign: TextAlign.center,
                    style: Week6Style.text(20, 27, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    '매주 주말엔 영화관으로 출근하는 프로 관람객.',
                    textAlign: TextAlign.center,
                    style: Week6Style.text(13, 18, color: Week6Style.body),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '좋은 영화를 보고 기록하는 것을 좋아합니다.',
                    textAlign: TextAlign.center,
                    style: Week6Style.text(13, 18, color: Week6Style.body),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width: 128,
                      height: 40,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Week6Style.primary,
                          padding: EdgeInsets.zero,
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
                  const SizedBox(height: 33),
                  Row(
                    children: [
                      _stat('본 영화', '342'),
                      const SizedBox(width: 8),
                      _stat('평점', '4.2'),
                      const SizedBox(width: 8),
                      _stat('즐겨찾기', '58'),
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
                  const SizedBox(height: 28),
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
                            height: 33,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Week6Style.chip,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  label,
                                  style: Week6Style.text(
                                    12,
                                    16,
                                    color: Week6Style.primary,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
