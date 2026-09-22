import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/common_app_bar.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _stats = [
    ProfileStat(label: '본 영화', value: '342'),
    ProfileStat(label: '평점', value: '4.2'),
    ProfileStat(label: '즐겨찾기', value: '58'),
  ];

  static const _genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = math.min(constraints.maxWidth / 390, 1.0);

                return SingleChildScrollView(
                  child: ProfileBody(
                    scale: scale,
                    stats: _stats,
                    genres: _genres,
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

class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.scale,
    required this.stats,
    required this.genres,
  });

  final double scale;
  final List<ProfileStat> stats;
  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 780 * scale,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * scale,
          vertical: 24 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(scale: scale),
            SizedBox(height: 32 * scale),
            EditProfileButton(scale: scale),
            SizedBox(height: 32 * scale),
            ProfileStats(scale: scale, stats: stats),
            SizedBox(height: 32 * scale),
            FavoriteGenres(scale: scale, genres: genres),
          ],
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileAvatar(
          scale: scale,
          imagePath: 'assets/images/profile/profile_movielog.jpg',
        ),
        SizedBox(height: 24 * scale),
        ProfileText(scale: scale),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.scale, this.imagePath});

  final double scale;

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final outerSize = 128 * scale;
    final innerSize = 124 * scale;

    return Container(
      width: outerSize,
      height: outerSize,
      padding: EdgeInsets.all(2 * scale),
      decoration: const BoxDecoration(
        color: AppColors.lightViolet,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: imagePath == null
            ? ColoredBox(
                color: colors.primaryContainer,
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 64 * scale,
                    color: colors.primary,
                  ),
                ),
              )
            : Image.asset(
                imagePath!,
                width: innerSize,
                height: innerSize,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class ProfileText extends StatelessWidget {
  const ProfileText({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 318 * scale,
      child: Column(
        children: [
          SizedBox(
            height: 28 * scale,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '무비러버',
                    style: TextStyle(
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.w500,
                      height: 28 / 22,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(width: 4 * scale),
                  SvgPicture.asset(
                    'assets/icons/check_circle.svg',
                    width: 20 * scale,
                    height: 20 * scale,
                    semanticsLabel: '인증된 사용자',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            height: 48 * scale,
            child: Center(
              child: Text(
                '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋아하는 영화를 기록하고 있어요.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  color: AppColors.bodyText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 127 * scale,
        height: 42 * scale,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.primary,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 24 * scale, vertical: 8 * scale),
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8 * scale),
            ),
          ),
          child: Text(
            '프로필 수정',
            maxLines: 1,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w500,
              height: 24 / 16,
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key, required this.scale, required this.stats});

  final double scale;
  final List<ProfileStat> stats;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86 * scale,
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 4 * scale,
                right: index == stats.length - 1 ? 0 : 4 * scale,
              ),
              child: StatItem(scale: scale, stat: stat),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ProfileStat {
  const ProfileStat({required this.label, required this.value});

  final String label;
  final String value;
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.scale, required this.stat});

  final double scale;
  final ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: AppColors.statSurface,
        border: Border.all(color: AppColors.primaryContainer),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              color: AppColors.bodyText,
            ),
          ),
          SizedBox(height: 8 * scale),
          Text(
            stat.value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 22 * scale,
              fontWeight: FontWeight.w700,
              height: 22 / 22,
              color: AppColors.violet,
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key, required this.scale, required this.genres});

  final double scale;
  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72 * scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24 * scale,
            child: Text(
              '선호하는 장르',
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w500,
                height: 24 / 16,
                color: AppColors.black,
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          SizedBox(
            height: 32 * scale,
            child: Wrap(
              spacing: 8 * scale,
              children: genres
                  .map((genre) => GenreChip(scale: scale, label: genre))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.scale, required this.label});

  final double scale;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32 * scale,
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12 * scale,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: AppColors.violet,
        ),
      ),
    );
  }
}
