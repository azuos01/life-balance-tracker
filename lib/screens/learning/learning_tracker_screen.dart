import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/learning_progress.dart';
import '../../providers/learning_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';

class LearningTrackerScreen extends StatefulWidget {
  const LearningTrackerScreen({super.key});

  @override
  State<LearningTrackerScreen> createState() => _LearningTrackerScreenState();
}

class _LearningTrackerScreenState extends State<LearningTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Row(
            children: [
              Text('📚', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text('Aprendizado'),
            ],
          ),
          bottom: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(
                icon: Icon(Icons.data_usage_outlined, size: 15),
                text: 'DataCamp',
              ),
              Tab(
                icon: Icon(Icons.translate_outlined, size: 15),
                text: 'Duolingo',
              ),
              Tab(
                icon: Icon(Icons.sports_esports_outlined, size: 15),
                text: 'Chess.com',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: const [
            _DataCampTab(),
            _DuolingoTab(),
            _ChessTab(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DATACAMP TAB
// ══════════════════════════════════════════════════════════════════════════════

class _DataCampTab extends StatelessWidget {
  const _DataCampTab();

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LearningProvider>();
    final courses = lp.courses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          _PlatformHeader(
            emoji: '📊',
            name: 'DataCamp',
            color: const Color(0xFF05C3DD),
            url: 'https://www.datacamp.com',
            subtitle: 'Tracking manual de cursos e capítulos',
          ),
          const SizedBox(height: 16),

          // Stats
          if (courses.isNotEmpty) ...[
            Row(
              children: [
                _StatCard(
                  label: 'Em andamento',
                  value:
                      '${courses.where((c) => !c.isCompleted).length}',
                  emoji: '📖',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Concluídos',
                  value: '${lp.completedCourses}',
                  emoji: '✅',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Progresso',
                  value:
                      '${(lp.overallProgress * 100).toStringAsFixed(0)}%',
                  emoji: '📈',
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Add course button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddCourseDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Adicionar Curso'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF05C3DD),
                side: const BorderSide(color: Color(0xFF05C3DD)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Courses list
          if (courses.isEmpty)
            _EmptyState(
              emoji: '📊',
              message:
                  'Adicione os cursos que você está estudando no DataCamp para acompanhar seu progresso.',
            )
          else
            ...courses.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DataCampCourseCard(course: c),
                )),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddCourseDialog(),
    );
  }
}

class _DataCampCourseCard extends StatelessWidget {
  final DataCampCourse course;
  const _DataCampCourseCard({required this.course});

  static const _techColors = {
    'Python': Color(0xFF3776AB),
    'R': Color(0xFF276DC3),
    'SQL': Color(0xFFE38C00),
    'Machine Learning': Color(0xFF10B981),
    'Deep Learning': Color(0xFF6366F1),
    'Power BI': Color(0xFFF2C811),
    'Tableau': Color(0xFFE97627),
    'Excel': Color(0xFF217346),
    'Data Engineering': Color(0xFFEF4444),
    'Shell': Color(0xFF6B7280),
    'Outro': Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context) {
    final lp = context.read<LearningProvider>();
    final color = _techColors[course.technology] ?? AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: course.isCompleted
              ? const Color(0xFF10B981).withOpacity(0.4)
              : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  course.technology,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              if (course.isCompleted)
                const Text('✅', style: TextStyle(fontSize: 16))
              else
                Row(
                  children: [
                    _ChapterButton(
                      icon: Icons.remove,
                      onTap: course.completedChapters > 0
                          ? () => lp.updateProgress(
                              course.id, course.completedChapters - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${course.completedChapters}/${course.totalChapters}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    _ChapterButton(
                      icon: Icons.add,
                      onTap: course.completedChapters < course.totalChapters
                          ? () => lp.updateProgress(
                              course.id, course.completedChapters + 1)
                          : null,
                    ),
                  ],
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => lp.deleteCourse(course.id),
                child: Icon(Icons.close, size: 16,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: course.progress,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation(
              course.isCompleted ? const Color(0xFF10B981) : color,
            ),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 4),
          Text(
            course.isCompleted
                ? 'Concluído!'
                : '${(course.progress * 100).toStringAsFixed(0)}% — ${course.totalChapters - course.completedChapters} capítulo(s) restante(s)',
            style: TextStyle(
              fontSize: 11,
              color: course.isCompleted
                  ? const Color(0xFF10B981)
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _ChapterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.primary.withOpacity(0.12)
              : AppTheme.divider,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _AddCourseDialog extends StatefulWidget {
  const _AddCourseDialog();

  @override
  State<_AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<_AddCourseDialog> {
  final _titleCtrl = TextEditingController();
  String _technology = 'Python';
  int _totalChapters = 4;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text('Adicionar Curso',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Nome do Curso',
              labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.divider)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Tecnologia',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButton<String>(
            value: _technology,
            isExpanded: true,
            dropdownColor: AppTheme.surface,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            underline:
                Container(height: 1, color: AppTheme.divider),
            items: kDataCampTechnologies
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _technology = v!),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Capítulos:',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              _ChapterButton(
                icon: Icons.remove,
                onTap: _totalChapters > 1
                    ? () => setState(() => _totalChapters--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$_totalChapters',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
              _ChapterButton(
                icon: Icons.add,
                onTap: () => setState(() => _totalChapters++),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _titleCtrl.text.trim().isEmpty ? null : () => _save(context),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white),
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  void _save(BuildContext context) {
    final course = DataCampCourse(
      id: 'dc_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      technology: _technology,
      totalChapters: _totalChapters,
      completedChapters: 0,
    );
    context.read<LearningProvider>().addCourse(course);
    Navigator.pop(context);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DUOLINGO TAB
// ══════════════════════════════════════════════════════════════════════════════

class _DuolingoTab extends StatefulWidget {
  const _DuolingoTab();

  @override
  State<_DuolingoTab> createState() => _DuolingoTabState();
}

class _DuolingoTabState extends State<_DuolingoTab> {
  bool _editing = false;

  late TextEditingController _usernameCtrl;
  late TextEditingController _streakCtrl;
  late TextEditingController _xpCtrl;
  late TextEditingController _langCtrl;
  late TextEditingController _levelCtrl;
  late TextEditingController _langXpCtrl;

  @override
  void initState() {
    super.initState();
    final d = context.read<LearningProvider>().duolingo;
    _usernameCtrl = TextEditingController(text: d.username);
    _streakCtrl = TextEditingController(text: '${d.streak}');
    _xpCtrl = TextEditingController(text: '${d.totalXP}');
    _langCtrl = TextEditingController(text: d.activeLanguage);
    _levelCtrl = TextEditingController(text: '${d.languageLevel}');
    _langXpCtrl = TextEditingController(text: '${d.languageXP}');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _streakCtrl.dispose();
    _xpCtrl.dispose();
    _langCtrl.dispose();
    _levelCtrl.dispose();
    _langXpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LearningProvider>();
    final d = lp.duolingo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlatformHeader(
            emoji: '🦜',
            name: 'Duolingo',
            color: const Color(0xFF58CC02),
            url: d.username.isNotEmpty
                ? 'https://www.duolingo.com/profile/${d.username}'
                : 'https://www.duolingo.com',
            subtitle: 'Atualização manual de progresso',
          ),
          const SizedBox(height: 16),

          if (!_editing && d.username.isEmpty)
            _EmptyState(
              emoji: '🦜',
              message:
                  'Configure seu perfil do Duolingo para acompanhar streak, XP e idiomas.',
            )
          else if (!_editing) ...[
            // Stats display
            Row(
              children: [
                _StatCard(
                  label: 'Streak',
                  value: '${d.streak} 🔥',
                  emoji: '',
                ),
                const SizedBox(width: 10),
                _StatCard(label: 'XP Total', value: '${d.totalXP}', emoji: '⭐'),
                const SizedBox(width: 10),
                _StatCard(
                    label: 'Nível', value: '${d.languageLevel}', emoji: '🏅'),
              ],
            ),
            const SizedBox(height: 12),
            if (d.activeLanguage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF58CC02).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF58CC02).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child: Text('🌍', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.activeLanguage,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          Text(
                            'Nível ${d.languageLevel} · ${d.languageXP} XP',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 12),

          if (_editing)
            _DuolingoForm(
              usernameCtrl: _usernameCtrl,
              streakCtrl: _streakCtrl,
              xpCtrl: _xpCtrl,
              langCtrl: _langCtrl,
              levelCtrl: _levelCtrl,
              langXpCtrl: _langXpCtrl,
              onSave: () => _save(context),
              onCancel: () => setState(() => _editing = false),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                    d.username.isEmpty ? 'Configurar Perfil' : 'Editar Progresso'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF58CC02),
                  side: const BorderSide(color: Color(0xFF58CC02)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _save(BuildContext context) {
    final lp = context.read<LearningProvider>();
    lp.saveDuolingo(DuolingoProgress(
      username: _usernameCtrl.text.trim(),
      streak: int.tryParse(_streakCtrl.text) ?? 0,
      totalXP: int.tryParse(_xpCtrl.text) ?? 0,
      activeLanguage: _langCtrl.text.trim(),
      languageLevel: int.tryParse(_levelCtrl.text) ?? 1,
      languageXP: int.tryParse(_langXpCtrl.text) ?? 0,
    ));
    setState(() => _editing = false);
  }
}

class _DuolingoForm extends StatelessWidget {
  final TextEditingController usernameCtrl;
  final TextEditingController streakCtrl;
  final TextEditingController xpCtrl;
  final TextEditingController langCtrl;
  final TextEditingController levelCtrl;
  final TextEditingController langXpCtrl;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _DuolingoForm({
    required this.usernameCtrl,
    required this.streakCtrl,
    required this.xpCtrl,
    required this.langCtrl,
    required this.levelCtrl,
    required this.langXpCtrl,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormField(ctrl: usernameCtrl, label: 'Usuário Duolingo'),
          _FormField(ctrl: streakCtrl, label: 'Streak atual (dias)', numeric: true),
          _FormField(ctrl: xpCtrl, label: 'XP Total', numeric: true),
          _FormField(ctrl: langCtrl, label: 'Idioma ativo (ex: Inglês)'),
          _FormField(ctrl: levelCtrl, label: 'Nível no idioma', numeric: true),
          _FormField(ctrl: langXpCtrl, label: 'XP no idioma', numeric: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Salvar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CHESS.COM TAB
// ══════════════════════════════════════════════════════════════════════════════

class _ChessTab extends StatefulWidget {
  const _ChessTab();

  @override
  State<_ChessTab> createState() => _ChessTabState();
}

class _ChessTabState extends State<_ChessTab> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: context.read<LearningProvider>().chessUsername);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LearningProvider>();
    final stats = lp.chessStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlatformHeader(
            emoji: '♟️',
            name: 'Chess.com',
            color: const Color(0xFF81B64C),
            url: lp.chessUsername.isNotEmpty
                ? 'https://www.chess.com/member/${lp.chessUsername}'
                : 'https://www.chess.com',
            subtitle: 'Dados via API pública do Chess.com',
          ),
          const SizedBox(height: 16),

          // Username input
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Seu usuário no Chess.com',
                      hintStyle: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                      isDense: true,
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.person_outline,
                          size: 18, color: AppTheme.textSecondary),
                    ),
                    onSubmitted: (_) => _fetch(context),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      lp.chessLoading ? null : () => _fetch(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81B64C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: lp.chessLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Buscar',
                          style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),

          // Error
          if (lp.chessError != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(error: lp.chessError!),
          ],

          // Stats
          if (stats != null) ...[
            const SizedBox(height: 16),
            Text(
              'Atualizado em ${_formatTime(stats.fetchedAt)}',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            _ChessStatsGrid(stats: stats),
          ] else if (!lp.chessLoading && lp.chessError == null) ...[
            const SizedBox(height: 16),
            _EmptyState(
              emoji: '♟️',
              message:
                  'Digite seu usuário do Chess.com e clique em Buscar para ver suas estatísticas.',
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _fetch(BuildContext context) {
    if (_ctrl.text.trim().isEmpty) return;
    context.read<LearningProvider>().fetchChess(_ctrl.text);
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} às $h:$m';
  }
}

class _ChessStatsGrid extends StatelessWidget {
  final ChessStats stats;
  const _ChessStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (stats.puzzleRating != null)
        _ChessStatItem(
            emoji: '⚡',
            label: 'Puzzles',
            value: '${stats.puzzleRating}',
            color: const Color(0xFFF59E0B)),
      if (stats.rapidRating != null)
        _ChessStatItem(
            emoji: '⏱️',
            label: 'Rapid',
            value: '${stats.rapidRating}',
            color: const Color(0xFF10B981)),
      if (stats.blitzRating != null)
        _ChessStatItem(
            emoji: '⚡',
            label: 'Blitz',
            value: '${stats.blitzRating}',
            color: const Color(0xFF6366F1)),
      if (stats.bulletRating != null)
        _ChessStatItem(
            emoji: '🔫',
            label: 'Bullet',
            value: '${stats.bulletRating}',
            color: const Color(0xFFEF4444)),
      if (stats.puzzleRushBest != null)
        _ChessStatItem(
            emoji: '🏃',
            label: 'Puzzle Rush',
            value: '${stats.puzzleRushBest}',
            color: const Color(0xFF81B64C)),
    ];

    if (items.isEmpty) {
      return Text(
        'Nenhuma estatística encontrada para este usuário.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((item) => SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: _ChessStatCard(item: item),
              ))
          .toList(),
    );
  }
}

class _ChessStatItem {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  const _ChessStatItem({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _ChessStatCard extends StatelessWidget {
  final _ChessStatItem item;
  const _ChessStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: item.color,
                  ),
                ),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
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

// ══════════════════════════════════════════════════════════════════════════════
// SHARED COMPONENTS
// ══════════════════════════════════════════════════════════════════════════════

class _PlatformHeader extends StatelessWidget {
  final String emoji;
  final String name;
  final Color color;
  final String url;
  final String subtitle;

  const _PlatformHeader({
    required this.emoji,
    required this.name,
    required this.color,
    required this.url,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) launchUrl(uri);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.open_in_new,
                      size: 14, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 4),
                  Text(
                    'Abrir',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  const _StatCard(
      {required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            if (emoji.isNotEmpty)
              Text(emoji, style: const TextStyle(fontSize: 18)),
            if (emoji.isNotEmpty) const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  const _EmptyState({required this.emoji, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style:
                  TextStyle(fontSize: 12, color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool numeric;
  const _FormField(
      {required this.ctrl, required this.label, this.numeric = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          isDense: true,
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.divider)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary)),
        ),
      ),
    );
  }
}
