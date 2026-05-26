/// Modelo de evento do Google Calendar.
///
/// Suporta eventos com hora (dateTime) e eventos de dia inteiro (date).
/// A serialização fromGoogleJson/toGoogleJson segue o formato da
/// Google Calendar REST API v3.
class CalendarEventModel {
  final String? id;
  String title;
  String description;
  DateTime start;
  DateTime end;
  bool isAllDay;
  String location;

  CalendarEventModel({
    this.id,
    required this.title,
    this.description = '',
    required this.start,
    required this.end,
    this.isAllDay = false,
    this.location = '',
  });

  // ── Deserialização (Google Calendar → modelo) ─────────────────────────────

  factory CalendarEventModel.fromGoogleJson(Map<String, dynamic> json) {
    final startJson = (json['start'] as Map<String, dynamic>?) ?? {};
    final endJson = (json['end'] as Map<String, dynamic>?) ?? {};
    final isAllDay =
        startJson.containsKey('date') && !startJson.containsKey('dateTime');

    DateTime parseDateTime(Map<String, dynamic> d) {
      if (d['dateTime'] != null) {
        return DateTime.parse(d['dateTime'] as String).toLocal();
      }
      if (d['date'] != null) {
        return DateTime.parse(d['date'] as String);
      }
      return DateTime.now();
    }

    return CalendarEventModel(
      id: json['id'] as String?,
      title: json['summary'] as String? ?? '(sem título)',
      description: json['description'] as String? ?? '',
      start: parseDateTime(startJson),
      end: parseDateTime(endJson),
      isAllDay: isAllDay,
      location: json['location'] as String? ?? '',
    );
  }

  // ── Serialização (modelo → Google Calendar) ───────────────────────────────

  Map<String, dynamic> toGoogleJson() {
    final Map<String, dynamic> startMap;
    final Map<String, dynamic> endMap;

    if (isAllDay) {
      startMap = {'date': _fmtDate(start)};
      // Google Calendar: end date é exclusivo para eventos all-day
      // então usamos o dia seguinte se start == end
      final endDay = end.year == start.year &&
              end.month == start.month &&
              end.day == start.day
          ? end.add(const Duration(days: 1))
          : end;
      endMap = {'date': _fmtDate(endDay)};
    } else {
      startMap = {
        'dateTime': start.toUtc().toIso8601String(),
        'timeZone': 'America/Sao_Paulo',
      };
      endMap = {
        'dateTime': end.toUtc().toIso8601String(),
        'timeZone': 'America/Sao_Paulo',
      };
    }

    return {
      'summary': title,
      if (description.isNotEmpty) 'description': description,
      'start': startMap,
      'end': endMap,
      if (location.isNotEmpty) 'location': location,
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Duration get duration => end.difference(start);

  String get durationLabel {
    final mins = duration.inMinutes;
    if (mins < 60) return '${mins}min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    bool? isAllDay,
    String? location,
  }) =>
      CalendarEventModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        start: start ?? this.start,
        end: end ?? this.end,
        isAllDay: isAllDay ?? this.isAllDay,
        location: location ?? this.location,
      );
}
