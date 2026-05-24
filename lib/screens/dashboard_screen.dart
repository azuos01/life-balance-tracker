import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/areas_provider.dart';
import '../providers/activities_provider.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/life_wheel_chart.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/area_card.dart';
import 'logging/morning_checkin_screen.dart';
import 'logging/evening_checkout_screen.dart';
import 'logging/add_activity_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final areas = context.watch<AreasProvider>().areas;
    final balance = context.watch<AreasProvider>().overallBalance;
    final acts = context.watch<ActivitiesProvider>();

    if (user == null) return const SizedBox();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            title: Row(
              children: [
                const Text('⚖️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Olá, ${user.name.split(' ').first}!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              _StreakChip(streak: user.currentStreak),
              const SizedBox(width: 12),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Check-in cards
                  _CheckInBanners(acts: acts),
                  const SizedBox(height: 16),
                  // XP bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: XpProgressBar(totalXP: user.totalXP),
                  ),
                  const SizedBox(height: 16),
                  // Life Wheel
                  _LifeWheelSection(areas: areas, balance: balance),
                  const SizedBox(height: 16),
                  // Today's activities
                  _TodayActivities(acts: acts),
                  const SizedBox(height: 16),
                  // Areas grid
                  _AreasGrid(areas: areas),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddActivityScreen()),
        ),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '+ Atividade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;
  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: streak > 0
            ? const Color(0xFFFF6348).withOpacity(0.15)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: streak > 0
              ? const Color(0xFFFF6348).withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$streak dias',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: streak > 0
                  ? const Color(0xFFFF6348)
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInBanners extends StatelessWidget {
  final ActivitiesProvider acts;
  const _CheckInBanners({required this.acts});

  @override
  Widget build(BuildContext context) {
    final hasMorning = acts.hasMorningCheckIn;
    final hasEvening = acts.hasEveningCheckIn;

    if (hasMorning && hasEvening) return const SizedBox();

    return Column(
      children: [
        if (!hasMorning)
          _BannerCard(
            emoji: '☀️',
            title: 'Check-in Matinal',
            subtitle: 'Como você está hoje?',
            color: const Color(0xFFFFD32A),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MorningCheckInScreen()),
            ),
          ),
        if (!hasMorning && !hasEvening) const SizedBox(height: 8),
        if (!hasEvening)
          _BannerCard(
            emoji: '🌙',
            title: 'Check-out Noturno',
            subtitle: 'Reflita sobre seu dia',
            color: AppTheme.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EveningCheckoutScreen()),
            ),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BannerCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _LifeWheelSection extends StatelessWidget {
  final List areas;
  final double balance;

  const _LifeWheelSection({required this.areas, required this.balance});

  @override
  Widget build(BuildContext context) {
    final scores = areas.map((a) => (a.currentScore as double)).toList();
    final labels = areas.map((a) => a.name as String).toList();
    final icons = areas.map((a) => a.icon as String).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Roda da Vida',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${balance.toStringAsFixed(0)}% equilíbrio',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: LifeWheelChart(
              scores: scores.cast<double>(),
              labels: labels.cast<String>(),
              icons: icons.cast<String>(),
              size: 280,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayActivities extends StatelessWidget {
  final ActivitiesProvider acts;
  const _TodayActivities({required this.acts});

  @override
  Widget build(BuildContext context) {
    final todayActs = acts.todayActivities;
    if (todayActs.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoje',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...todayActs.take(3).map((a) {
          final areaConfig = kAreas.firstWhere(
            (c) => c.id == a.areaId,
            orElse: () => kAreas.first,
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(areaConfig.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${a.durationMinutes} min • ${a.difficulty}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${a.xpEarned} XP',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _AreasGrid extends StatelessWidget {
  final List areas;
  const _AreasGrid({required this.areas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suas Áreas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: areas.length,
          itemBuilder: (context, i) {
            return AreaCard(
              area: areas[i],
              colorIndex: i,
            );
          },
        ),
      ],
    );
  }
}
