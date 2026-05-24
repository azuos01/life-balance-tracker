import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/areas_provider.dart';
import '../providers/activities_provider.dart';
import '../providers/tasks_provider.dart';
import '../models/task_model.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../services/quotes_service.dart';
import '../widgets/life_wheel_chart.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/area_card.dart';
import 'logging/morning_checkin_screen.dart';
import 'logging/evening_checkout_screen.dart';
import 'logging/add_activity_screen.dart';
import 'tasks/task_create_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final areas = context.watch<AreasProvider>().areas;
    final balance = context.watch<AreasProvider>().overallBalance;
    final acts = context.watch<ActivitiesProvider>();
    final tasks = context.watch<TasksProvider>();

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
                  // ── Hero: descrição do app ──────────────────────────────
                  _AppHeroCard(),
                  const SizedBox(height: 12),

                  // ── Frase filosófica do dia ─────────────────────────────
                  _DailyQuoteCard(),
                  const SizedBox(height: 16),

                  // ── Check-in cards ──────────────────────────────────────
                  _CheckInBanners(acts: acts),
                  const SizedBox(height: 16),

                  // ── Bloco MIT ───────────────────────────────────────────
                  _MITBlock(tasks: tasks),
                  const SizedBox(height: 16),

                  // ── XP bar ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: XpProgressBar(totalXP: user.totalXP),
                  ),
                  const SizedBox(height: 16),

                  // ── Life Wheel ──────────────────────────────────────────
                  _LifeWheelSection(areas: areas, balance: balance),
                  const SizedBox(height: 16),

                  // ── Atividades de hoje ──────────────────────────────────
                  _TodayActivities(acts: acts),
                  const SizedBox(height: 16),

                  // ── Areas grid ─────────────────────────────────────────
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

// ── App Hero Card ─────────────────────────────────────────────────────────────

class _AppHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.85),
            AppTheme.primary.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚖️', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Life Balance Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Transforme intenções em ações. Execute as 3 tarefas MIT do dia, organize pela Matriz de Eisenhower e acompanhe o equilíbrio das 10 áreas da sua vida.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _HeroPill('⭐ MIT'),
                    _HeroPill('⚡ Eisenhower'),
                    _HeroPill('🎯 Roda da Vida'),
                    _HeroPill('🔥 Streaks'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  const _HeroPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Daily Quote Card ──────────────────────────────────────────────────────────

class _DailyQuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final quote = QuotesService.instance.getDailyQuote();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💭', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Text(
                'Reflexão do Dia',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${quote.text}"',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${quote.author}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MIT Block ─────────────────────────────────────────────────────────────────

class _MITBlock extends StatelessWidget {
  final TasksProvider tasks;
  const _MITBlock({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final mits = tasks.activeMITs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tarefas MIT do Dia',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Most Important Tasks · ${mits.length}/3',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (tasks.canAddMIT)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TaskCreateScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: const Text(
                      '+ Definir MIT',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (mits.isEmpty)
            _EmptyMIT()
          else
            ...mits.map((t) => _MITTile(task: t)),
        ],
      ),
    );
  }
}

class _EmptyMIT extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          const Text(
            'Defina suas 3 tarefas MIT',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'As 3 tarefas mais importantes do dia.\nSe só essas forem feitas, o dia terá valido a pena.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TaskCreateScreen()),
            ),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text(
              'Criar primeira MIT',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MITTile extends StatelessWidget {
  final TaskModel task;
  const _MITTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final area = kAreas.firstWhere(
      (a) => a.id == task.areaId,
      orElse: () => kAreas.first,
    );
    final qColor = switch (task.eisenhowerQ) {
      1 => Colors.red,
      2 => Colors.green,
      3 => Colors.orange,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // MIT number
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${task.mitOrder}',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(area.icon, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 3),
                    Text(
                      area.name,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: qColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${task.eisenhowerEmoji} Q${task.eisenhowerQ}',
                        style: TextStyle(
                          fontSize: 9,
                          color: qColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Progress indicator for subtasks
          if (task.subtasks.isNotEmpty)
            SizedBox(
              width: 36,
              height: 36,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: task.progress,
                    strokeWidth: 3,
                    backgroundColor: AppTheme.divider,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                  Center(
                    child: Text(
                      '${(task.progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Streak chip ───────────────────────────────────────────────────────────────

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

// ── Check-in banners ──────────────────────────────────────────────────────────

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

// ── Life Wheel ────────────────────────────────────────────────────────────────

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

// ── Today Activities ──────────────────────────────────────────────────────────

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
          'Atividades de Hoje',
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

// ── Areas Grid ────────────────────────────────────────────────────────────────

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
            return AreaCard(area: areas[i], colorIndex: i);
          },
        ),
      ],
    );
  }
}
