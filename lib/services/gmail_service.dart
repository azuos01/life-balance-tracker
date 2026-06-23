import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/email_model.dart';

class GmailAuthException implements Exception {
  final String message;
  const GmailAuthException([this.message = 'Token de Gmail expirado ou ausente']);
  @override
  String toString() => 'GmailAuthException: $message';
}

class GmailApiException implements Exception {
  final int statusCode;
  final String message;
  const GmailApiException(this.message, {this.statusCode = 0});
  @override
  String toString() => 'GmailApiException($statusCode): $message';
}

/// Serviço singleton para acesso à Gmail REST API v1.
/// Reutiliza o access token OAuth2 do Google Sign-In (inclui scope gmail.readonly).
class GmailService {
  GmailService._();
  static final GmailService instance = GmailService._();

  static const _base = 'https://gmail.googleapis.com/gmail/v1/users/me';
  static const _maxConcurrentFetch = 5;

  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
    debugPrint(
        '[GmailService] token ${token != null ? 'configurado (${token.length} chars)' : 'removido'}');
  }

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  void _requireToken() {
    if (!hasToken) throw const GmailAuthException();
  }

  // ── Listagem de mensagens ─────────────────────────────────────────────────

  /// Retorna até [maxResults] e-mails dentro dos últimos [windowDays] dias.
  /// Se [senderEmails] não for vazio, filtra pelos remetentes informados.
  Future<List<EmailMessage>> getMessages({
    required int windowDays,
    List<String> senderEmails = const [],
    int maxResults = 30,
  }) async {
    _requireToken();

    // Monta query do Gmail
    final afterDate = DateTime.now().subtract(Duration(days: windowDays));
    final dateStr =
        '${afterDate.year}/${afterDate.month.toString().padLeft(2, '0')}/${afterDate.day.toString().padLeft(2, '0')}';

    String query = 'after:$dateStr in:inbox';
    if (senderEmails.isNotEmpty) {
      final fromPart =
          senderEmails.map((e) => 'from:$e').join(' OR ');
      query += ' ($fromPart)';
    }

    // 1 — Lista IDs
    final listUri = Uri.parse(
      '$_base/messages?q=${Uri.encodeComponent(query)}&maxResults=$maxResults',
    );
    final listResp = await http.get(listUri, headers: _headers);
    _handleErrors(listResp);

    final listBody =
        jsonDecode(utf8.decode(listResp.bodyBytes)) as Map<String, dynamic>;
    final rawMessages = (listBody['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (rawMessages.isEmpty) return [];

    // 2 — Busca detalhes em lotes de _maxConcurrentFetch
    final messages = <EmailMessage>[];
    for (var i = 0; i < rawMessages.length; i += _maxConcurrentFetch) {
      final batch = rawMessages.skip(i).take(_maxConcurrentFetch).toList();
      final futures = batch.map((m) => _fetchMessage(m['id'] as String));
      final results = await Future.wait(futures, eagerError: false);
      for (final r in results) {
        if (r != null) messages.add(r);
      }
    }

    return messages;
  }

  Future<EmailMessage?> _fetchMessage(String id) async {
    try {
      final uri = Uri.parse(
        '$_base/messages/$id?format=metadata&metadataHeaders=Subject,From,Date',
      );
      final resp = await http.get(uri, headers: _headers);
      _handleErrors(resp);

      final body =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final headers = (body['payload']?['headers'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      String getHeader(String name) => headers
          .firstWhere((h) => (h['name'] as String).toLowerCase() == name.toLowerCase(),
              orElse: () => {'value': ''})['value'] as String? ?? '';

      final snippet = (body['snippet'] as String? ?? '').replaceAll('&quot;', '"').trim();
      final subject = getHeader('Subject');
      final from = getHeader('From');
      final dateStr = getHeader('Date');

      DateTime date;
      try {
        date = _parseEmailDate(dateStr);
      } catch (_) {
        date = DateTime.now();
      }

      return EmailMessage(
        id: id,
        subject: subject.isEmpty ? '(Sem assunto)' : subject,
        from: from,
        snippet: snippet,
        date: date,
      );
    } catch (e) {
      debugPrint('[GmailService] _fetchMessage($id) error: $e');
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _handleErrors(http.Response resp) {
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      throw GmailAuthException(
          'Acesso negado (${resp.statusCode}). Reconnecte ao Google.');
    }
    if (resp.statusCode != 200) {
      throw GmailApiException(
        'Erro ao acessar Gmail (${resp.statusCode})',
        statusCode: resp.statusCode,
      );
    }
  }

  /// Parseia datas no formato RFC 2822 comuns em e-mails,
  /// ex: "Mon, 01 Jan 2024 12:00:00 +0000"
  DateTime _parseEmailDate(String dateStr) {
    // Remove timezone offset and try direct parse
    final clean = dateStr.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();
    // Try standard parse first
    try {
      return DateTime.parse(clean);
    } catch (_) {}

    // Try RFC 2822 pattern: "Mon, 1 Jan 2024 12:00:00 +0000"
    final months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = clean.split(RegExp(r'[\s,]+'));
    if (parts.length >= 5) {
      final dayIdx = parts.indexWhere((p) => int.tryParse(p) != null);
      if (dayIdx >= 0 && dayIdx + 3 < parts.length) {
        final day = int.parse(parts[dayIdx]);
        final month = months[parts[dayIdx + 1]] ?? 1;
        final year = int.tryParse(parts[dayIdx + 2]) ?? 2024;
        final timeParts = (parts[dayIdx + 3]).split(':');
        final hour = int.tryParse(timeParts.isNotEmpty ? timeParts[0] : '0') ?? 0;
        final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
        return DateTime(year, month, day, hour, minute);
      }
    }
    return DateTime.now();
  }
}
