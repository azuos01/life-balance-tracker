import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/task_suggestion.dart';
import '../../providers/ai_agent_provider.dart';
import '../../providers/areas_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class AiAgentScreen extends StatelessWidget {
  const AiAgentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiAgentProvider>();
    final settings = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(ai: ai),
          const SizedBox(height: 16),
          if (!settings.hasOpenAIKey)
            _NoKeyCard(context: context)
          else if (ai.isLoading)
            const _LoadingCard()
          else if (ai.error != null)
            _ErrorCard(error: ai.error!)
          else if (!ai.hasSuggestions)
            _EmptyCard(settings: settings, ai: ai)
          else
            _SuggestionsList(ai: ai, settings: settings),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Cabeçalho ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AiAgentProvider ai;
  const _Header({required this.ai});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final tp = context.read<TasksProvider>();
    final areas = context.read<AreasProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.85),
            AppTheme.primary.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assistente IA',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Sugestões personalizadas de tarefas',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ai.lastGenerated != null) ...[
            const SizedBox(height: 8),
            Text(
              'Gerado em ${_formatTime(ai.lastGenerated!)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (ai.isLoading || !settings.hasOpenAIKey)
                  ? null
                  : () => _generate(context, settings, tp, areas),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(
                ai.hasSuggestions ? 'Regenerar Sugestões' : 'Gerar Sugestões',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                disabledBackgroundColor: Colors.white.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _generate(
    BuildContext context,
    SettingsProvider settings,
    TasksProvider tp,
    AreasProvider areas,
  ) {
    final scores = {
      for (final a in areas.areas) a.id: a.currentScore.toDouble(),
    };
    context.read<AiAgentProvider>().generate(
          apiKey: settings.openAIKey!,
          currentTasks: tp.tasks.toList(),
          areaScores: scores,
        );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} às $h:$m';
  }
}

// ── Cards de estado ───────────────────────────────────────────────────────────

class _NoKeyCard extends StatelessWidget {
  final BuildContext context;
  const _NoKeyCard({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          const Text('🔑', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            'Configure sua chave OpenAI',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acesse Perfil → Configurações → Inteligência Artificial e adicione sua chave de API da OpenAI para usar o assistente.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Obtenha em platform.openai.com/api-keys',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.primary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
          const SizedBox(height: 16),
          Text(
            'Analisando suas tarefas e áreas de vida...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Erro ao gerar sugestões',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
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

class _EmptyCard extends StatelessWidget {
  final SettingsProvider settings;
  final AiAgentProvider ai;
  const _EmptyCard({required this.settings, required this.ai});

  @override
  Widget build(BuildContext context) {
    final tp = context.read<TasksProvider>();
    final areas = context.read<AreasProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Pronto para otimizar sua produtividade?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'O assistente analisará suas ${tp.tasks.length} tarefas e os scores das ${areas.areas.length} áreas de vida para sugerir as próximas ações mais impactantes.',
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

// ── Lista de sugestões ────────────────────────────────────────────────────────

class _SuggestionsList extends StatelessWidget {
  final AiAgentProvider ai;
  final SettingsProvider settings;
  const _SuggestionsList({required this.ai, required this.settings});

  @override
  Widget build(BuildContext context) {
    final list = ai.suggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${list.length} sugestões geradas',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ai.clear(),
              child: Text(
                'Limpar',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...list.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SuggestionCard(suggestion: s),
            )),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final TaskSuggestion suggestion;
  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final ai = context.read<AiAgentProvider>();
    final tp = context.read<TasksProvider>();
    final s = suggestion;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da área + quadrante
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 0),
            child: Row(
              children: [
                _AreaBadge(areaId: s.areaId),
                const SizedBox(width: 8),
                _QBadge(q: s.eisenhowerQ, label: s.eisenhowerLabel),
                if (s.isMIT) ...[
                  const SizedBox(width: 6),
                  _MITBadge(),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => ai.dismiss(s.id),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              s.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // Descrição
          if (s.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Text(
                s.description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),

          // Reasoning
          if (s.reasoning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 13, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.reasoning,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Ação
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _createTask(context, tp, s),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Criar Tarefa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createTask(
      BuildContext context, TasksProvider tp, TaskSuggestion s) {
    final uid = context.read<UserProvider>().user?.id ?? 'local';

    final task = TaskModel(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      title: s.title,
      description: s.description,
      areaId: s.areaId,
      eisenhowerQ: s.eisenhowerQ,
      isMIT: s.isMIT,
      createdAt: DateTime.now(),
    );

    tp.addTask(task);
    context.read<AiAgentProvider>().dismiss(s.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tarefa criada com sucesso!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class _AreaBadge extends StatelessWidget {
  final String areaId;
  const _AreaBadge({required this.areaId});

  static const _icons = {
    'health_physical': '💪',
    'health_mental': '🧠',
    'career': '🚀',
    'finances': '💰',
    'relationships': '❤️',
    'family': '👨‍👩‍👧',
    'intellectual': '📚',
    'spirituality': '🌟',
    'leisure': '🎨',
    'contribution': '🌍',
  };

  static const _names = {
    'health_physical': 'Saúde Física',
    'health_mental': 'Saúde Mental',
    'career': 'Carreira',
    'finances': 'Finanças',
    'relationships': 'Relacionamentos',
    'family': 'Família',
    'intellectual': 'Intelecto',
    'spirituality': 'Espiritualidade',
    'leisure': 'Lazer',
    'contribution': 'Contribuição',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[areaId] ?? '📌';
    final name = _names[areaId] ?? areaId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QBadge extends StatelessWidget {
  final int q;
  final String label;
  const _QBadge({required this.q, required this.label});

  static const _colors = {
    1: Color(0xFFEF4444),
    2: Color(0xFF10B981),
    3: Color(0xFFF59E0B),
    4: Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[q] ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        'Q$q · $label',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MITBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35)),
      ),
      child: const Text(
        'MIT',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }
}
