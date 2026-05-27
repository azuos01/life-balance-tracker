# ⚖️ Life Balance Tracker

> Sistema gamificado de gestão de vida com as **10 áreas fundamentais** do equilíbrio pessoal.

[![Deploy](https://github.com/azuos01/life-balance-tracker/actions/workflows/deploy.yml/badge.svg)](https://github.com/azuos01/life-balance-tracker/actions/workflows/deploy.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Versão](https://img.shields.io/badge/versão-2.0.0-blueviolet)](pubspec.yaml)

**🌐 Live:** https://azuos01.github.io/life-balance-tracker/

---

## Visão Geral

O Life Balance Tracker é um aplicativo Flutter Web que combina **gamificação** com **gestão intencional de vida**. O usuário acompanha e evolui as 10 áreas da Roda da Vida, registra atividades, planeja tarefas com a Matriz de Eisenhower/Kanban, realiza check-ins diários e sincroniza compromissos diretamente do Google Agenda — tudo persistido localmente ou na nuvem via Cloud Firestore.

---

## Funcionalidades Implementadas (v2.0.0)

### 🔐 Autenticação
- [x] Login com **Google** (Firebase Auth + OAuth2)
- [x] Login com **LinkedIn** (OAuth2 PKCE — sem backend)
- [x] Modo **offline/local** (sem conta) com SharedPreferences
- [x] Migração automática de dados locais → cloud ao fazer login

### 🏠 Dashboard
- [x] **Roda da Vida** — gráfico radar interativo com as 10 áreas (CustomPainter)
- [x] Score de equilíbrio geral (0–100%)
- [x] Cards de visão rápida por área (score + importância)
- [x] **Frase filosófica diária** (150 citações, seleção determinística por dia)
- [x] Resumo de atividades da semana e check-ins

### 🎯 Sistema de XP e Gamificação
- [x] XP por dificuldade: fácil **10** / médio **25** / difícil **50** XP
- [x] XP adicional: hábito **15** / streak **100** / objetivo **500** / check-in **20**
- [x] **5 tiers**: Iniciante → Praticante → Guerreiro → Mestre → Lenda
- [x] **100 níveis** (cálculo progressivo por tier)
- [x] Streak de dias consecutivos com bônus
- [x] **8 conquistas** com sistema de desbloqueio automático

### 📋 Planejamento de Tarefas
- [x] **Matriz de Eisenhower** (4 quadrantes: Urgente/Importante)
- [x] **Kanban** (Planejado → Em Progresso → Concluído)
- [x] **MITs — Most Important Tasks** (máx. 3 por dia)
- [x] Classificação automática de área por palavras-chave (`AreaClassifier`)
- [x] Sincronização bidirecional com Cloud Firestore
- [x] Tarefas de calendário protegidas (não editáveis/deletáveis pelo usuário)

### 📅 Google Agenda
- [x] Integração com **Google Calendar REST API v3**
- [x] Visualização de eventos por mês (calendário interativo)
- [x] Criação e edição de eventos com data, hora e recorrência
- [x] **Sincronização automática** de compromissos → Tarefas Planejadas
- [x] Janela de sincronização configurável: **7 / 15 / 30 / 90 / 180 / 360 dias**
- [x] Badge `🗓️ Google Agenda` em tarefas originadas do calendário
- [x] Estado das tarefas de calendário persistido localmente (overrides)

### 📓 Diário (Check-ins)
- [x] **Check-in matinal**: humor (1-5), energia (1-5), intenções do dia, gratidão
- [x] **Check-out noturno**: nota do dia (1-10), reflexão, plano para amanhã
- [x] Histórico de check-ins com contadores
- [x] Apenas um check-in por dia (atualização em vez de duplicação)

### 📊 Atividades
- [x] Registro de atividades com área, duração e dificuldade
- [x] Heatmap de atividades estilo GitHub (por dia)
- [x] Agrupamento de XP por área (`xpByArea`)
- [x] Filtro de atividades por área (`activitiesByArea`)
- [x] Áreas ativas na última semana (`areasActiveThisWeek`)

### 🎯 Objetivos
- [x] Criação de objetivos por área com título, prazo e progresso (%)
- [x] Status: `pendente` / `em andamento` / `concluído`
- [x] Edição e exclusão de objetivos
- [x] Listagem de objetivos ativos (exclui concluídos)

### ⚙️ Configurações
- [x] Alternância **Dark / Light theme** (persistida)
- [x] Alternância de idioma **Português / English** (i18n com `AppLocalizations`)
- [x] Configuração da janela de sincronização do Google Agenda
- [x] Reset completo de dados do usuário
- [x] **Seção de informações do app** com versão, tipo de release e changelog

### ☁️ Cloud (Firebase)
- [x] Cloud Firestore com estrutura `users/{uid}/{profile|activities|areas|checkIns|achievements|tasks}`
- [x] Dados completamente isolados por `uid`
- [x] Modo local → cloud transparente (sem mudança de UX)

---

## Estrutura do Projeto

```
life_balance_tracker/
│
├── .github/
│   └── workflows/
│       └── deploy.yml              # CI/CD: testes → build → GitHub Pages
│
├── test/
│   ├── models/
│   │   ├── activity_model_test.dart
│   │   ├── area_model_test.dart
│   │   ├── task_model_test.dart
│   │   └── user_model_test.dart
│   └── providers/
│       ├── activities_provider_test.dart
│       ├── areas_provider_test.dart
│       └── tasks_provider_test.dart
│
└── lib/
    ├── main.dart                    # Entry point + MultiProvider
    ├── app.dart                     # MaterialApp + roteamento + temas
    │
    ├── constants/
    │   └── app_constants.dart       # 10 áreas, XP, níveis, tiers, changelog
    │
    ├── theme/
    │   └── app_theme.dart           # Dark/light theme + cores das 10 áreas
    │
    ├── l10n/
    │   └── app_l10n.dart            # Internacionalização PT/EN (inline)
    │
    ├── models/
    │   ├── user_model.dart          # Perfil, XP, tier, nível, streak
    │   ├── area_model.dart          # Área da roda da vida + GoalModel
    │   ├── activity_model.dart      # Log de atividade
    │   ├── checkin_model.dart       # Check-in matinal + noturno
    │   ├── achievement_model.dart   # Conquistas
    │   ├── task_model.dart          # Tarefas Eisenhower/Kanban + MIT
    │   └── calendar_event_model.dart # Evento do Google Calendar
    │
    ├── services/
    │   ├── storage_service.dart     # SharedPreferences wrapper (singleton)
    │   ├── firestore_service.dart   # Cloud Firestore CRUD por coleção
    │   ├── auth_service.dart        # Google + LinkedIn OAuth2 PKCE
    │   ├── calendar_service.dart    # Google Calendar REST API v3
    │   ├── area_classifier.dart     # Classificação de tarefas por palavras-chave
    │   └── quotes_service.dart      # 150 frases filosóficas (por dia do ano)
    │
    ├── providers/
    │   ├── user_provider.dart       # XP, nível, streak, conquistas, auth
    │   ├── areas_provider.dart      # 10 áreas, scores, objetivos
    │   ├── activities_provider.dart # Atividades, check-ins, heatmap
    │   ├── tasks_provider.dart      # Tarefas, Kanban, Eisenhower, MITs, sync calendário
    │   ├── calendar_provider.dart   # Google Calendar, janela de sync, eventos
    │   └── settings_provider.dart  # Tema, idioma
    │
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── onboarding_screen.dart   # Wizard 3 passos (nome + scores + objetivos)
    │   ├── main_screen.dart         # Bottom nav (5 abas)
    │   ├── dashboard_screen.dart    # Roda da Vida + overview + frase do dia
    │   ├── activities_screen.dart   # Histórico + heatmap
    │   ├── goals_screen.dart        # Objetivos por área
    │   ├── profile_screen.dart      # XP, conquistas, stats, configurações
    │   ├── auth/
    │   │   └── login_screen.dart    # Google + LinkedIn sign-in
    │   ├── logging/
    │   │   ├── add_activity_screen.dart
    │   │   ├── morning_checkin_screen.dart
    │   │   └── evening_checkout_screen.dart
    │   ├── tasks/
    │   │   ├── tasks_screen.dart    # Kanban + Eisenhower + MITs (TabBar 3 abas)
    │   │   └── task_create_screen.dart
    │   └── calendar/
    │       ├── calendar_screen.dart # Calendário mensal interativo
    │       └── event_form_screen.dart
    │
    ├── widgets/
    │   ├── life_wheel_chart.dart    # Gráfico radar (CustomPainter)
    │   ├── xp_progress_bar.dart     # Barra de XP animada
    │   ├── area_card.dart           # Card de área da Roda da Vida
    │   └── app_background.dart      # Background gradiente adaptativo dark/light
    │
    └── firebase_options.dart        # Configuração Firebase (gerada pelo FlutterFire CLI)
```

---

## Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| Framework | Flutter 3.x / Dart 3.x |
| Estado | Provider (`ChangeNotifier`, `ProxyProvider2`) |
| Autenticação | Firebase Auth + Google Sign-In + LinkedIn OAuth2 PKCE |
| Banco de dados cloud | Cloud Firestore |
| Persistência local | SharedPreferences |
| Integração de agenda | Google Calendar REST API v3 |
| Deploy | GitHub Pages via `peaceiris/actions-gh-pages` |
| CI/CD | GitHub Actions (test gate + build + deploy) |
| Testes | `flutter_test` (134 testes unitários) |
| Fontes | Google Fonts |
| Geração de IDs | uuid |

---

## Como Rodar

### Pré-requisitos

- Flutter SDK ≥ 3.3.0 — https://docs.flutter.dev/get-started/install
- Dart SDK ≥ 3.3.0 (incluído no Flutter)
- Conta Google com projeto Firebase configurado (opcional — app funciona sem login)

### Instalação

```bash
# 1. Clone o repositório
git clone https://github.com/azuos01/life-balance-tracker.git
cd life-balance-tracker

# 2. Instale as dependências
flutter pub get

# 3. Verifique o ambiente
flutter doctor
```

### Executar localmente

```bash
# Web (Chrome)
flutter run -d chrome

# Android (com emulador ou dispositivo)
flutter run

# Windows desktop
flutter run -d windows
```

### Build de produção

```bash
flutter build web --release --base-href "/life-balance-tracker/"
```

---

## Testes

```bash
# Executar todos os testes
flutter test --reporter=expanded

# Com cobertura
flutter test --coverage --reporter=expanded
```

**134 testes unitários** cobrindo:

| Arquivo | Testes |
|---|---|
| `test/models/task_model_test.dart` | 35 |
| `test/models/user_model_test.dart` | 17 |
| `test/models/area_model_test.dart` | 12 |
| `test/models/activity_model_test.dart` | 7 |
| `test/providers/tasks_provider_test.dart` | 41 |
| `test/providers/areas_provider_test.dart` | 20 |
| `test/providers/activities_provider_test.dart` | 20 |

---

## CI/CD

O pipeline `.github/workflows/deploy.yml` executa em todo push/PR para `main`:

```
push → main
  ├── [1] 🧪 Testes Unitários
  │       flutter analyze --no-fatal-infos
  │       flutter test --reporter=expanded
  │       flutter test --coverage  (artefato: coverage/lcov.info)
  │
  └── [2] 🏗️ Build + Deploy  (somente push, após testes passarem)
          flutter build web --release
          peaceiris/actions-gh-pages → GitHub Pages
```

> Node.js 24 opt-in ativo via `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: 'true'`.

---

## Versionamento

Formato: **`MAJOR.MINOR.PATCH+BUILD`**

| Dígito | Quando incrementar |
|---|---|
| `MAJOR` | Alterações complexas de arquitetura (ex: mudança de providers, refatoração de camadas) |
| `MINOR` | Novas funcionalidades e melhorias (ex: nova tela, nova feature) |
| `PATCH` | Correções de bugs (ex: fix de lógica, crash fix, correção visual) |
| `+BUILD` | Incrementado a cada publicação/release |

---

## 10 Áreas da Roda da Vida

| # | Área | Ícone |
|---|---|---|
| 1 | Saúde Física | 💪 |
| 2 | Saúde Mental | 🧠 |
| 3 | Carreira e Propósito | 🚀 |
| 4 | Finanças Pessoais | 💰 |
| 5 | Relacionamentos Íntimos | ❤️ |
| 6 | Família e Amizades | 👨‍👩‍👧 |
| 7 | Desenvolvimento Intelectual | 📚 |
| 8 | Espiritualidade e Propósito | 🌟 |
| 9 | Lazer e Criatividade | 🎨 |
| 10 | Contribuição e Legado | 🌍 |

---

## Roadmap — Sugestões de Novos Desenvolvimentos

### 🔔 Notificações e Engajamento
- [ ] Notificações push para check-in matinal e check-out noturno (horários configuráveis)
- [ ] Lembretes de tarefas MITs com X minutos de antecedência
- [ ] Notificação de streak em risco ("Você não fez check-in hoje ainda!")

### 📊 Analytics e Insights
- [ ] Gráfico de evolução de scores das 10 áreas ao longo do tempo (linha temporal)
- [ ] Painel de insights automáticos ("Você não registra atividade em Saúde Mental há 7 dias")
- [ ] Correlação entre score de área e XP ganho
- [ ] Relatório semanal/mensal em PDF exportável
- [ ] Exportação de dados em CSV

### 🤖 Inteligência Artificial
- [ ] Sugestão de atividades baseada em áreas com score mais baixo
- [ ] Análise de sentimento do check-in noturno (reflexão textual)
- [ ] Geração automática de objetivos SMART com base no perfil
- [ ] Resumo semanal gerado por IA com pontos de atenção

### 🔗 Integrações Externas
- [ ] Sincronização com **Google Fit / Apple Health** (passos, sono, frequência cardíaca)
- [ ] Integração com **Notion** para importar tarefas como blocos
- [ ] Integração com **Todoist / TickTick** via API REST
- [ ] Webhook para Zapier / Make (automação externa)
- [ ] Importação de tarefas do **Microsoft Outlook Calendar**

### 👥 Social e Colaboração
- [ ] Perfil público compartilhável (Roda da Vida pública com link)
- [ ] Grupos e desafios coletivos ("Grupo de corrida — meta semanal")
- [ ] Ranking de XP entre amigos (leaderboard opt-in)
- [ ] Mentor/mentee: compartilhar progresso com coach ou mentor

### 🎮 Gamificação Avançada
- [ ] Missões semanais com recompensas extras de XP
- [ ] Conquistas sazonais (ex: "30 dias de streak em dezembro")
- [ ] Sistema de loja de avatares/skins desbloqueáveis com XP
- [ ] Modo desafio: completar todas as 10 áreas em 1 semana

### 📱 Plataforma e UX
- [ ] App nativo Android / iOS (build mobile com suporte a push nativo)
- [ ] Widget de tela inicial (Android) com score diário e MIT do dia
- [ ] Modo offline completo com sincronização delta ao reconectar
- [ ] Acessibilidade: suporte a leitores de tela, contraste elevado
- [ ] Suporte a ES/FR/DE (extensão do sistema i18n existente)

### 🔐 Segurança e Privacidade
- [ ] Autenticação por biometria (Face ID / impressão digital) no mobile
- [ ] Criptografia local dos dados em SharedPreferences
- [ ] Exportação e exclusão completa de dados (LGPD/GDPR compliance)
- [ ] Histórico de sessões e revogação de acesso por dispositivo

---

## Segurança

> ⚠️ **O Client Secret do LinkedIn vai APENAS no Firebase Console, nunca no código ou repositório.**
> A Firebase API Key é segura em repositório público (restrita por domínio).

---

## Licença

Este projeto é privado. Todos os direitos reservados.
