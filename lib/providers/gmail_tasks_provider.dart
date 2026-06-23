import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/email_model.dart';
import '../models/task_suggestion.dart';
import '../services/gmail_service.dart';
import '../services/storage_service.dart';

const _kConfigKey = 'gmail_tasks_config';
const _kEndpoint = 'https://api.openai.com/v1/chat/completions';
const _kModel = 'gpt-4o-mini';

enum GmailTasksStatus { idle, fetchingEmails, analyzingWithAI, done, error }

class GmailTasksProvider extends ChangeNotifier {
  // ── Config ────────────────────────────────────────────────────────────────
  EmailAnalysisConfig _config = const EmailAnalysisConfig();
  EmailAnalysisConfig get config => _config;

  // ── Estado ────────────────────────────────────────────────────────────────
  GmailTasksStatus _status = GmailTasksStatus.idle;
  GmailTasksStatus get status => _status;
  bool get isLoading =>
      _status == GmailTasksStatus.fetchingEmails ||
      _status == GmailTasksStatus.analyzingWithAI;

  List<EmailMessage> _emails = [];
  List<EmailMessage> get emails => _emails;

  List<TaskSuggestion> _suggestions = [];
  final Set<String> _dismissed = {};
  List<TaskSuggestion> get suggestions =>
      _suggestions.where((s) => !_dismissed.contains(s.id)).toList();

  String? _error;
  String? get error => _error;
  DateTime? _lastRun;
  DateTime? get lastRun => _lastRun;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final raw = StorageService.instance.getJson(_kConfigKey);
    if (raw != null) {
      try {
        _config = EmailAnalysisConfig.fromJson(raw);
      } catch (_) {}
    }
  }

  // ── Config ────────────────────────────────────────────────────────────────

  Future<void> saveConfig(EmailAnalysisConfig config) async {
    _config = config;
    await StorageService.instance.setJson(_kConfigKey, config.toJson());
    notifyListeners();
  }

  // ── Analysis ──────────────────────────────────────────────────────────────

  Future<void> analyze({required String apiKey}) async {
    if (isLoading) return;

    _status = GmailTasksStatus.fetchingEmails;
    _error = null;
    _suggestions = [];
    _dismissed.clear();
    notifyListeners();

    try {
      // 1 — Busca e-mails via Gmail API
      _emails = await GmailService.instance.getMessages(
        windowDays: _config.windowDays,
        senderEmails: _config.senderEmails,
        maxResults: 30,
      );

      if (_emails.isEmpty) {
        _status = GmailTasksStatus.done;
        _lastRun = DateTime.now();
        notifyListeners();
        return;
      }

      // 2 — Análise via OpenAI
      _status = GmailTasksStatus.analyzingWithAI;
      notifyListeners();

      _suggestions = await _generateSuggestions(
        apiKey: apiKey,
        emails: _emails,
        windowDays: _config.windowDays,
      );

      _status = GmailTasksStatus.done;
      _lastRun = DateTime.now();
    } on GmailAuthException catch (e) {
      _error = e.message;
      _status = GmailTasksStatus.error;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = GmailTasksStatus.error;
    }

    notifyListeners();
  }

  void dismiss(String id) {
    _dismissed.add(id);
    notifyListeners();
  }

  void clear() {
    _suggestions = [];
    _dismissed.clear();
    _emails = [];
    _error = null;
    _status = GmailTasksStatus.idle;
    _lastRun = null;
    notifyListeners();
  }

  // ── OpenAI ────────────────────────────────────────────────────────────────

  Future<List<TaskSuggestion>> _generateSuggestions({
    required String apiKey,
    required List<EmailMessage> emails,
    required int windowDays,
  }) async {
    final windowLabel = _windowLabel(windowDays);
    final emailsText = emails.asMap().entries.map((e) {
      final em = e.value;
      final i = e.key + 1;
      final dateStr =
          '${em.date.day.toString().padLeft(2, '0')}/${em.date.month.toString().padLeft(2, '0')}';
      return '$i. [$dateStr] De: ${em.fromName} | Assunto: ${em.subject}\n   Resumo: ${em.snippet}';
    }).join('\n\n');

    const areas = 'health_physical, health_mental, career, finances, '
        'relationships, family, intellectual, spirituality, leisure, contribution';

    final systemPrompt = '''
Você é um assistente de produtividade pessoal. Analise os e-mails abaixo e identifique APENAS ações concretas que o usuário precisa executar.

Regras obrigatórias:
- IGNORE e-mails informativos, newsletters, promoções e notificações sem ação necessária
- Gere tarefas APENAS quando há um compromisso, prazo, pedido ou ação explícita no e-mail
- Máximo de 8 tarefas; prefira qualidade a quantidade
- Priorize com Matriz de Eisenhower:
  1 = Urgente e Importante (faça agora)
  2 = Importante, não urgente (agende)
  3 = Urgente, não importante (delegue)
  4 = Nem urgente nem importante (elimine)
- isMIT = true apenas para as 3 tarefas mais críticas do dia
- areaId deve ser uma das áreas: $areas
- reasoning deve mencionar o e-mail de origem

Responda SOMENTE com JSON válido:
{"suggestions":[{"title":"...","description":"...","areaId":"career","eisenhowerQ":1,"isMIT":false,"reasoning":"..."}]}
''';

    final userPrompt =
        'Janela de análise: $windowLabel\nTotal de e-mails: ${emails.length}\n\n$emailsText';

    final resp = await http
        .post(
          Uri.parse(_kEndpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _kModel,
            'response_format': {'type': 'json_object'},
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.3,
            'max_tokens': 1500,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (resp.statusCode != 200) {
      throw Exception('OpenAI error ${resp.statusCode}: ${resp.body}');
    }

    final body =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final content =
        body['choices'][0]['message']['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final rawList =
        (parsed['suggestions'] as List? ?? []).cast<Map<String, dynamic>>();

    return rawList
        .asMap()
        .entries
        .map((e) => TaskSuggestion.fromJson('email_${e.key}', e.value))
        .toList();
  }

  String _windowLabel(int days) {
    for (final opt in kEmailWindowOptions) {
      if (opt.days == days) return opt.label;
    }
    return '$days dias';
  }
}
