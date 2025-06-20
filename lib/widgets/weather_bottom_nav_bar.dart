import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class WeatherBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const WeatherBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<WeatherBottomNavigationBar> createState() => _WeatherBottomNavigationBarState();
}

class _WeatherBottomNavigationBarState extends State<WeatherBottomNavigationBar> with TickerProviderStateMixin {
  late AnimationController _iconAnimationController;

  final List<IconData> iconList = [Icons.wb_sunny_outlined, Icons.settings_outlined];

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    _iconAnimationController.forward(from: 0);
    widget.onTap(index);
  }

  Widget _animatedIcon(int index) {
    bool isActive = widget.currentIndex == index;
    IconData icon = index == 0 ? Icons.wb_sunny_rounded : Icons.settings;

    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _iconAnimationController, curve: Curves.elasticOut),
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.orangeAccent : Colors.grey[400],
        size: isActive ? 30 : 24,
        shadows: isActive
            ? [
          const Shadow(
            blurRadius: 10,
            color: Colors.orange,
            offset: Offset(0, 0),
          ),
        ]
            : [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavigationBar.builder(
      itemCount: iconList.length,
      tabBuilder: (index, isActive) => _animatedIcon(index),
      activeIndex: widget.currentIndex,
      splashColor: Colors.lightBlueAccent.withOpacity(0.2),
      notchSmoothness: NotchSmoothness.softEdge,
      gapLocation: GapLocation.center,
      backgroundColor: Colors.white,
      leftCornerRadius: 24,
      rightCornerRadius: 24,
      onTap: _handleTap,
    );
  }
}
