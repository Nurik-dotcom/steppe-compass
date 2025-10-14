import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/region.dart';


import 'home_screen.dart';
import 'user_profile_screen.dart';
import 'direction_screen.dart';
import 'region_detail_screen.dart';
import 'place_detail_screen.dart';


import '../services/search_service.dart';

class RootShell extends StatefulWidget {
  
  final int initialIndex;
  const RootShell({super.key, this.initialIndex = 1});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index;

  final _searchKey  = GlobalKey<NavigatorState>();
  final _homeKey    = GlobalKey<NavigatorState>();
  final _profileKey = GlobalKey<NavigatorState>();

  List<GlobalKey<NavigatorState>> get _navKeys => [_searchKey, _homeKey, _profileKey];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 2);
  }

  Navigator _buildTabNavigator(GlobalKey<NavigatorState> key, Widget root) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => root);
          case '/directions':
            return MaterialPageRoute(builder: (_) => const DirectionsScreen());
          case '/region':
            final r = settings.arguments as Region;
            return MaterialPageRoute(builder: (_) => RegionDetailScreen(region: r));
          case '/place':
            final p = settings.arguments as Place;
            return MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: p));
        }
        return MaterialPageRoute(builder: (_) => root);
      },
    );
  }

  GlobalKey<NavigatorState> get _currentKey => _navKeys[_index];

  Future<bool> _onWillPop() async {
    final canPop = _currentKey.currentState?.canPop() ?? false;

    if (canPop) {
      _currentKey.currentState!.pop();
      return false;
    }
    if (_index != 1) {
      setState(() => _index = 1);
      return false;
    }
    return true;
  }

  void _popToRoot(GlobalKey<NavigatorState> key) {
    final nav = key.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((r) => r.isFirst);
    }
  }

  void _goHome() {
    _popToRoot(_currentKey);
    if (_index != 1) {
      setState(() => _index = 1);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _popToRoot(_homeKey));
  }

  void _goProfile() {
    _popToRoot(_currentKey);
    if (_index != 2) {
      setState(() => _index = 2);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _popToRoot(_profileKey));
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2196F3);
    const inactiveColor = Colors.white70;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            Offstage(
              offstage: _index != 0,
              child: TickerMode(
                enabled: _index == 0,
                child: _buildTabNavigator(_searchKey, const SearchView()),
              ),
            ),
            Offstage(
              offstage: _index != 1,
              child: TickerMode(
                enabled: _index == 1,
                child: _buildTabNavigator(_homeKey, HomeScreen()),
              ),
            ),
            Offstage(
              offstage: _index != 2,
              child: TickerMode(
                enabled: _index == 2,
                child: _buildTabNavigator(_profileKey, const UserProfileScreen()),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SizedBox(
          height: 70,
          width: 70,
          child: FloatingActionButton(
            onPressed: _goHome,
            shape: const CircleBorder(),
            backgroundColor: activeColor.withOpacity(0.85),
            elevation: 5,
            child: Image.asset(
              'assets/icons/yurt.png',
              width: 32,
              height: 32,
              color: Colors.white,
            ),
          ),
        ),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              top: false,
              bottom: false,
              child: BottomAppBar(
                color: activeColor.withOpacity(0.60),
                elevation: 0,
                shape: const CircularNotchedRectangle(),
                notchMargin: 6,
                child: SizedBox(
                  height: 58,
                  child: Row(
                    children: [
                      _NavBarItem(
                        iconActive: Icons.search_rounded,
                        iconInactive: Icons.search_outlined,
                        label: 'Поиск',
                        selected: _index == 0,
                        activeColor: Colors.white,
                        inactiveColor: inactiveColor,
                        onTap: () => setState(() => _index = 0),
                      ),
                      const SizedBox(width: 70), 
                      _NavBarItem(
                        iconActive: Icons.person_rounded,
                        iconInactive: Icons.person_outline,
                        label: 'Профиль',
                        selected: _index == 2,
                        activeColor: Colors.white,
                        inactiveColor: inactiveColor,
                        onTap: _goProfile,
                      ),
                    ],
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

class _NavBarItem extends StatelessWidget {
  final IconData iconActive;
  final IconData iconInactive;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.iconActive,
    required this.iconInactive,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          splashFactory: InkRipple.splashFactory,
          child: SizedBox.expand(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      selected ? iconActive : iconInactive,
                      size: 22,
                      color: selected ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? activeColor : inactiveColor,
                    ),
                    duration: const Duration(milliseconds: 180),
                    child: Text(label),
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
