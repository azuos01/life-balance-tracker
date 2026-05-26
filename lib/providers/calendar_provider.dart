import 'package:flutter/foundation.dart';
import '../models/calendar_event_model.dart';
import '../services/calendar_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

const String _kSyncDaysKey = 'calendar_sync_days';

enum CalendarStatus { initial, loading, ready, unauthorized, error }

class CalendarProvider extends ChangeNotifier {
  // ── Estado ────────────────────────────────────────────────────────────────

  List<CalendarEventModel> _events = [];
  List<CalendarEventModel> _syncEvents = [];
  CalendarStatus _status = CalendarStatus.initial;
  String? _errorMessage;

  /// Data selecionada no calendário (padrão: hoje)
  DateTime _selectedDate = _today();
  /// Mês visível no calendário
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);

  String _authProvider = '';

  /// Janela de sincronização em dias (7 | 15 | 30 | 90 | 180 | 360)
  int _syncDays;

  CalendarProvider()
      : _syncDays = int.tryParse(
              StorageService.instance.getString(_kSyncDaysKey) ?? '') ??
            7;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<CalendarEventModel> get events => List.unmodifiable(_events);
  CalendarStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  DateTime get viewMonth => _viewMonth;
  bool get isLoading => _status == CalendarStatus.loading;
  bool get isGoogleUser => _authProvider == 'google';
  bool get isAuthorized =>
      isGoogleUser && CalendarService.instance.hasToken;
  int get syncDays => _syncDays;

  static const List<int> syncDayOptions = [7, 15, 30, 90, 180, 360];

  /// Eventos dentro da janela de sincronização (hoje → hoje + syncDays).
  /// Usados por TasksProvider para criar tarefas automáticas.
  List<CalendarEventModel> get upcomingEvents {
    final today = _today();
    final cutoff = DateTime(
        today.year, today.month, today.day + _syncDays);
    return List.unmodifiable(
      _syncEvents
          .where((e) =>
              !e.start.isBefore(today) && e.start.isBefore(cutoff))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start)),
    );
  }

  /// Eventos do dia selecionado, ordenados por hora
  List<CalendarEventModel> get selectedDateEvents {
    return _events
        .where((e) => _sameDay(e.start, _selectedDate))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// Todos os eventos do mês visível (para dots no calendário)
  List<CalendarEventModel> get monthEvents {
    return _events
        .where((e) =>
            e.start.year == _viewMonth.year &&
            e.start.month == _viewMonth.month)
        .toList();
  }

  bool hasEventsOnDate(DateTime date) =>
      _events.any((e) => _sameDay(e.start, date));

  List<CalendarEventModel> eventsOnDate(DateTime date) =>
      _events.where((e) => _sameDay(e.start, date)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  // ── Sincronização com UserProvider ────────────────────────────────────────

  void syncUser(String? authProvider) {
    final prov = authProvider ?? '';
    if (_authProvider == prov) {
      // Re-check token in case it was just set by sign-in
      if (isGoogleUser && isAuthorized && _status == CalendarStatus.unauthorized) {
        loadEvents();
        _loadSyncWindowEvents();
      }
      return;
    }
    _authProvider = prov;

    if (isGoogleUser) {
      if (isAuthorized) {
        loadEvents();
        _loadSyncWindowEvents();
      } else {
        _status = CalendarStatus.unauthorized;
        notifyListeners();
      }
    } else {
      _events = [];
      _syncEvents = [];
      _status = CalendarStatus.unauthorized;
      notifyListeners();
    }
  }

  // ── Janela de sincronização ───────────────────────────────────────────────

  /// Define a janela de sincronização em dias e persiste localmente.
  /// Dispara recarga dos eventos se o usuário tiver acesso ao calendário.
  Future<void> setSyncDays(int days) async {
    assert(syncDayOptions.contains(days),
        'days deve ser um dos: $syncDayOptions');
    _syncDays = days;
    await StorageService.instance.setString(_kSyncDaysKey, days.toString());
    if (isAuthorized) {
      await _loadSyncWindowEvents();
    }
    notifyListeners();
  }

  /// Carrega eventos para a janela de sincronização (hoje → hoje + syncDays).
  /// Armazenado em _syncEvents (separado de _events do calendário visual).
  Future<void> _loadSyncWindowEvents() async {
    if (!isAuthorized) return;
    try {
      final today = _today();
      final to = DateTime(today.year, today.month, today.day + _syncDays + 1);
      _syncEvents =
          await CalendarService.instance.getEvents(from: today, to: to);
      notifyListeners();
    } on CalendarAuthException {
      _status = CalendarStatus.unauthorized;
      notifyListeners();
    } catch (e) {
      debugPrint('[CalendarProvider] _loadSyncWindowEvents error: $e');
    }
  }

  // ── Carregamento ─────────────────────────────────────────────────────────

  Future<void> loadEvents() async {
    if (!isGoogleUser) {
      _status = CalendarStatus.unauthorized;
      notifyListeners();
      return;
    }
    if (!isAuthorized) {
      _status = CalendarStatus.unauthorized;
      notifyListeners();
      return;
    }

    _status = CalendarStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Carrega eventos do mês anterior, atual e próximo
      final from = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
      final to = DateTime(_viewMonth.year, _viewMonth.month + 2, 1);
      final result =
          await CalendarService.instance.getEvents(from: from, to: to);
      _events = result;
      _status = CalendarStatus.ready;
    } on CalendarAuthException {
      _status = CalendarStatus.unauthorized;
    } catch (e) {
      _errorMessage = 'Erro ao carregar eventos: $e';
      _status = CalendarStatus.error;
      debugPrint('[CalendarProvider] $e');
    }
    notifyListeners();
  }

  // ── Autorização ───────────────────────────────────────────────────────────

  /// Solicita autorização de acesso ao Google Calendar via re-autenticação.
  /// Retorna true se o token foi obtido com sucesso.
  Future<bool> requestAccess() async {
    _status = CalendarStatus.loading;
    notifyListeners();

    final token = await AuthService.instance.requestCalendarAccess();
    if (token != null) {
      await loadEvents();
      await _loadSyncWindowEvents();
      return true;
    }
    _status = CalendarStatus.unauthorized;
    notifyListeners();
    return false;
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<CalendarEventModel?> addEvent(CalendarEventModel event) async {
    try {
      final created = await CalendarService.instance.insertEvent(event);
      _events.add(created);
      _sortEvents();
      notifyListeners();
      return created;
    } on CalendarAuthException {
      _status = CalendarStatus.unauthorized;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Erro ao criar evento: $e';
      notifyListeners();
      return null;
    }
  }

  Future<CalendarEventModel?> updateEvent(CalendarEventModel event) async {
    try {
      final updated = await CalendarService.instance.updateEvent(event);
      final i = _events.indexWhere((e) => e.id == event.id);
      if (i >= 0) _events[i] = updated;
      _sortEvents();
      notifyListeners();
      return updated;
    } on CalendarAuthException {
      _status = CalendarStatus.unauthorized;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Erro ao atualizar evento: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await CalendarService.instance.deleteEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      _syncEvents.removeWhere((e) => e.id == eventId);
      notifyListeners();
      return true;
    } on CalendarAuthException {
      _status = CalendarStatus.unauthorized;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao excluir evento: $e';
      notifyListeners();
      return false;
    }
  }

  // ── Navegação no calendário ───────────────────────────────────────────────

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> goToMonth(DateTime month) async {
    _viewMonth = DateTime(month.year, month.month);
    await loadEvents();
  }

  Future<void> nextMonth() =>
      goToMonth(DateTime(_viewMonth.year, _viewMonth.month + 1));

  Future<void> prevMonth() =>
      goToMonth(DateTime(_viewMonth.year, _viewMonth.month - 1));

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _sortEvents() {
    _events.sort((a, b) => a.start.compareTo(b.start));
  }
}
