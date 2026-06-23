// ── Email Message ─────────────────────────────────────────────────────────────

class EmailMessage {
  final String id;
  final String subject;
  final String from;
  final String snippet;
  final DateTime date;

  const EmailMessage({
    required this.id,
    required this.subject,
    required this.from,
    required this.snippet,
    required this.date,
  });

  String get fromName {
    final match = RegExp(r'^(.*?)\s*<').firstMatch(from);
    final name = match?.group(1)?.trim() ?? from;
    return name.isEmpty ? from : name;
  }
}

// ── Email Analysis Config ─────────────────────────────────────────────────────

class EmailWindowOption {
  final String label;
  final int days;
  const EmailWindowOption(this.label, this.days);
}

const kEmailWindowOptions = [
  EmailWindowOption('1 dia', 1),
  EmailWindowOption('1 semana', 7),
  EmailWindowOption('1 mês', 30),
  EmailWindowOption('1 trimestre', 90),
  EmailWindowOption('1 semestre', 180),
  EmailWindowOption('1 ano', 365),
];

class EmailAnalysisConfig {
  final List<String> senderEmails;
  final int windowDays;

  const EmailAnalysisConfig({
    this.senderEmails = const [],
    this.windowDays = 7,
  });

  EmailAnalysisConfig copyWith({
    List<String>? senderEmails,
    int? windowDays,
  }) =>
      EmailAnalysisConfig(
        senderEmails: senderEmails ?? this.senderEmails,
        windowDays: windowDays ?? this.windowDays,
      );

  Map<String, dynamic> toJson() => {
        'senderEmails': senderEmails,
        'windowDays': windowDays,
      };

  factory EmailAnalysisConfig.fromJson(Map<String, dynamic> json) =>
      EmailAnalysisConfig(
        senderEmails: (json['senderEmails'] as List? ?? []).cast<String>(),
        windowDays: json['windowDays'] as int? ?? 7,
      );
}
