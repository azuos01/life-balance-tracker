# ⚖️ Life Balance Tracker

> Sistema gamificado de gestão de vida com as **10 áreas fundamentais** do equilíbrio pessoal.

[![Deploy](https://github.com/azuos01/life-balance-tracker/actions/workflows/deploy.yml/badge.svg)](https://github.com/azuos01/life-balance-tracker/actions/workflows/deploy.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase)](https://firebase.google.com)
[![Versão](https://img.shields.io/badge/versão-2.7.0-blueviolet)](pubspec.yaml)

**🌐 Live:** https://azuos01.github.io/life-balance-tracker/

---

## Visão Geral

O Life Balance Tracker é um aplicativo Flutter Web que combina **gamificação** com **gestão intencional de vida**. O usuário acompanha e evolui as 10 áreas da Roda da Vida, registra atividades, planeja tarefas com a Matriz de Eisenhower/Kanban, realiza check-ins diários, sincroniza compromissos do Google Agenda, analisa e-mails para gerar tarefas automaticamente via IA, e acompanha a previsão do tempo integrada ao seu plano do dia — tudo persistido localmente ou na nuvem via Cloud Firestore.

---

## Funcionalidades Implementadas (v2.7.0)

### 🔐 Autenticação

- [x] Login com **Google** (Firebase Auth + OAuth2 — escopos: Calendar + Gmail)
- [x] Login com **LinkedIn** (OAuth2 PKCE — sem backend)
- [x] Modo **offline/local** (sem conta) com SharedPreferences
- [x] Migração automática de dados locais → cloud ao fazer login

### 🏠 Dashboard

- [x] **Roda da Vida** — gráfico radar interativo com as 10 áreas (CustomPainter)
- [x] Score de equilíbrio geral (0–100%)
- [x] Cards de visão rápida por área (score + importância)
- [x] **Frase filosófica diária** (150 citações, seleção determinística por dia)
- [x] Resumo de atividades da semana e check-ins
- [x] **Previsão do tempo** via Open-Meteo (sem API key) com temperatura atual e forecast de 3 dias
- [x] **Alertas de tarefas sensíveis ao clima** — avisa quando há tarefas como limpeza, instalação solar ou jardinagem e a previsão é de chuva ou tempestade

### 🎯 Sistema de XP e Gamificação

- [x] XP por dificuldade: fácil **10** / médio **25** / difícil **50** XP
- [x] XP adicional: hábito **15** / streak **100** / objetivo **500** / check-in **20**
- [x] **5 tiers**: Iniciante → Praticante → Guerreiro → Mestre → Lenda
- [x] **100 níveis** (cálculo progressivo por tier)
- [x] Streak de dias consecutivos com bônus
- [x] **8 conquistas** com sistema de desbloqueio automático

### 📋 Planejamento de Tarefas (6 abas)

- [x] **Matriz de Eisenhower** — Q1=+Urg+Imp (🔴), Q2=+Urg−Imp (🟡), Q3=−Urg+Imp (🟢), Q4=−Urg−Imp (⚫)
- [x] **Kanban** (4 colunas: Planejado → Em Andamento → Feito → Bloqueado) com scroll horizontal
- [x] **MITs — Most Important Tasks** (máx. 3 por dia)
- [x] **Histórico** de tarefas concluídas
- [x] **Relatórios** com filtros de status, taxa de conclusão e métricas por área
- [x] **IA (Agente OpenAI)** — sugere tarefas priorizadas por Eisenhower/MIT com base no perfil de vida (GPT-4o-mini)
- [x] **E-mail** — analisa e-mails do Gmail e gera tarefas automaticamente via IA
- [x] **Campos padronizados** em todas as tarefas:
  - ID com timestamp (`YYYYMMDDHHMMSSXX`) — sem colisões no mesmo segundo
  - Área da Vida (auto-classificada por `AreaClassifier` em importações)
  - Prazo (`dueDate`), Tempo Estimado em horas (slider 30min–24h)
  - Campo **Localização** vinculado ao Google Maps
  - **Ambiente**: Indoor / Outdoor / Auto (tarefas outdoor afetadas pelo clima)
  - **Status Kanban**: Planejado | Em Andamento | Feito | Bloqueado
  - **Pontuação**: Q1=100, Q3=75, Q2=50, Q4=25 pts (×1,5 se MIT)
  - **Progresso** (0–100%) com barra visual nos cards Kanban
- [x] Classificação automática de área por palavras-chave (`AreaClassifier`)
- [x] Sincronização bidirecional com Cloud Firestore
- [x] Tarefas de calendário protegidas (não deletáveis; área auto-classificada)

### 📧 Análise de E-mails (aba E-mail em Tarefas)

- [x] Integração com **Gmail REST API v1** (escopo `gmail.readonly`)
- [x] Configuração de **remetentes-alvo** (filtra apenas e-mails de endereços específicos)
- [x] **Janela de análise** configurável: 1 dia / 1 semana / 1 mês / 1 trimestre / 1 semestre / 1 ano
- [x] Análise por **OpenAI GPT-4o-mini** — identifica ações concretas e gera até 8 tarefas priorizadas
- [x] Cada sugestão exibe: quadrante Eisenhower, área de vida, raciocínio da IA e origem no e-mail
- [x] Aceitar sugestão cria a tarefa diretamente; ignorar a descarta sem efeitos

### 🌤️ Previsão do Tempo

- [x] **Open-Meteo API** — totalmente gratuita, sem API key, CORS-friendly
- [x] Busca por nome de cidade (geocodificação automática)
- [x] Exibe temperatura atual, condição (emoji + texto) e forecast dos próximos 3 dias
- [x] **Detecção de tarefas sensíveis ao clima** — palavras-chave: limpeza, solar, pintura, jardinagem, obra, lavagem, telhado, etc.
- [x] Cache local de 30 minutos (evita chamadas repetidas)

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

### 📚 Aprender (7 plataformas)

- [x] **DataCamp** — cursos concluídos, capítulos, XP e curso atual
- [x] **Duolingo** — streak, XP diário/total, nível e idioma ativo
- [x] **Chess.com** — ratings Bullet / Blitz / Rapid via API pública
- [x] **Goodreads** — livros lidos no ano, em leitura, páginas e livro atual
- [x] **NotebookLM** — notebooks, fontes, notas e tópico mais recente
- [x] **MEC Livros** — livros lidos, em leitura e gênero favorito
- [x] **MEC Idiomas** — curso ativo, lições concluídas, total e progresso (%)
- [x] Grid 2-colunas com indicador visual de plataforma ativa
- [x] Modal por plataforma com formulário de atualização manual

### ⚙️ Configurações

- [x] Alternância **Dark / Light theme** (persistida)
- [x] Alternância de idioma **Português / English** (i18n com `AppLocalizations`)
- [x] Configuração da janela de sincronização do Google Agenda
- [x] Configuração da **chave OpenAI** (armazenada apenas localmente via SharedPreferences)
- [x] Reset completo de dados do usuário
- [x] **Seção de informações do app** com versão, tipo de release, timestamp e changelog

### ☁️ Cloud (Firebase)

- [x] Cloud Firestore com estrutura `users/{uid}/{profile|activities|areas|checkIns|achievements|tasks}`
- [x] Dados completamente isolados por `uid`
- [x] Modo local → cloud transparente (sem mudança de UX)

---

## Pré-requisitos de Configuração

### Chave OpenAI (para IA e análise de e-mails)

A chave OpenAI é necessária para duas features:
- **Aba IA** em Tarefas — sugestões de tarefas por GPT-4o-mini
- **Aba E-mail** em Tarefas — análise de e-mails e geração de tarefas

Configure em: **Perfil → Inteligência Artificial → Chave OpenAI**

> A chave é armazenada apenas localmente no dispositivo (SharedPreferences). Nunca é enviada ao repositório.

### Acesso Gmail (para análise de e-mails)

O acesso ao Gmail é solicitado automaticamente no login com Google. O aplicativo usa apenas o escopo `gmail.readonly` — nenhum e-mail é armazenado, apenas o snippet (prévia curta) é enviado ao OpenAI para análise.

---

## Estrutura do Projeto

```
life_balance_tracker/
│
├── .github/
│   └── workflows/
│       └── deploy.yml                   # CI/CD: testes → build → GitHub Pages
│
├── test/
│   ├── models/
│   │   ├── activity_model_test.dart
│   │   ├── area_model_test.dart
│   │   ├── email_model_test.dart        # EmailMessage, EmailAnalysisConfig
│   │   ├── learning_progress_test.dart  # 7 plataformas de aprendizado
│   │   ├── task_model_test.dart
│   │   ├── user_model_test.dart
│   │   └── weather_model_test.dart      # WeatherData, isWeatherSensitiveTask
│   ├── providers/
│   │   ├── activities_provider_test.dart
│   │   ├── areas_provider_test.dart
│   │   └── tasks_provider_test.dart
│   └── reports/
│       ├── tasks_report_filter_test.dart
│       ├── tasks_report_integration_test.dart
│       └── tasks_report_stress_test.dart  # Stress com 500–1000 tarefas
│
└── lib/
    ├── main.dart                          # Entry point + MultiProvider (10 providers)
    ├── app.dart                           # MaterialApp + roteamento + temas
    │
    ├── constants/
    │   └── app_constants.dart             # 10 áreas, XP, níveis, tiers, changelog
    │
    ├── theme/
    │   └── app_theme.dart                 # Dark/light theme + cores das 10 áreas
    │
    ├── l10n/
    │   └── app_l10n.dart                  # Internacionalização PT/EN (inline)
    │
    ├── models/
    │   ├── user_model.dart                # Perfil, XP, tier, nível, streak
    │   ├── area_model.dart                # Área da roda da vida + GoalModel
    │   ├── activity_model.dart            # Log de atividade
    │   ├── checkin_model.dart             # Check-in matinal + noturno
    │   ├── achievement_model.dart         # Conquistas
    │   ├── task_model.dart                # Tarefas: ID timestamp, Eisenhower, Kanban, MIT, ambiente, pontos, progresso
    │   ├── task_suggestion.dart           # Sugestão de tarefa gerada por IA
    │   ├── calendar_event_model.dart      # Evento do Google Calendar
    │   ├── learning_progress.dart         # 7 plataformas (DataCamp, Duolingo, etc.)
    │   ├── weather_model.dart             # WeatherData, WeatherCurrent, WeatherDay
    │   └── email_model.dart               # EmailMessage, EmailAnalysisConfig
    │
    ├── services/
    │   ├── storage_service.dart           # SharedPreferences wrapper (singleton)
    │   ├── firestore_service.dart         # Cloud Firestore CRUD por coleção
    │   ├── auth_service.dart              # Google + LinkedIn OAuth2 PKCE
    │   ├── calendar_service.dart          # Google Calendar REST API v3
    │   ├── weather_service.dart           # Open-Meteo geocoding + forecast
    │   ├── gmail_service.dart             # Gmail REST API v1 (batch fetch)
    │   ├── area_classifier.dart           # Classificação de tarefas por palavras-chave
    │   └── task_id_service.dart           # Geração de IDs timestamp (YYYYMMDDHHMMSSXX)
    │   └── quotes_service.dart            # 150 frases filosóficas (por dia do ano)
    │
    ├── providers/
    │   ├── settings_provider.dart         # Tema, idioma, chave OpenAI
    │   ├── user_provider.dart             # XP, nível, streak, conquistas, auth
    │   ├── areas_provider.dart            # 10 áreas, scores, objetivos
    │   ├── activities_provider.dart       # Atividades, check-ins, heatmap
    │   ├── calendar_provider.dart         # Google Calendar, janela de sync, eventos
    │   ├── ai_agent_provider.dart         # Sugestões de tarefas via OpenAI
    │   ├── learning_provider.dart         # 7 plataformas de aprendizado
    │   ├── weather_provider.dart          # Clima via Open-Meteo (cache 30 min)
    │   ├── gmail_tasks_provider.dart      # Análise Gmail + geração de tarefas IA
    │   └── tasks_provider.dart            # Tarefas, Kanban, Eisenhower, MITs, sync calendário
    │
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── onboarding_screen.dart         # Wizard 3 passos (nome + scores + objetivos)
    │   ├── main_screen.dart               # Bottom nav (5 abas)
    │   ├── dashboard_screen.dart          # Roda da Vida + clima + frase do dia
    │   ├── activities_screen.dart         # Histórico + heatmap
    │   ├── goals_screen.dart              # Objetivos por área
    │   ├── profile_screen.dart            # XP, conquistas, stats, configurações
    │   ├── auth/
    │   │   └── login_screen.dart          # Google + LinkedIn sign-in
    │   ├── logging/
    │   │   ├── add_activity_screen.dart
    │   │   ├── morning_checkin_screen.dart
    │   │   └── evening_checkout_screen.dart
    │   ├── tasks/
    │   │   ├── tasks_screen.dart          # 6 abas: Eisenhower, Kanban, Histórico, Relatórios, IA, E-mail
    │   │   ├── task_create_screen.dart
    │   │   ├── task_detail_sheet.dart
    │   │   ├── ai_agent_screen.dart       # Aba IA: sugestões OpenAI
    │   │   └── email_tasks_tab.dart       # Aba E-mail: análise Gmail + tarefas IA
    │   ├── reports/
    │   │   └── reports_screen.dart        # Relatórios com filtros e métricas
    │   ├── learning/
    │   │   └── learning_tracker_screen.dart  # Grid 7 plataformas + modais
    │   └── calendar/
    │       ├── calendar_screen.dart       # Calendário mensal interativo
    │       └── event_form_screen.dart
    │
    ├── widgets/
    │   ├── life_wheel_chart.dart          # Gráfico radar (CustomPainter)
    │   ├── xp_progress_bar.dart           # Barra de XP animada
    │   ├── area_card.dart                 # Card de área da Roda da Vida
    │   └── app_background.dart            # Background gradiente adaptativo dark/light
    │
    └── firebase_options.dart              # Configuração Firebase (gerada pelo FlutterFire CLI)
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
| Análise de e-mails | Gmail REST API v1 (escopo `gmail.readonly`) |
| Inteligência Artificial | OpenAI GPT-4o-mini (sugestões + análise de e-mails) |
| Previsão do tempo | Open-Meteo API (gratuita, sem API key) |
| Deploy | GitHub Pages via `peaceiris/actions-gh-pages` |
| CI/CD | GitHub Actions (test gate + build + deploy) |
| Testes | `flutter_test` (344 testes unitários/integração/stress) |
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

**344 testes** cobrindo modelos, providers, filtros de relatórios e cenários stress:

| Arquivo | Escopo |
|---|---|
| `test/models/task_model_test.dart` | TaskModel, SubtaskModel |
| `test/models/user_model_test.dart` | UserModel, XP, tiers |
| `test/models/area_model_test.dart` | AreaModel, GoalModel |
| `test/models/activity_model_test.dart` | ActivityModel |
| `test/models/weather_model_test.dart` | WeatherData, isWeatherSensitiveTask |
| `test/models/learning_progress_test.dart` | 7 plataformas de aprendizado |
| `test/models/email_model_test.dart` | EmailMessage, EmailAnalysisConfig |
| `test/providers/tasks_provider_test.dart` | TasksProvider, Eisenhower, MIT, calendar |
| `test/providers/areas_provider_test.dart` | AreasProvider, scores, objetivos |
| `test/providers/activities_provider_test.dart` | ActivitiesProvider, check-ins |
| `test/reports/tasks_report_filter_test.dart` | Filtros de status em Relatórios |
| `test/reports/tasks_report_integration_test.dart` | Fluxos multi-step |
| `test/reports/tasks_report_stress_test.dart` | Stress 500–1000 tarefas |

---

## CI/CD

O pipeline `.github/workflows/deploy.yml` executa em todo push/PR para `main`:

```
push → main
  ├── [1] 🧪 Testes + Análise
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
| `MAJOR` | Alterações de arquitetura (ex: troca de provider, breaking change) |
| `MINOR` | Novas funcionalidades (ex: nova aba, nova integração) |
| `PATCH` | Correções de bugs (ex: crash fix, correção visual) |
| `+BUILD` | Incrementado a cada publicação em `main` |

### Histórico de Versões

| Versão | Tipo | Timestamp | Resumo |
|---|---|---|---|
| `v2.7.0+10` | MINOR | 23/06/2026 18:45 | Campos padronizados: ID timestamp, Ambiente Indoor/Outdoor, Tempo Estimado, Pontuação, Kanban com Bloqueado; Q2/Q3 corrigidos; 344 testes |
| `v2.6.0+9` | MINOR | 23/06/2026 11:58 | Nova aba E-mail: integração Gmail + OpenAI para gerar tarefas; 327 testes |
| `v2.5.0+8` | MINOR | 22/06/2026 22:18 | Previsão do tempo no Dashboard + alertas de tarefas sensíveis ao clima; 7 plataformas de aprendizado; 313 testes |
| `v2.4.0+7` | MINOR | 22/06/2026 03:21 | Aba Aprender com DataCamp, Duolingo e Chess.com; 273 testes |
| `v2.3.0+6` | MINOR | 21/06/2026 01:12 | Assistente IA com OpenAI GPT-4o-mini na aba Tarefas; 256 testes |
| `v2.2.0+5` | MINOR | 03/06/2026 20:13 | Campo Localização via Google Maps; relatórios com filtros funcionais; 244 testes |
| `v2.1.0+3` | MINOR | 03/06/2026 00:33 | Relatórios, edição universal de tarefas e taxa de conclusão por período |
| `v2.0.0+2` | MAJOR | 26/05/2026 20:05 | Sincronização Google Agenda→Tarefas, 134 testes unitários, CI/CD |
| `v1.x` | — | — | Versão inicial (local-only, sem Firebase) |

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

## Roadmap — Próximos Desenvolvimentos

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

- [ ] Análise de sentimento do check-in noturno (reflexão textual)
- [ ] Geração automática de objetivos SMART com base no perfil
- [ ] Resumo semanal gerado por IA com pontos de atenção
- [ ] Análise de e-mails de calendário (Outlook) além do Gmail

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
> A chave OpenAI é armazenada apenas localmente no dispositivo do usuário (SharedPreferences).

---

## Licença

Este projeto é privado. Todos os direitos reservados.
