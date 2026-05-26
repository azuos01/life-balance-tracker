import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/calendar_event_model.dart';

// ── Exceções ──────────────────────────────────────────────────────────────────

class CalendarAuthException implements Exception {
  final String message;
  const CalendarAuthException([this.message = 'Token expirado ou ausente']);
  @override
  String toString() => 'CalendarAuthException: $message';
}

class CalendarApiException implements Exception {
  final int statusCode;
  final String message;
  const CalendarApiException(this.message, {this.statusCode = 0});
  @override
  String toString() => 'CalendarApiException($statusCode): $message';
}

// ── Serviço ───────────────────────────────────────────────────────────────────

/// Serviço singleton para acesso à Google Calendar REST API v3.
///
/// Usa o access token OAuth2 obtido durante o sign-in com Google.
/// O token é válido por ~1 hora; em caso de 401 lança [CalendarAuthException].
class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  static const String _base =
      'https://www.googleapis.com/calendar/v3/calendars/primary/events';

  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
    debugPrint(
        '[CalendarService] token ${token != null ? 'configurado (${token.length} chars)' : 'removido'}');
  }

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  // ── Listagem ───────────────────────────────────────────────────────────────

  /// Retorna eventos do calendário primário no intervalo [from, to].
  Future<List<CalendarEventModel>> getEvents({
    DateTime? from,
    DateTime? to,
    int maxResults = 500,
  }) async {
    _requireToken();

    final params = <String, String>{
      'orderBy': 'startTime',
      'singleEvents': 'true',
      'maxResults': '$maxResults',
      if (from != null) 'timeMin': from.toUtc().toIso8601String(),
      if (to != null) 'timeMax': to.toUtc().toIso8601String(),
    };

    final resp = await http
        .get(Uri.parse(_base).replace(queryParameters: params),
            headers: _headers)
        .timeout(const Duration(seconds: 15));

    _assertSuccess(resp);

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = (data['items'] as List?) ?? [];
    return items
        .map((e) =>
            CalendarEventModel.fromGoogleJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Inserção ───────────────────────────────────────────────────────────────

  Future<CalendarEventModel> insertEvent(CalendarEventModel event) async {
    _requireToken();

    final resp = await http
        .post(Uri.parse(_base),
            headers: _headers, body: jsonEncode(event.toGoogleJson()))
        .timeout(const Duration(seconds: 15));

    _assertSuccess(resp);
    return CalendarEventModel.fromGoogleJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // ── Atualização ────────────────────────────────────────────────────────────

  Future<CalendarEventModel> updateEvent(CalendarEventModel event) async {
    _requireToken();
    if (event.id == null) {
      throw const CalendarApiException('ID do evento é obrigatório para atualizar');
    }

    final resp = await http
        .put(Uri.parse('$_base/${event.id}'),
            headers: _headers, body: jsonEncode(event.toGoogleJson()))
        .timeout(const Duration(seconds: 15));

    _assertSuccess(resp);
    return CalendarEventModel.fromGoogleJson(
        jsonDecode(resp.body) as Map<String, dynamic>);
  }

  // ── Exclusão ───────────────────────────────────────────────────────────────

  Future<void> deleteEvent(String eventId) async {
    _requireToken();

    final resp = await http
        .delete(Uri.parse('$_base/$eventId'), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode == 401) {
      _accessToken = null;
      throw const CalendarAuthException();
    }
    if (resp.statusCode != 204 && resp.statusCode != 200) {
      throw CalendarApiException(
          'Falha ao excluir evento',
          statusCode: resp.statusCode);
    }
  }

  // ── Helpers internos ──────────────────────────────────────────────────────

  void _requireToken() {
    if (!hasToken) throw const CalendarAuthException('Token não configurado');
  }

  void _assertSuccess(http.Response resp) {
    if (resp.statusCode == 401) {
      _accessToken = null;
      throw const CalendarAuthException();
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw CalendarApiException(
          'Erro ${resp.statusCode}: ${resp.body}',
          statusCode: resp.statusCode);
    }
  }
}
