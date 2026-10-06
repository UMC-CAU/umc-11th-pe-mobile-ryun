import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'movie_grid_layout.dart';

class MovieListLoading extends StatefulWidget {
  const MovieListLoading({super.key});

  @override
  State<MovieListLoading> createState() => _MovieListLoadingState();
}

class _MovieListLoadingState extends State<MovieListLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '영화 목록 불러오는 중',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _opacity,
          child: LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: MovieGridLayout.padding,
              gridDelegate: MovieGridLayout.delegate(constraints.maxWidth),
              itemCount: 6,
              itemBuilder: (context, index) => const MovieCardSkeleton(),
            ),
          ),
        ),
      ),
    );
  }
}

class MovieCardSkeleton extends StatelessWidget {
  const MovieCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _SkeletonBlock()),
        SizedBox(height: 10),
        FractionallySizedBox(
          widthFactor: 0.8,
          child: _SkeletonBlock(height: 20),
        ),
        SizedBox(height: 6),
        FractionallySizedBox(
          widthFactor: 0.5,
          child: _SkeletonBlock(height: 14),
        ),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.genreChipBackground,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
