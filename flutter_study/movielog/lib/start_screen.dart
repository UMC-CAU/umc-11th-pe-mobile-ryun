import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  static const _background = Color(0xFFFAF9F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Figma 기준 캔버스(390 x 884)가 작은 화면에도 들어가도록 축소합니다.
                final scale = math.min(
                  constraints.maxWidth / 390,
                  constraints.maxHeight / 884,
                );

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    16 * scale,
                    32 * scale,
                    16 * scale,
                    32 * scale,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _IntroContent(scale: scale),
                      _StartButton(scale: scale),
                    ],
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

class _IntroContent extends StatelessWidget {
  const _IntroContent({required this.scale});

  final double scale;

  static const _purple = Color(0xFF4F378A);
  static const _text = Color(0xFF1B1C1A);
  static const _subtext = Color(0xFF494551);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 352 * scale,
      child: Padding(
        padding: EdgeInsets.only(top: 32 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 주차 레이아웃: 79 x 40, 아래 여백 24
            SizedBox(
              height: 40 * scale,
              child: Padding(
                padding: EdgeInsets.only(bottom: 24 * scale),
                child: Center(
                  child: Text(
                    'FLUTTER 0주차',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _subtext,
                      fontFamily: 'Manrope',
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.w500,
                      height: 16 / 11,
                      letterSpacing: 0.55 * scale,
                    ),
                  ),
                ),
              ),
            ),
            // 아이콘 레이아웃: 128 x 160, 아래 여백 32
            SizedBox(
              height: 160 * scale,
              child: Padding(
                padding: EdgeInsets.only(bottom: 32 * scale),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 72 * scale,
                    height: 72 * scale,
                    semanticsLabel: 'MovieLog 영화 아이콘',
                  ),
                ),
              ),
            ),
            // 텍스트 묶음: 358 x 120, 좌우 여백 8, 항목 간격 8
            SizedBox(
              height: 120 * scale,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                child: Column(
                  children: [
                    SizedBox(
                      height: 72 * scale,
                      child: Center(
                        child: Text(
                          '영화의 순간을\n기록하세요',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _text,
                            fontFamily: 'Manrope',
                            fontSize: 28 * scale,
                            fontWeight: FontWeight.w500,
                            height: 36 / 28,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    SizedBox(
                      height: 40 * scale,
                      child: Center(
                        child: Text(
                          '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _subtext,
                            fontFamily: 'Manrope',
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.w500,
                            height: 20 / 14,
                            letterSpacing: 0.25 * scale,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.scale});

  final double scale;

  static const _purple = Color(0xFF4F378A);

  @override
  Widget build(BuildContext context) {
    // 버튼 레이아웃: 358 x 80, 내부 버튼: 326 x 56
    return SizedBox(
      height: 80 * scale,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 * scale, 0, 16 * scale, 24 * scale),
        child: ElevatedButton(
          onPressed: () {
            debugPrint('시작하기 버튼을 눌렀습니다.');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            elevation: 1,
            shadowColor: const Color(0x0D000000),
            padding: EdgeInsets.symmetric(
              horizontal: 24 * scale,
              vertical: 8 * scale,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16 * scale),
            ),
          ),
          child: Text(
            '시작하기',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
