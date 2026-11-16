import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'theme/week6_style.dart';

import 'package:provider/provider.dart';

import 'core/session/auth_session.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthSession>().loadMember();
    });
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 64,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Week6Style.navigationIndicator,
          elevation: 0,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Week6Style.primary
                  : Week6Style.body,
              size: 24,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => Week6Style.text(
              12,
              16,
              color: states.contains(WidgetState.selected)
                  ? Week6Style.primary
                  : Week6Style.body,
              weight: FontWeight.w700,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            for (final (asset, label) in [
              ('home', '홈'),
              ('movie', '영화'),
              ('person', '마이'),
            ])
              NavigationDestination(
                icon: SvgPicture.asset(
                  'assets/icons/$asset.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Week6Style.body,
                    BlendMode.srcIn,
                  ),
                ),
                selectedIcon: SvgPicture.asset(
                  'assets/icons/$asset.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Week6Style.primary,
                    BlendMode.srcIn,
                  ),
                ),
                label: label,
              ),
          ],
        ),
      ),
    );
  }
}
