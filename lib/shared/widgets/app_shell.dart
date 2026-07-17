import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../utils/extensions.dart';

/// One tab of an [AppShell].
class ShellDestination {
  const ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final WidgetBuilder builder;
}

/// Persistent bottom navigation around a set of top-level screens.
///
/// A custom bar rather than Flutter's [BottomNavigationBar]: that widget's
/// default look is a Material elevation/shadow surface, which fights
/// `AppTheme` (every component there sets elevation: 0) more than it costs to
/// just build the five rows this needs directly from [AppColors]/[AppRadius].
///
/// Tabs are kept alive with [IndexedStack] rather than rebuilt on switch, so a
/// scroll position or an in-flight load on one tab survives a trip to another
/// and back.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.destinations, this.initialIndex = 0});

  final List<ShellDestination> destinations;
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  void _goTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      goTo: _goTo,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (final d in widget.destinations) Builder(builder: d.builder),
          ],
        ),
        bottomNavigationBar: _ShellNavBar(
          destinations: widget.destinations,
          index: _index,
          onChanged: _goTo,
        ),
      ),
    );
  }
}

/// Lets a tab's own content switch tabs — the driver home's notification bell
/// and profile avatar use this to jump straight to those tabs rather than
/// pushing a second copy of the screen on top.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.goTo, required super.child});

  final ValueChanged<int> goTo;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) => goTo != oldWidget.goTo;
}

class _ShellNavBar extends StatelessWidget {
  const _ShellNavBar({
    required this.destinations,
    required this.index,
    required this.onChanged,
  });

  final List<ShellDestination> destinations;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? destination.selectedIcon : destination.icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 3),
          Text(
            destination.label,
            style: context.text.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
