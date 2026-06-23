import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/learning_progress.dart';
import '../../providers/learning_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';

class LearningTrackerScreen extends StatelessWidget {
  const LearningTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LearningProvider>();

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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(lp: lp),
              const SizedBox(height: 16),
              _PlatformGrid(lp: lp),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final LearningProvider lp;
  const _SummaryRow({required this.lp});

  @override
  Widget build(BuildContext context) {
    final configured = [
      lp.courses.isNotEmpty,
      lp.duolingo.username.isNotEmpty,
      lp.chessUsername.isNotEmpty,
      lp.goodreads.username.isNotEmpty || lp.goodreads.booksReadYear > 0,
      lp.notebookLM.notebooksCount > 0,
      lp.mecLivros.booksRead > 0 || lp.mecLivros.booksReading > 0,
      lp.mecIdiomas.activeCourse.isNotEmpty,
    ].where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A4FCC), Color(0xFF7C6FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$configured de 7 plataformas ativas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lp.completedCourses} cursos concluídos · '
                  '${(lp.overallProgress * 100).toStringAsFixed(0)}% DataCamp',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Text('🎓', style: TextStyle(fontSize: 32)),
        ],
      ),
    );
  }
}

// ── Platform grid ─────────────────────────────────────────────────────────────

class _PlatformGrid extends StatelessWidget {
  final LearningProvider lp;
  const _PlatformGrid({required this.lp});

  @override
  Widget build(BuildContext context) {
    final platforms = [
      _PlatformSpec(
        emoji: '📊',
        name: 'DataCamp',
        color: const Color(0xFF05C3DD),
        metric: lp.courses.isEmpty
            ? 'Nenhum curso'
            : '${lp.completedCourses}/${lp.courses.length} concluídos',
        active: lp.courses.isNotEmpty,
        onTap: () => _openSheet(context, const _DataCampSheet()),
      ),
      _PlatformSpec(
        emoji: '🦜',
        name: 'Duolingo',
        color: const Color(0xFF58CC02),
        metric: lp.duolingo.username.isEmpty
            ? 'Configurar'
            : 'Streak: ${lp.duolingo.streak} 🔥',
        active: lp.duolingo.username.isNotEmpty,
        onTap: () => _openSheet(context, const _DuolingoSheet()),
      ),
      _PlatformSpec(
        emoji: '♟️',
        name: 'Chess.com',
        color: const Color(0xFF769656),
        metric: lp.chessStats == null
            ? 'Configurar'
            : 'Puzzle: ${lp.chessStats!.puzzleRating ?? "—"}',
        active: lp.chessUsername.isNotEmpty,
        onTap: () => _openSheet(context, const _ChessSheet()),
      ),
      _PlatformSpec(
        emoji: '📖',
        name: 'Goodreads',
        color: const Color(0xFF372213),
        metric: lp.goodreads.booksReadYear == 0
            ? 'Configurar'
            : '${lp.goodreads.booksReadYear} livros lidos',
        active:
            lp.goodreads.booksReadYear > 0 || lp.goodreads.username.isNotEmpty,
        onTap: () => _openSheet(context, const _GoodreadsSheet()),
      ),
      _PlatformSpec(
        emoji: '🧠',
        name: 'NotebookLM',
        color: const Color(0xFF4285F4),
        metric: lp.notebookLM.notebooksCount == 0
            ? 'Configurar'
            : '${lp.notebookLM.notebooksCount} cadernos',
        active: lp.notebookLM.notebooksCount > 0,
        onTap: () => _openSheet(context, const _NotebookLMSheet()),
      ),
      _PlatformSpec(
        emoji: '📕',
        name: 'MEC Livros',
        color: const Color(0xFF1B4F72),
        metric: (lp.mecLivros.booksRead + lp.mecLivros.booksReading) == 0
            ? 'Configurar'
            : '${lp.mecLivros.booksRead} lidos · ${lp.mecLivros.booksReading} lendo',
        active: lp.mecLivros.booksRead > 0 || lp.mecLivros.booksReading > 0,
        onTap: () => _openSheet(context, const _MecLivrosSheet()),
      ),
      _PlatformSpec(
        emoji: '🌐',
        name: 'MEC Idiomas',
        color: const Color(0xFF117A65),
        metric: lp.mecIdiomas.activeCourse.isEmpty
            ? 'Configurar'
            : lp.mecIdiomas.activeCourse,
        active: lp.mecIdiomas.activeCourse.isNotEmpty,
        onTap: () => _openSheet(context, const _MecIdiomasSheet()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: platforms.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) => _PlatformCard(spec: platforms[i]),
    );
  }

  void _openSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<LearningProvider>(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    child: sheet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlatformSpec {
  final String emoji;
  final String name;
  final Color color;
  final String metric;
  final bool active;
  final VoidCallback onTap;

  const _PlatformSpec({
    required this.emoji,
    required this.name,
    required this.color,
    required this.metric,
    required this.active,
    required this.onTap,
  });
}

class _PlatformCard extends StatelessWidget {
  final _PlatformSpec spec;
  const _PlatformCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: spec.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: spec.active
                ? spec.color.withOpacity(0.4)
                : AppTheme.divider,
            width: spec.active ? 1.5 : 1,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(spec.emoji, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                if (spec.active)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: spec.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              spec.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              spec.metric,
              style: TextStyle(
                fontSize: 11,
                color: spec.active ? spec.color : AppTheme.textSecondary,
                fontWeight:
                    spec.active ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
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
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
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
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(url)),
            style: TextButton.styleFrom(foregroundColor: color),
            child: const Text('Abrir', style: TextStyle(fontSize: 12)),
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
            if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 16)),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
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
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  const _FormField(
      {required this.controller,
      required this.label,
      this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.divider)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary)),
        ),
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

// ══════════════════════════════════════════════════════════════════════════════
// DATACAMP SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _DataCampSheet extends StatelessWidget {
  const _DataCampSheet();

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LearningProvider>();
    final courses = lp.courses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlatformHeader(
          emoji: '📊',
          name: 'DataCamp',
          color: const Color(0xFF05C3DD),
          url: 'https://www.datacamp.com',
          subtitle: 'Tracking manual de cursos e capítulos',
        ),
        const SizedBox(height: 16),
        if (courses.isNotEmpty) ...[
          Row(
            children: [
              _StatCard(
                label: 'Em andamento',
                value: '${courses.where((c) => !c.isCompleted).length}',
                emoji: '📖',
              ),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Concluídos',
                  value: '${lp.completedCourses}',
                  emoji: '✅'),
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
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<LearningProvider>(),
                child: const _AddCourseDialog(),
              ),
            ),
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
        if (courses.isEmpty)
          _EmptyState(
            emoji: '📊',
            message:
                'Adicione os cursos que você está estudando no DataCamp.',
          )
        else
          ...courses.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DataCampCourseCard(course: c),
              )),
        const SizedBox(height: 20),
      ],
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
        color: AppTheme.background,
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
                child: Icon(Icons.close,
                    size: 16, color: AppTheme.textSecondary),
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
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Nome do Curso',
              labelStyle: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13),
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
            style:
                TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            underline: Container(height: 1, color: AppTheme.divider),
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
                child: Text('$_totalChapters',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
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
          onPressed:
              _titleCtrl.text.trim().isEmpty ? null : () => _save(context),
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
// DUOLINGO SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _DuolingoSheet extends StatefulWidget {
  const _DuolingoSheet();

  @override
  State<_DuolingoSheet> createState() => _DuolingoSheetState();
}

class _DuolingoSheetState extends State<_DuolingoSheet> {
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
    _editing = d.username.isEmpty;
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
    final d = context.watch<LearningProvider>().duolingo;

    return Column(
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

        if (!_editing && d.username.isNotEmpty) ...[
          Row(
            children: [
              _StatCard(
                  label: 'Streak', value: '${d.streak} 🔥', emoji: ''),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'XP Total', value: '${d.totalXP}', emoji: '⭐'),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Nível',
                  value: '${d.languageLevel}',
                  emoji: '🏅'),
            ],
          ),
          const SizedBox(height: 12),
          if (d.activeLanguage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
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
                      color:
                          const Color(0xFF58CC02).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                        child:
                            Text('🌍', style: TextStyle(fontSize: 20))),
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
                              fontSize: 12,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Atualizar dados', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF58CC02),
              side: const BorderSide(color: Color(0xFF58CC02)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ] else if (!_editing)
          _EmptyState(
            emoji: '🦜',
            message:
                'Configure seu perfil para acompanhar streak e XP.',
          ),

        if (_editing) ...[
          _FormField(controller: _usernameCtrl, label: 'Usuário Duolingo'),
          _FormField(
              controller: _streakCtrl,
              label: 'Streak (dias)',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _xpCtrl,
              label: 'XP Total',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _langCtrl, label: 'Idioma ativo (ex: Inglês)'),
          _FormField(
              controller: _levelCtrl,
              label: 'Nível no idioma',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _langXpCtrl,
              label: 'XP no idioma',
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          Row(
            children: [
              if (d.username.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: Text('Cancelar',
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58CC02),
                    foregroundColor: Colors.white),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  void _save(BuildContext context) {
    final progress = DuolingoProgress(
      username: _usernameCtrl.text.trim(),
      streak: int.tryParse(_streakCtrl.text) ?? 0,
      totalXP: int.tryParse(_xpCtrl.text) ?? 0,
      activeLanguage: _langCtrl.text.trim(),
      languageLevel: int.tryParse(_levelCtrl.text) ?? 1,
      languageXP: int.tryParse(_langXpCtrl.text) ?? 0,
    );
    context.read<LearningProvider>().saveDuolingo(progress);
    setState(() => _editing = false);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CHESS.COM SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _ChessSheet extends StatefulWidget {
  const _ChessSheet();

  @override
  State<_ChessSheet> createState() => _ChessSheetState();
}

class _ChessSheetState extends State<_ChessSheet> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlatformHeader(
          emoji: '♟️',
          name: 'Chess.com',
          color: const Color(0xFF769656),
          url: lp.chessUsername.isNotEmpty
              ? 'https://www.chess.com/member/${lp.chessUsername}'
              : 'https://www.chess.com',
          subtitle: 'Ratings via API pública (sem autenticação)',
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Username do Chess.com',
                  hintStyle: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: const Color(0xFF769656)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: lp.chessLoading
                  ? null
                  : () => lp.fetchChess(_ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF769656),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: lp.chessLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Buscar', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),

        if (lp.chessError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              lp.chessError!,
              style:
                  const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],

        const SizedBox(height: 16),

        if (lp.chessStats == null && !lp.chessLoading)
          _EmptyState(
            emoji: '♟️',
            message:
                'Informe seu username do Chess.com para carregar seus ratings automáticamente.',
          )
        else if (lp.chessStats != null)
          _ChessStatsGrid(stats: lp.chessStats!),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _ChessStatsGrid extends StatelessWidget {
  final ChessStats stats;
  const _ChessStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('♟️', 'Puzzle', stats.puzzleRating),
      ('⚡', 'Rápido', stats.rapidRating),
      ('🏃', 'Blitz', stats.blitzRating),
      ('💨', 'Bullet', stats.bulletRating),
      ('🧩', 'Rush', stats.puzzleRushBest),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: items
          .map((e) => _ChessStatCard(emoji: e.$1, label: e.$2, value: e.$3))
          .toList(),
    );
  }
}

class _ChessStatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final int? value;
  const _ChessStatCard(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value != null ? '$value' : '—',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: value != null
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
          ),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GOODREADS SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _GoodreadsSheet extends StatefulWidget {
  const _GoodreadsSheet();

  @override
  State<_GoodreadsSheet> createState() => _GoodreadsSheetState();
}

class _GoodreadsSheetState extends State<_GoodreadsSheet> {
  bool _editing = false;
  late TextEditingController _usernameCtrl;
  late TextEditingController _booksReadYearCtrl;
  late TextEditingController _booksReadingCtrl;
  late TextEditingController _booksWantCtrl;
  late TextEditingController _pagesCtrl;
  late TextEditingController _currentBookCtrl;

  @override
  void initState() {
    super.initState();
    final g = context.read<LearningProvider>().goodreads;
    _usernameCtrl = TextEditingController(text: g.username);
    _booksReadYearCtrl =
        TextEditingController(text: '${g.booksReadYear}');
    _booksReadingCtrl =
        TextEditingController(text: '${g.booksReading}');
    _booksWantCtrl =
        TextEditingController(text: '${g.booksWantToRead}');
    _pagesCtrl = TextEditingController(text: '${g.pagesYear}');
    _currentBookCtrl =
        TextEditingController(text: g.currentBook);
    _editing = g.username.isEmpty && g.booksReadYear == 0;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _booksReadYearCtrl.dispose();
    _booksReadingCtrl.dispose();
    _booksWantCtrl.dispose();
    _pagesCtrl.dispose();
    _currentBookCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<LearningProvider>().goodreads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlatformHeader(
          emoji: '📖',
          name: 'Goodreads',
          color: const Color(0xFF372213),
          url: g.username.isNotEmpty
              ? 'https://www.goodreads.com/user/show/${g.username}'
              : 'https://www.goodreads.com',
          subtitle: 'Tracking manual de leitura',
        ),
        const SizedBox(height: 16),

        if (!_editing && g.booksReadYear > 0) ...[
          Row(
            children: [
              _StatCard(
                  label: 'Lidos (ano)',
                  value: '${g.booksReadYear}',
                  emoji: '✅'),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Lendo',
                  value: '${g.booksReading}',
                  emoji: '📖'),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Quero ler',
                  value: '${g.booksWantToRead}',
                  emoji: '🔖'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                  label: 'Páginas (ano)',
                  value: '${g.pagesYear}',
                  emoji: '📄'),
            ],
          ),
          if (g.currentBook.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF372213).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('📚', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lendo agora',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                        Text(g.currentBook,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Atualizar', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF372213),
              side: const BorderSide(color: Color(0xFF372213)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ] else if (!_editing)
          _EmptyState(
            emoji: '📖',
            message:
                'Registre seus livros lidos, em leitura e quanto quer ler.',
          ),

        if (_editing) ...[
          _FormField(
              controller: _usernameCtrl,
              label: 'Username Goodreads (opcional)'),
          _FormField(
              controller: _booksReadYearCtrl,
              label: 'Livros lidos este ano',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _booksReadingCtrl,
              label: 'Livros lendo agora',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _booksWantCtrl,
              label: 'Quero ler (fila)',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _pagesCtrl,
              label: 'Páginas lidas este ano',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _currentBookCtrl,
              label: 'Livro atual (título)'),
          const SizedBox(height: 8),
          Row(
            children: [
              if (g.booksReadYear > 0)
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: Text('Cancelar',
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF372213),
                    foregroundColor: Colors.white),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  void _save(BuildContext context) {
    final progress = GoodreadsProgress(
      username: _usernameCtrl.text.trim(),
      booksReadYear: int.tryParse(_booksReadYearCtrl.text) ?? 0,
      booksReading: int.tryParse(_booksReadingCtrl.text) ?? 0,
      booksWantToRead: int.tryParse(_booksWantCtrl.text) ?? 0,
      pagesYear: int.tryParse(_pagesCtrl.text) ?? 0,
      currentBook: _currentBookCtrl.text.trim(),
    );
    context.read<LearningProvider>().saveGoodreads(progress);
    setState(() => _editing = false);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// NOTEBOOKLM SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _NotebookLMSheet extends StatefulWidget {
  const _NotebookLMSheet();

  @override
  State<_NotebookLMSheet> createState() => _NotebookLMSheetState();
}

class _NotebookLMSheetState extends State<_NotebookLMSheet> {
  bool _editing = false;
  late TextEditingController _notebooksCtrl;
  late TextEditingController _sourcesCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _topicCtrl;

  @override
  void initState() {
    super.initState();
    final n = context.read<LearningProvider>().notebookLM;
    _notebooksCtrl =
        TextEditingController(text: '${n.notebooksCount}');
    _sourcesCtrl = TextEditingController(text: '${n.sourcesCount}');
    _notesCtrl = TextEditingController(text: '${n.notesCount}');
    _topicCtrl = TextEditingController(text: n.latestTopic);
    _editing = n.notebooksCount == 0;
  }

  @override
  void dispose() {
    _notebooksCtrl.dispose();
    _sourcesCtrl.dispose();
    _notesCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<LearningProvider>().notebookLM;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlatformHeader(
          emoji: '🧠',
          name: 'NotebookLM',
          color: const Color(0xFF4285F4),
          url: 'https://notebooklm.google.com',
          subtitle: 'Tracking manual de cadernos e fontes',
        ),
        const SizedBox(height: 16),

        if (!_editing && n.notebooksCount > 0) ...[
          Row(
            children: [
              _StatCard(
                  label: 'Cadernos',
                  value: '${n.notebooksCount}',
                  emoji: '📓'),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Fontes',
                  value: '${n.sourcesCount}',
                  emoji: '🔗'),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Notas', value: '${n.notesCount}', emoji: '📝'),
            ],
          ),
          if (n.latestTopic.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        const Color(0xFF4285F4).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Último tema',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                        Text(n.latestTopic,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Atualizar', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4285F4),
              side: const BorderSide(color: Color(0xFF4285F4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ] else if (!_editing)
          _EmptyState(
            emoji: '🧠',
            message:
                'Registre quantos cadernos, fontes e notas você tem no NotebookLM.',
          ),

        if (_editing) ...[
          _FormField(
              controller: _notebooksCtrl,
              label: 'Número de cadernos',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _sourcesCtrl,
              label: 'Fontes adicionadas',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _notesCtrl,
              label: 'Notas criadas',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _topicCtrl, label: 'Último tema estudado'),
          const SizedBox(height: 8),
          Row(
            children: [
              if (n.notebooksCount > 0)
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: Text('Cancelar',
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  void _save(BuildContext context) {
    final progress = NotebookLMProgress(
      notebooksCount: int.tryParse(_notebooksCtrl.text) ?? 0,
      sourcesCount: int.tryParse(_sourcesCtrl.text) ?? 0,
      notesCount: int.tryParse(_notesCtrl.text) ?? 0,
      latestTopic: _topicCtrl.text.trim(),
    );
    context.read<LearningProvider>().saveNotebookLM(progress);
    setState(() => _editing = false);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MEC LIVROS SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _MecLivrosSheet extends StatefulWidget {
  const _MecLivrosSheet();

  @override
  State<_MecLivrosSheet> createState() => _MecLivrosSheetState();
}

class _MecLivrosSheetState extends State<_MecLivrosSheet> {
  bool _editing = false;
  late TextEditingController _booksReadCtrl;
  late TextEditingController _booksReadingCtrl;
  late TextEditingController _currentBookCtrl;
  late TextEditingController _genreCtrl;

  @override
  void initState() {
    super.initState();
    final m = context.read<LearningProvider>().mecLivros;
    _booksReadCtrl = TextEditingController(text: '${m.booksRead}');
    _booksReadingCtrl =
        TextEditingController(text: '${m.booksReading}');
    _currentBookCtrl = TextEditingController(text: m.currentBook);
    _genreCtrl = TextEditingController(text: m.favoriteGenre);
    _editing = m.booksRead == 0 && m.booksReading == 0;
  }

  @override
  void dispose() {
    _booksReadCtrl.dispose();
    _booksReadingCtrl.dispose();
    _currentBookCtrl.dispose();
    _genreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<LearningProvider>().mecLivros;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlatformHeader(
          emoji: '📕',
          name: 'MEC Livros',
          color: const Color(0xFF1B4F72),
          url: 'https://livros.mec.gov.br',
          subtitle: 'Acervo digital do Ministério da Educação',
        ),
        const SizedBox(height: 16),

        if (!_editing && (m.booksRead > 0 || m.booksReading > 0)) ...[
          Row(
            children: [
              _StatCard(
                  label: 'Lidos', value: '${m.booksRead}', emoji: '✅'),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Lendo',
                  value: '${m.booksReading}',
                  emoji: '📖'),
            ],
          ),
          if (m.currentBook.isNotEmpty || m.favoriteGenre.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        const Color(0xFF1B4F72).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m.currentBook.isNotEmpty) ...[
                    Text('Lendo agora',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                    Text(m.currentBook,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                  ],
                  if (m.favoriteGenre.isNotEmpty)
                    Text('Gênero favorito: ${m.favoriteGenre}',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Atualizar', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B4F72),
              side: const BorderSide(color: Color(0xFF1B4F72)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ] else if (!_editing)
          _EmptyState(
            emoji: '📕',
            message:
                'Acompanhe os livros que você leu ou está lendo pelo acervo do MEC.',
          ),

        if (_editing) ...[
          _FormField(
              controller: _booksReadCtrl,
              label: 'Livros lidos',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _booksReadingCtrl,
              label: 'Livros lendo agora',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _currentBookCtrl, label: 'Título do livro atual'),
          _FormField(
              controller: _genreCtrl, label: 'Gênero favorito'),
          const SizedBox(height: 8),
          Row(
            children: [
              if (m.booksRead > 0 || m.booksReading > 0)
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: Text('Cancelar',
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F72),
                    foregroundColor: Colors.white),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  void _save(BuildContext context) {
    final progress = MecLivrosProgress(
      booksRead: int.tryParse(_booksReadCtrl.text) ?? 0,
      booksReading: int.tryParse(_booksReadingCtrl.text) ?? 0,
      currentBook: _currentBookCtrl.text.trim(),
      favoriteGenre: _genreCtrl.text.trim(),
    );
    context.read<LearningProvider>().saveMecLivros(progress);
    setState(() => _editing = false);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MEC IDIOMAS SHEET
// ══════════════════════════════════════════════════════════════════════════════

class _MecIdiomasSheet extends StatefulWidget {
  const _MecIdiomasSheet();

  @override
  State<_MecIdiomasSheet> createState() => _MecIdiomasSheetState();
}

class _MecIdiomasSheetState extends State<_MecIdiomasSheet> {
  bool _editing = false;
  late TextEditingController _courseCtrl;
  late TextEditingController _languageCtrl;
  late TextEditingController _lessonsCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _streakCtrl;

  @override
  void initState() {
    super.initState();
    final m = context.read<LearningProvider>().mecIdiomas;
    _courseCtrl = TextEditingController(text: m.activeCourse);
    _languageCtrl = TextEditingController(text: m.activeLanguage);
    _lessonsCtrl =
        TextEditingController(text: '${m.lessonsCompleted}');
    _totalCtrl = TextEditingController(text: '${m.totalLessons}');
    _streakCtrl = TextEditingController(text: '${m.streak}');
    _editing = m.activeCourse.isEmpty;
  }

  @override
  void dispose() {
    _courseCtrl.dispose();
    _languageCtrl.dispose();
    _lessonsCtrl.dispose();
    _totalCtrl.dispose();
    _streakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.watch<LearningProvider>().mecIdiomas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PlatformHeader(
          emoji: '🌐',
          name: 'MEC Idiomas',
          color: const Color(0xFF117A65),
          url: 'https://idiomas.mec.gov.br',
          subtitle: 'Cursos de idiomas do Ministério da Educação',
        ),
        const SizedBox(height: 16),

        if (!_editing && m.activeCourse.isNotEmpty) ...[
          Row(
            children: [
              _StatCard(
                  label: 'Lições',
                  value: '${m.lessonsCompleted}/${m.totalLessons}',
                  emoji: '📝'),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Progresso',
                  value:
                      '${(m.progress * 100).toStringAsFixed(0)}%',
                  emoji: '📊'),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Streak',
                  value: '${m.streak} 🔥',
                  emoji: ''),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: m.progress,
            backgroundColor: AppTheme.divider,
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF117A65)),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 6),
          Text(
            m.activeCourse +
                (m.activeLanguage.isNotEmpty
                    ? ' · ${m.activeLanguage}'
                    : ''),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Atualizar', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF117A65),
              side: const BorderSide(color: Color(0xFF117A65)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ] else if (!_editing)
          _EmptyState(
            emoji: '🌐',
            message:
                'Registre o curso de idioma que você está fazendo pelo MEC Idiomas.',
          ),

        if (_editing) ...[
          _FormField(
              controller: _courseCtrl,
              label: 'Nome do curso (ex: Inglês B1)'),
          _FormField(
              controller: _languageCtrl,
              label: 'Idioma (ex: Inglês, Espanhol)'),
          _FormField(
              controller: _lessonsCtrl,
              label: 'Lições concluídas',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _totalCtrl,
              label: 'Total de lições',
              keyboardType: TextInputType.number),
          _FormField(
              controller: _streakCtrl,
              label: 'Streak (dias)',
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          Row(
            children: [
              if (m.activeCourse.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: Text('Cancelar',
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF117A65),
                    foregroundColor: Colors.white),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  void _save(BuildContext context) {
    final progress = MecIdiomasProgress(
      activeCourse: _courseCtrl.text.trim(),
      activeLanguage: _languageCtrl.text.trim(),
      lessonsCompleted: int.tryParse(_lessonsCtrl.text) ?? 0,
      totalLessons: int.tryParse(_totalCtrl.text) ?? 0,
      streak: int.tryParse(_streakCtrl.text) ?? 0,
    );
    context.read<LearningProvider>().saveMecIdiomas(progress);
    setState(() => _editing = false);
  }
}
