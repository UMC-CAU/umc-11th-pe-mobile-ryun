import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/about_view_model.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const routePath = '/my/about';
  static const attribution =
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.warmWhite,
    appBar: AppBar(
      centerTitle: true,
      title: Text(
        '앱 정보',
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
      leading: IconButton(
        tooltip: '뒤로가기',
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/logos/movielog_logo.png',
                  width: 120,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'MovieLog',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                '버전 ${context.watch<AboutViewModel>().versionLabel}',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '영화 정보 · TMDB',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Image.asset('assets/logos/tmdb_logo.png', width: 96),
                    const SizedBox(height: 20),
                    const Text(attribution, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    const SelectableText(
                      'https://www.themoviedb.org',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('오픈소스 라이선스', style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              const Text(
                'Manrope · Material Symbols',
                style: AppTextStyles.bodyMedium,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'MovieLog',
                  ),
                  child: const Text(
                    'Flutter/패키지 라이선스 보기',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
