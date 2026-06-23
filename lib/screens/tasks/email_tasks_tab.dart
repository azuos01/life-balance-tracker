import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../models/email_model.dart';
import '../../models/task_model.dart';
import '../../providers/gmail_tasks_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/gmail_service.dart';
import '../../theme/app_theme.dart';

class EmailTasksTab extends StatelessWidget {
  const EmailTasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final authProvider = context.watch<UserProvider>().authProvider;
    final settings = context.watch<SettingsProvider>();
    final gtp = context.watch<GmailTasksProvider>();

    // Não logado com Google
    if (user == null || authProvider != 'google') {
      return _CenteredMessage(
        emoji: '📧',
        title: 'Login com Google necessário',
        subtitle:
            'A análise de e-mails usa sua conta Google. Faça login com Google para continuar.',
        actionLabel: null,
        onAction: null,
      );
    }

    // Logado mas sem token Gmail
    final hasGmailToken = GmailService.instance.hasToken;
    if (!hasGmailToken) {
      return _CenteredMessage(
        emoji: '🔒',
        title: 'Autorize o acesso ao Gmail',
        subtitle:
            'Precisamos de permissão de leitura para analisar seus e-mails e gerar tarefas. Nenhum e-mail é armazenado.',
        actionLabel: 'Autorizar',
        onAction: () => _requestGmailAccess(context),
      );
    }

    // Sem chave OpenAI
    if (!settings.hasOpenAIKey) {
      return _CenteredMessage(
        emoji: '🤖',
        title: 'Chave OpenAI necessária',
        subtitle:
            'A análise usa OpenAI GPT-4o-mini. Configure sua chave API em Perfil → Inteligência Artificial.',
        actionLabel: null,
        onAction: null,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          _EmailHeader(gtp: gtp),
          const SizedBox(height: 16),

          // ── Config ────────────────────────────────────────────────────────
          _ConfigCard(gtp: gtp),
          const SizedBox(height: 16),

          // ── Botão analisar ────────────────────────────────────────────────
          _AnalyzeButton(
            gtp: gtp,
            apiKey: settings.openAIKey!,
          ),
          const SizedBox(height: 16),

          // ── Estado / resultados ───────────────────────────────────────────
          if (gtp.isLoading) _LoadingIndicator(gtp: gtp),
          if (gtp.error != null) _ErrorCard(gtp: gtp),
          if (!gtp.isLoading &&
              gtp.error == null &&
              gtp.status == GmailTasksStatus.done) ...[
            _EmailsSummary(emails: gtp.emails),
            const SizedBox(height: 12),
            _SuggestionsList(gtp: gtp, uid: user.id),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _requestGmailAccess(BuildContext context) async {
    final ok = await AuthService.instance.requestGmailAccess();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível autorizar o Gmail.'),
            backgroundColor: Colors.red),
      );
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _EmailHeader extends StatelessWidget {
  final GmailTasksProvider gtp;
  const _EmailHeader({required this.gtp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD44638), Color(0xFFE57368)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('📧', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Análise de E-mails',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  gtp.lastRun != null
                      ? 'Última análise: ${_formatTime(gtp.lastRun!)}'
                      : 'Gera tarefas a partir dos seus e-mails',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (gtp.suggestions.isNotEmpty || gtp.emails.isNotEmpty)
            IconButton(
              onPressed: gtp.clear,
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              tooltip: 'Limpar resultados',
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} às $h:$m';
  }
}

// ── Config Card ───────────────────────────────────────────────────────────────

class _ConfigCard extends StatelessWidget {
  final GmailTasksProvider gtp;
  const _ConfigCard({required this.gtp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Janela de tempo ──────────────────────────────────────────────
          _SectionLabel('⏱️ Janela de análise'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kEmailWindowOptions
                .map((opt) => _WindowChip(
                      option: opt,
                      selected: opt.days == gtp.config.windowDays,
                      onTap: () => gtp.saveConfig(
                          gtp.config.copyWith(windowDays: opt.days)),
                    ))
                .toList(),
          ),

          const Divider(height: 24),

          // ── Remetentes ───────────────────────────────────────────────────
          _SectionLabel('📬 Filtrar por remetente (opcional)'),
          const SizedBox(height: 4),
          Text(
            'Deixe vazio para analisar todos os e-mails da caixa de entrada',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          ...gtp.config.senderEmails.map((email) => _SenderChip(
                email: email,
                onRemove: () {
                  final updated = List<String>.from(gtp.config.senderEmails)
                    ..remove(email);
                  gtp.saveConfig(
                      gtp.config.copyWith(senderEmails: updated));
                },
              )),
          const SizedBox(height: 6),
          _AddSenderButton(gtp: gtp),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  final EmailWindowOption option;
  final bool selected;
  final VoidCallback onTap;
  const _WindowChip(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD44638)
              : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFD44638)
                : AppTheme.divider,
          ),
        ),
        child: Text(
          option.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SenderChip extends StatelessWidget {
  final String email;
  final VoidCallback onRemove;
  const _SenderChip({required this.email, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD44638).withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: const Color(0xFFD44638).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.email_outlined,
                size: 14, color: Color(0xFFD44638)),
            const SizedBox(width: 6),
            Text(
              email,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD44638),
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close,
                  size: 14, color: Color(0xFFD44638)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSenderButton extends StatelessWidget {
  final GmailTasksProvider gtp;
  const _AddSenderButton({required this.gtp});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showAddDialog(context),
      icon: const Icon(Icons.add, size: 14),
      label: const Text('Adicionar remetente', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD44638),
        side: const BorderSide(color: Color(0xFFD44638)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Adicionar remetente',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'email@exemplo.com',
            hintStyle:
                TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.divider)),
            focusedBorder: UnderlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFD44638))),
          ),
          onSubmitted: (v) {
            Navigator.pop(context);
            _addSender(context, ctrl.text.trim());
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
              _addSender(context, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD44638),
                foregroundColor: Colors.white),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _addSender(BuildContext context, String email) {
    if (email.isEmpty || !email.contains('@')) return;
    final current = List<String>.from(gtp.config.senderEmails);
    if (!current.contains(email)) {
      current.add(email);
      gtp.saveConfig(gtp.config.copyWith(senderEmails: current));
    }
  }
}

// ── Analyze Button ────────────────────────────────────────────────────────────

class _AnalyzeButton extends StatelessWidget {
  final GmailTasksProvider gtp;
  final String apiKey;
  const _AnalyzeButton({required this.gtp, required this.apiKey});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: gtp.isLoading
            ? null
            : () => gtp.analyze(apiKey: apiKey),
        icon: gtp.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.search, color: Colors.white, size: 18),
        label: Text(
          gtp.isLoading
              ? (gtp.status == GmailTasksStatus.fetchingEmails
                  ? 'Buscando e-mails...'
                  : 'Analisando com IA...')
              : (gtp.status == GmailTasksStatus.done
                  ? 'Reanalisar'
                  : 'Analisar E-mails'),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD44638),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  final GmailTasksProvider gtp;
  const _LoadingIndicator({required this.gtp});

  @override
  Widget build(BuildContext context) {
    final isFetching = gtp.status == GmailTasksStatus.fetchingEmails;
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(
              color: Color(0xFFD44638), strokeWidth: 2),
          const SizedBox(height: 12),
          Text(
            isFetching
                ? 'Buscando e-mails no Gmail...'
                : 'Analisando conteúdo com IA...',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final GmailTasksProvider gtp;
  const _ErrorCard({required this.gtp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              gtp.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Emails Summary ────────────────────────────────────────────────────────────

class _EmailsSummary extends StatelessWidget {
  final List<EmailMessage> emails;
  const _EmailsSummary({required this.emails});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Text('📥', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(
            '${emails.length} e-mail(s) analisado(s)',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Suggestions List ──────────────────────────────────────────────────────────

class _SuggestionsList extends StatelessWidget {
  final GmailTasksProvider gtp;
  final String uid;
  const _SuggestionsList({required this.gtp, required this.uid});

  @override
  Widget build(BuildContext context) {
    final suggestions = gtp.suggestions;

    if (suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Text('✅', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              'Nenhuma ação identificada nos e-mails analisados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${suggestions.length} tarefa(s) sugerida(s)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SuggestionCard(
                suggestion: s,
                gtp: gtp,
                uid: uid,
              ),
            )),
      ],
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final dynamic suggestion;
  final GmailTasksProvider gtp;
  final String uid;
  const _SuggestionCard(
      {required this.suggestion, required this.gtp, required this.uid});

  static const _qColors = {
    1: Color(0xFFEF4444),
    2: Color(0xFF10B981),
    3: Color(0xFFF59E0B),
    4: Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final qColor = _qColors[suggestion.eisenhowerQ] ?? _qColors[4]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: qColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: qColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: qColor.withOpacity(0.4)),
                ),
                child: Text(
                  '${suggestion.eisenhowerEmoji} ${suggestion.eisenhowerLabel}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: qColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (suggestion.isMIT)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.4)),
                  ),
                  child: const Text(
                    '⭐ MIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
              const Spacer(),
              _AreaBadge(areaId: suggestion.areaId),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            suggestion.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          if (suggestion.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              suggestion.description,
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 12, color: Color(0xFFD44638)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  suggestion.reasoning,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFD44638)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => gtp.dismiss(suggestion.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: AppTheme.divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Ignorar',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _createTask(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD44638),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Criar Tarefa',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _createTask(BuildContext context) {
    final task = TaskModel(
      id: 'email_task_${DateTime.now().millisecondsSinceEpoch}',
      userId: uid,
      title: suggestion.title,
      description: suggestion.description,
      areaId: suggestion.areaId,
      eisenhowerQ: suggestion.eisenhowerQ,
      isMIT: suggestion.isMIT,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    context.read<TasksProvider>().addTask(task);
    gtp.dismiss(suggestion.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tarefa "${suggestion.title}" criada!'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _AreaBadge extends StatelessWidget {
  final String areaId;
  const _AreaBadge({required this.areaId});

  @override
  Widget build(BuildContext context) {
    final config =
        kAreas.firstWhere((a) => a.id == areaId, orElse: () => kAreas.first);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${config.icon} ${config.name.split(' ').first}',
        style: TextStyle(
          fontSize: 10,
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Centered Message ──────────────────────────────────────────────────────────

class _CenteredMessage extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredMessage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.lock_open, color: Colors.white, size: 16),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD44638),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
