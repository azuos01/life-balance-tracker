import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/areas_provider.dart';
import '../providers/activities_provider.dart';
import '../providers/tasks_provider.dart';
import '../providers/weather_provider.dart';
import '../models/task_model.dart';
import '../models/weather_model.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../services/quotes_service.dart';
import '../widgets/life_wheel_chart.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/area_card.dart';
import '../widgets/app_background.dart';
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

    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: Colors.transparent,
            title: Row(
              children: [
                const Text('⚖️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Olá, ${user.name.split(' ').first}!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            actions: [
              _StreakChip(streak: user.currentStreak),
              SizedBox(width: 12),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Hero: descrição do app ──────────────────────────────
                  _AppHeroCard(),
                  SizedBox(height: 12),

                  // ── Frase filosófica do dia ─────────────────────────────
                  _DailyQuoteCard(),
                  SizedBox(height: 12),

                  // ── Clima + alertas de tarefas ──────────────────────────
                  _WeatherCard(tasks: tasks),
                  SizedBox(height: 16),

                  // ── Check-in cards ──────────────────────────────────────
                  _CheckInBanners(acts: acts),
                  SizedBox(height: 16),

                  // ── Bloco MIT ───────────────────────────────────────────
                  _MITBlock(tasks: tasks),
                  SizedBox(height: 16),

                  // ── XP bar ──────────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                      boxShadow: AppTheme.cardShadow,
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
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '+ Atividade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    ),
    );
  }
}

// ── Weather Card ──────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  final TasksProvider tasks;
  const _WeatherCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();

    if (!wp.hasData && !wp.loading && wp.city.isEmpty) {
      return _WeatherSetupPrompt(onSetup: () => _showCityDialog(context, wp));
    }

    if (wp.loading && !wp.hasData) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (wp.error != null && !wp.hasData) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                wp.error!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => _showCityDialog(context, wp),
              child: const Text('Trocar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (!wp.hasData) return const SizedBox();

    final weather = wp.data!;
    final sensitiveTasks = weather.isBadWeather
        ? tasks.tasks
            .where((t) => t.status != 'completed' && t.isOutdoor)
            .toList()
        : <TaskModel>[];

    return Column(
      children: [
        // Card principal do clima
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: weather.isBadWeather
                  ? [const Color(0xFF2C3E50), const Color(0xFF3D5166)]
                  : [const Color(0xFF1A6B3C), const Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha principal
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Text(
                      WeatherData.emoji(weather.current.code),
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather.current.temperature.toStringAsFixed(0)}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            WeatherData.description(weather.current.code),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _showCityDialog(context, wp),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: Colors.white70, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                weather.city,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                              const Icon(Icons.edit,
                                  color: Colors.white38, size: 11),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => wp.fetch(weather.city),
                          child: const Icon(Icons.refresh,
                              color: Colors.white54, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Mini-previsão 3 dias
              if (weather.forecast.isNotEmpty)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black12,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(18)),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weather.forecast
                        .map((d) => _ForecastDay(day: d))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),

        // Alerta de tarefas sensíveis
        if (sensitiveTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Condições desfavoráveis para ${sensitiveTasks.length} tarefa(s) ao ar livre:',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...sensitiveTasks.take(3).map((t) => Padding(
                      padding: const EdgeInsets.only(left: 24, top: 2),
                      child: Text(
                        '• ${t.title}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                if (sensitiveTasks.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, top: 2),
                    child: Text(
                      '+ ${sensitiveTasks.length - 3} mais...',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showCityDialog(BuildContext context, WeatherProvider wp) {
    final ctrl = TextEditingController(text: wp.city);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Cidade',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Ex: São Paulo, Brasília...',
            hintStyle:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.divider)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primary)),
          ),
          onSubmitted: (v) {
            Navigator.pop(context);
            if (v.trim().isNotEmpty) wp.fetch(v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (ctrl.text.trim().isNotEmpty) wp.fetch(ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white),
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}

class _WeatherSetupPrompt extends StatelessWidget {
  final VoidCallback onSetup;
  const _WeatherSetupPrompt({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSetup,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            const Text('🌤️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Previsão do Tempo',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text('Toque para configurar sua cidade',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ForecastDay extends StatelessWidget {
  final WeatherDay day;
  const _ForecastDay({required this.day});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          WeatherData.shortDay(day.date),
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(WeatherData.emoji(day.code),
            style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          '${day.tempMax.toStringAsFixed(0)}° / ${day.tempMin.toStringAsFixed(0)}°',
          style:
              const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }
}

// ── App Hero Card ─────────────────────────────────────────────────────────────

class _AppHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A4FCC), Color(0xFF7C6FFF), Color(0xFF9D5FE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.glowShadow(AppTheme.primary, blur: 30, opacity: 0.35),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: const Center(
              child: Text('⚖️', style: TextStyle(fontSize: 26)),
            ),
          ),
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
                SizedBox(height: 5),
                Text(
                  'Execute as 3 tarefas MIT do dia, organize pela Matriz de Eisenhower e acompanhe as 10 áreas da sua vida.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.55,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
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
        style: TextStyle(
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

    return GlassCard(
      opacity: 0.06,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(18),
      tintColor: AppTheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('💭', style: TextStyle(fontSize: 14)),
              ),
              SizedBox(width: 10),
              Text(
                'Reflexão do Dia',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            '"${quote.text}"',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '— ${quote.author}',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── MIT Block ─────────────────────────────────────────────────────────────────

class _MITBlock extends StatelessWidget {
  final TasksProvider tasks;
  _MITBlock({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final mits = tasks.activeMITs;

    return Container(
      padding: EdgeInsets.all(16),
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
                  Text('⭐', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarefas MIT do Dia',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Most Important Tasks · ${mits.length}/3',
                        style: TextStyle(
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
          SizedBox(height: 12),
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
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text('🎯', style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(
            'Defina suas 3 tarefas MIT',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 4),
          Text(
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
  _MITTile({required this.task});

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
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
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
                style: TextStyle(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(area.icon, style: TextStyle(fontSize: 10)),
                    SizedBox(width: 3),
                    Text(
                      area.name,
                      style: TextStyle(
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
                    value: task.progressPercent / 100,
                    strokeWidth: 3,
                    backgroundColor: AppTheme.divider,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.accent),
                  ),
                  Center(
                    child: Text(
                      '${task.progressPercent}%',
                      style: TextStyle(
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
  _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: streak > 0
            ? Color(0xFFFF6348).withOpacity(0.15)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: streak > 0
              ? Color(0xFFFF6348).withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: 14)),
          SizedBox(width: 4),
          Text(
            '$streak dias',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: streak > 0
                  ? Color(0xFFFF6348)
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
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
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
                    style: TextStyle(
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

  _LifeWheelSection({required this.areas, required this.balance});

  @override
  Widget build(BuildContext context) {
    final scores = areas.map((a) => (a.currentScore as double)).toList();
    final labels = areas.map((a) => a.name as String).toList();
    final icons = areas.map((a) => a.icon as String).toList();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
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
                  style: TextStyle(
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
  _TodayActivities({required this.acts});

  @override
  Widget build(BuildContext context) {
    final todayActs = acts.todayActivities;
    if (todayActs.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atividades de Hoje',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        ...todayActs.take(3).map((a) {
          final areaConfig = kAreas.firstWhere(
            (c) => c.id == a.areaId,
            orElse: () => kAreas.first,
          );
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(areaConfig.icon, style: TextStyle(fontSize: 20)),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${a.durationMinutes} min • ${a.difficulty}',
                        style: TextStyle(
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
                    style: TextStyle(
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
  _AreasGrid({required this.areas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
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