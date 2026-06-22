import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_l10n.dart';
import 'dashboard_screen.dart';
import 'tasks/tasks_screen.dart';
import 'activities_screen.dart';
import 'goals_screen.dart';
import 'profile_screen.dart';
import 'calendar/calendar_screen.dart';
import 'learning/learning_tracker_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    TasksScreen(),
    ActivitiesScreen(),
    GoalsScreen(),
    CalendarScreen(),
    LearningTrackerScreen(),
    ProfileScreen(),
  ];

  List<_NavItem> _navItems(L10n l10n) => [
    _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home,           label: l10n.navHome),
    _NavItem(icon: Icons.grid_view_outlined,     activeIcon: Icons.grid_view,      label: l10n.navTasks),
    _NavItem(icon: Icons.list_alt_outlined,      activeIcon: Icons.list_alt,       label: l10n.navActivities),
    _NavItem(icon: Icons.track_changes_outlined, activeIcon: Icons.track_changes,  label: l10n.navGoals),
    _NavItem(icon: Icons.calendar_month_outlined,activeIcon: Icons.calendar_month, label: l10n.navCalendar),
    _NavItem(icon: Icons.school_outlined,        activeIcon: Icons.school,         label: l10n.navLearning),
    _NavItem(icon: Icons.person_outline,         activeIcon: Icons.person,         label: l10n.navProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: _navItems(l10n),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          top: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pill indicator
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: selected ? 40 : 0,
                          height: selected ? 3 : 0,
                          margin: EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            gradient: selected
                                ? AppTheme.primaryGradient
                                : null,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 22,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w400,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}