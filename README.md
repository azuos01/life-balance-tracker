# Life Balance Tracker

App Flutter para gerenciamento de vida gamificado com 10 áreas fundamentais.

## Como rodar

### 1. Instalar o Flutter SDK

Baixe em: https://docs.flutter.dev/get-started/install/windows

Adicione `flutter/bin` ao PATH e verifique com:
```
flutter doctor
```

### 2. Instalar dependências

```
flutter pub get
```

### 3. Rodar o app

**Android/iOS:**
```
flutter run
```

**Web (browser):**
```
flutter run -d chrome
```

**Windows desktop:**
```
flutter run -d windows
```

## Estrutura do projeto

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + roteamento raiz
├── constants/
│   └── app_constants.dart       # Configuração das 10 áreas + XP
├── models/
│   ├── user_model.dart
│   ├── area_model.dart          # Inclui GoalModel
│   ├── activity_model.dart
│   ├── checkin_model.dart
│   └── achievement_model.dart
├── services/
│   └── storage_service.dart     # SharedPreferences wrapper
├── providers/
│   ├── user_provider.dart       # XP, nível, streak, conquistas
│   ├── areas_provider.dart      # 10 áreas + scores + objetivos
│   └── activities_provider.dart # Logs de atividade + check-ins
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart   # Wizard 3 passos
│   ├── main_screen.dart         # Bottom nav (4 abas)
│   ├── dashboard_screen.dart    # Roda da Vida + overview
│   ├── activities_screen.dart   # Histórico de atividades
│   ├── goals_screen.dart        # Objetivos por área
│   ├── profile_screen.dart      # XP, conquistas, stats
│   └── logging/
│       ├── add_activity_screen.dart
│       ├── morning_checkin_screen.dart
│       └── evening_checkout_screen.dart
├── widgets/
│   ├── life_wheel_chart.dart    # Gráfico radar (CustomPainter)
│   ├── xp_progress_bar.dart
│   └── area_card.dart
└── theme/
    └── app_theme.dart           # Dark theme + cores das áreas
```

## Funcionalidades implementadas (MVP)

- [x] Onboarding wizard (nome + scores das 10 áreas + objetivos)
- [x] Dashboard com Roda da Vida (gráfico radar interativo)
- [x] Score de equilíbrio geral (0-100%)
- [x] Sistema de XP (fácil 10 / médio 25 / difícil 50 XP)
- [x] Níveis e tiers (Iniciante → Praticante → Guerreiro → Mestre → Lenda)
- [x] Streak de dias consecutivos
- [x] Check-in matinal (humor, energia, intenções, gratidão)
- [x] Check-out noturno (nota do dia, reflexão, plano)
- [x] Log de atividades com área, duração e dificuldade
- [x] Gestão de objetivos (criar, concluir, progresso)
- [x] 8 conquistas com sistema de desbloqueio
- [x] Persistência local (SharedPreferences)
- [x] Dark mode com tema purple/neon

## Próximos passos sugeridos

- Analytics: heatmap de atividades estilo GitHub
- Notificações push para check-ins
- Insights baseados em padrões
- Export CSV/PDF
- Modo claro
