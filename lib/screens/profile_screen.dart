import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/activities_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/calendar_provider.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';
import '../l10n/app_l10n.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/app_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final achievements = context.watch<UserProvider>().achievements;
    final acts = context.watch<ActivitiesProvider>();
    final l10n = context.l10n;

    if (user == null) return const SizedBox();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.profile),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _showSettings(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withOpacity(0.8),
                      AppTheme.primary.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${l10n.level} ${user.level} • ${user.tier}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 22)),
                            Text(
                              '${user.currentStreak}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              l10n.days,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    XpProgressBar(totalXP: user.totalXP),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Stats row
              Row(
                children: [
                  _StatCard(label: l10n.activities, value: '${acts.totalActivities}', emoji: '📝'),
                  SizedBox(width: 10),
                  _StatCard(label: l10n.totalXP, value: '${user.totalXP}', emoji: '⭐'),
                  SizedBox(width: 10),
                  _StatCard(label: l10n.record, value: '${user.longestStreak}d', emoji: '🏆'),
                ],
              ),
              SizedBox(height: 20),
              // Achievements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.achievements,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, i) =>
                    _AchievementCard(achievement: achievements[i]),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SettingsSheet(),
    );
  }
}

// ── Settings bottom sheet ──────────────────────────────────────────────────────

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final up = context.watch<UserProvider>();
    final calendar = context.watch<CalendarProvider>();
    final l10n = context.l10n;
    final isDark = settings.themeMode == ThemeMode.dark;

    final providerLabel = switch (up.authProvider) {
      'google'   => '🔵 Google',
      'github'   => '🐙 GitHub',
      'linkedin' => '🔷 LinkedIn',
      'facebook' => '📘 Facebook',
      'demo'     => '🎮 Modo Demo',
      _          => '—',
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.settings_outlined,
                          color: Colors.white, size: 18),
                    ),
                    SizedBox(width: 12),
                    Text(
                      l10n.settings,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: AppTheme.divider, height: 16),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ── Aparência ──────────────────────────────────────────
                    _SectionHeader(
                        icon: Icons.palette_outlined, title: l10n.appearance),
                    SizedBox(height: 10),

                    // Tema (Dark / Light)
                    Text(l10n.theme,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.3)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _ThemeChip(
                          icon: Icons.dark_mode_outlined,
                          label: l10n.themeDark,
                          selected: isDark,
                          onTap: () =>
                              settings.setThemeMode(ThemeMode.dark),
                        ),
                        SizedBox(width: 10),
                        _ThemeChip(
                          icon: Icons.light_mode_outlined,
                          label: l10n.themeLight,
                          selected: !isDark,
                          onTap: () =>
                              settings.setThemeMode(ThemeMode.light),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Idioma
                    Text(l10n.language,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.3)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        _LangChip(
                          flag: '🇧🇷',
                          label: 'Português',
                          selected: settings.locale == 'pt',
                          onTap: () => settings.setLocale('pt'),
                        ),
                        SizedBox(width: 10),
                        _LangChip(
                          flag: '🇺🇸',
                          label: 'English',
                          selected: settings.locale == 'en',
                          onTap: () => settings.setLocale('en'),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // ── Google Agenda ──────────────────────────────────────
                    if (calendar.isGoogleUser) ...[
                      _SectionHeader(
                          icon: Icons.calendar_month_outlined,
                          title: 'Google Agenda'),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  calendar.isAuthorized
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  size: 15,
                                  color: calendar.isAuthorized
                                      ? Color(0xFF34D399)
                                      : AppTheme.textSecondary,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  calendar.isAuthorized
                                      ? 'Sincronização ativa'
                                      : 'Aguardando autorização',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: calendar.isAuthorized
                                        ? Color(0xFF34D399)
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (calendar.isAuthorized) ...[
                              SizedBox(height: 14),
                              Text(
                                'Janela de sincronização',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Eventos dos próximos N dias aparecem como tarefas planejadas.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: CalendarProvider.syncDayOptions
                                    .map((days) {
                                  final selected =
                                      calendar.syncDays == days;
                                  return GestureDetector(
                                    onTap: () =>
                                        calendar.setSyncDays(days),
                                    child: AnimatedContainer(
                                      duration:
                                          Duration(milliseconds: 180),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppTheme.primary
                                                .withOpacity(0.15)
                                            : AppTheme.surface,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: selected
                                              ? AppTheme.primary
                                              : AppTheme.divider,
                                          width: selected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${days}d',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: selected
                                              ? AppTheme.primary
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                    ],

                    // ── Conta ──────────────────────────────────────────────
                    _SectionHeader(
                        icon: Icons.manage_accounts_outlined,
                        title: l10n.account),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.link,
                                  size: 16, color: AppTheme.textSecondary),
                              SizedBox(width: 8),
                              Text(
                                '${l10n.connectedVia} $providerLabel',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  label: l10n.signOut,
                                  icon: Icons.logout,
                                  color: AppTheme.accent,
                                  onTap: () async {
                                    Navigator.pop(context);
                                    await context
                                        .read<UserProvider>()
                                        .signOut();
                                  },
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: _ActionButton(
                                  label: l10n.resetData,
                                  icon: Icons.delete_forever_outlined,
                                  color: Colors.red,
                                  onTap: () =>
                                      _confirmReset(context, l10n),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // ── Info do app ────────────────────────────────────────
                    _SectionHeader(
                        icon: Icons.info_outline, title: l10n.appInfoSection),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text('⚖️',
                                  style: TextStyle(fontSize: 22)),
                            ),
                          ),
                          SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kAppName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'v$kAppVersion',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context, L10n l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(l10n.resetTitle,
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(l10n.resetBody,
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l10n.resetData,
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.pop(context);
      await context.read<UserProvider>().resetAll();
    }
  }
}

// ── Componentes ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(width: 8),
        Expanded(child: Divider(color: AppTheme.divider)),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  _ThemeChip(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary),
              SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  _LangChip(
      {required this.flag,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: TextStyle(fontSize: 24)),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  _StatCard({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 22)),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Achievement card ──────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final dynamic achievement;
  _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked as bool;
    return Container(
      decoration: BoxDecoration(
        color: unlocked
            ? AppTheme.primary.withOpacity(0.10)
            : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? AppTheme.primary.withOpacity(0.4)
              : AppTheme.divider,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.icon as String,
            style: TextStyle(
              fontSize: 28,
              color: unlocked ? null : AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              achievement.name as String,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: unlocked ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unlocked)
            Text(
              '✓',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}