# Life Balance Tracker — Instruções para o Claude Code

Este arquivo é lido automaticamente pelo Claude Code no início de cada sessão.
As regras aqui definidas têm prioridade sobre qualquer instrução genérica.

---

## Visão Geral do Projeto

| Item | Detalhe |
|---|---|
| **Framework** | Flutter 3.x / Dart 3.x (web) |
| **Deploy** | GitHub Pages → https://azuos01.github.io/life-balance-tracker/ |
| **CI/CD** | `.github/workflows/deploy.yml` — test gate → build → deploy |
| **State** | Provider (`ChangeNotifier`, `ProxyProvider2`) |
| **Auth** | Firebase Auth (Google + LinkedIn OAuth2 PKCE) |
| **DB Cloud** | Cloud Firestore (`users/{uid}/...`) |
| **Testes** | `flutter_test` — 273 testes unitários/integração/stress |

---

## ⚠️ Protocolo de Versionamento — OBRIGATÓRIO

**Toda vez que Claude alterar código funcional (feature, fix ou refatoração),
ele DEVE atualizar os arquivos de versão ANTES de fazer o commit.**

### Critérios de bump

| Dígito | Condição | Exemplos |
|---|---|---|
| **MAJOR** (X.0.0) | Arquitetura: troca de provider, nova camada, breaking change | Migrar Provider→Riverpod, refatorar todo o sistema de auth |
| **MINOR** (x.Y.0) | Nova funcionalidade, nova tela, nova integração, melhoria visível | Nova aba, novo filtro, sincronização com API externa |
| **PATCH** (x.y.Z) | Correção de bug, fix de CI, correção visual | Filtro quebrado, crash fix, import circular |
| **+BUILD** (+N) | Todo commit publicado em `main` | Incrementar sempre, sem exceção |

**Regra de prioridade:** se o commit misturar tipos, usar o dígito mais alto.
Exemplo: fix + nova feature → bump MINOR (não PATCH).

### Arquivos que DEVEM ser atualizados a cada release

#### 1. `pubspec.yaml` — versão do pacote Flutter

```yaml
version: X.Y.Z+N   # ex: 2.1.0+3
```

#### 2. `lib/constants/app_constants.dart` — 5 constantes obrigatórias

```dart
const String kAppVersion        = 'X.Y.Z';            // ex: '2.1.0'
const String kLastChangeVersion = 'vX.Y.Z';           // ex: 'v2.1.0'
const String kLastChangeDate    = 'DD/MM/YYYY HH:mm'; // ex: '23/06/2026 14:30'  (timestamp completo)
const String kLastChangeType    = 'TIPO';             // 'MAJOR' | 'MINOR' | 'PATCH'
const String kLastChangeSummary = '...';              // Máx. 3 frases descrevendo o que mudou
```

#### Exemplo completo de atualização

Antes de commitar uma sessão que adicionou uma nova tela e corrigiu um bug:

```dart
// pubspec.yaml
version: 2.2.0+4          // era 2.1.0+3 → MINOR (nova tela) + incremento BUILD

// app_constants.dart
const String kAppVersion        = '2.2.0';
const String kLastChangeVersion = 'v2.2.0';
const String kLastChangeDate    = '15/07/2026 10:30';
const String kLastChangeType    = 'MINOR';
const String kLastChangeSummary =
    'Nova tela de Configurações com exportação de dados em CSV. '
    'Correção do crash ao abrir tarefa sem área associada.';
```

### Resumo do `kLastChangeSummary`

- Máximo de **3 frases curtas**
- Listar as funcionalidades/fixes mais importantes
- Usar linguagem objetiva em português
- Não mencionar detalhes técnicos internos (nomes de classe, arquivos)

---

## Histórico de Versões

| Versão | Tipo | Timestamp | Resumo |
|---|---|---|---|
| `v2.6.0+9` | MINOR | 23/06/2026 11:58 | Nova aba E-mail em Tarefas: integração Gmail (OAuth2 gmail.readonly) + OpenAI GPT-4o-mini para gerar tarefas priorizadas por Eisenhower; configuração de remetentes e janela de 1 dia a 1 ano; 327 testes, CI/CD verde |
| `v2.5.0+8` | MINOR | 22/06/2026 22:18 | Previsão do tempo no Dashboard (Open-Meteo, sem API key) + alertas de tarefas sensíveis ao clima; aba Aprender expandida com Goodreads, NotebookLM, MEC Livros e MEC Idiomas; 313 testes, CI/CD verde |
| `v2.4.0+7` | MINOR | 22/06/2026 03:21 | Nova aba Aprender: tracking de DataCamp (cursos/capítulos), Duolingo (streak/XP) e Chess.com (ratings via API); 273 testes, CI/CD verde |
| `v2.3.0+6` | MINOR | 21/06/2026 01:12 | Assistente IA com OpenAI GPT-4o-mini na aba Tarefas: sugere tarefas priorizadas por Eisenhower/MIT com base no perfil de vida; 256 testes, CI/CD verde |
| `v2.2.0+5` | MINOR | 03/06/2026 20:13 | Campo Localização (Google Maps) em todas as tarefas; filtros de status na aba Relatórios garantidamente funcionais; 244 testes, CI/CD verde |
| `v2.1.0+3` | MINOR | 03/06/2026 00:33 | Relatórios com filtros corrigidos, edição universal de tarefas e taxa de conclusão por período |
| `v2.0.0+2` | MAJOR | 26/05/2026 20:05 | Sincronização Google Agenda→Tarefas, 134 testes unitários, CI/CD com gate de qualidade |
| `v1.x` | — | — | Versão inicial (local-only, sem Firebase) |

---

## Arquitetura — Referência Rápida

### Providers (ordem em `main.dart`)

```
SettingsProvider          → tema + idioma
UserProvider              → XP, nível, streak, auth
AreasProvider             → 10 áreas + scores + objetivos
ActivitiesProvider        → atividades + check-ins
CalendarProvider          → Google Calendar (deve vir ANTES de TasksProvider)
TasksProvider             → Eisenhower + Kanban + MIT + sync calendário
```

> ⚠️ `CalendarProvider` **precisa** ser declarado antes de `TasksProvider` no
> `MultiProvider` (dependência do `ChangeNotifierProxyProvider2`).

### Convenções de ID

| Prefixo | Significado |
|---|---|
| `cal_` | Tarefa originada do Google Calendar (`isFromCalendar: true`) |
| Sem prefixo | Tarefa manual do usuário |

### Tarefas de Calendário

- **Não persistidas** no Firestore — reconstruídas a cada `syncCalendarTasks()`
- **Estado mutável** salvo em `_calendarOverrides` (SharedPreferences)
- **Campos sobreponíveis**: `eisenhowerQ`, `isMIT`, `mitOrder`, `status`, `completedAt`
- **`deleteTask('cal_...')`** é no-op — a tarefa não pode ser excluída

---

## Política de Testes — OBRIGATÓRIA

Toda nova feature ou método público deve ter testes **antes do commit**.

| Tipo | Localização | Quando criar |
|---|---|---|
| **Unitário** | `test/models/` e `test/providers/` | Todo método público novo |
| **Integração** | `test/reports/` ou subpasta relevante | Fluxos multi-step (add→complete→check stats) |
| **Stress** | `test/reports/tasks_report_stress_test.dart` | Operações com datasets grandes (≥100 itens) |

```bash
# Rodar todos os testes antes de commitar
flutter test --reporter=expanded

# Checar se o analyze está limpo (exit 0 obrigatório para CI passar)
flutter analyze --no-fatal-infos
```

---

## CI/CD — Regras

O pipeline (`.github/workflows/deploy.yml`) **falha** se:
- `flutter analyze --no-fatal-infos` retornar `exit code 1` (warning ou error)
- Qualquer teste falhar

**Warnings que bloqueiam CI:** `unused_local_variable`, `unused_import`.
Infos (`prefer_const`, `withOpacity deprecated`) são toleradas.

---

## Segurança

> ⚠️ O **Client Secret do LinkedIn** vai APENAS no Firebase Console.
> Nunca em código, nunca em repositório.
> A Firebase API Key é pública (restrita por domínio).

---

## Documentação — README.md

O `README.md` deve ser atualizado **sempre que houver mudança significativa** na estrutura do software ou no design do aplicativo.

### Quando atualizar o README

| Situação | Exemplos |
|---|---|
| **Nova tela ou aba** | Adicionar aba IA, nova tela de Relatórios |
| **Nova integração externa** | OpenAI, Google Maps, LinkedIn OAuth |
| **Mudança de arquitetura** | Novo provider, nova camada de serviço |
| **Mudança na navegação principal** | Item adicionado/removido do bottom nav |
| **Novo modelo de dados** | Campo importante adicionado a `TaskModel` |
| **Requisito de configuração do usuário** | Chave de API que o usuário precisa obter |

### O que manter atualizado

- **Funcionalidades implementadas (MVP)** — lista das features ativas
- **Estrutura de pastas** — quando arquivos/diretórios são adicionados
- **Pré-requisitos e configuração** — ex: chave OpenAI, Firebase
- **Histórico de versões** — espelhar a tabela do CLAUDE.md
- **Roadmap** — remover itens concluídos, adicionar novos

> Mudanças apenas internas (refatoração, fix de bug, ajuste visual) **não exigem** atualização do README.

---

## Checklist de Release

Antes de cada `git push origin main`, verificar:

- [ ] `pubspec.yaml` — `version:` atualizada
- [ ] `app_constants.dart` — `kAppVersion`, `kLastChange*` atualizados
- [ ] `README.md` — atualizado se houve mudança estrutural ou de design
- [ ] Testes passando: `flutter test`
- [ ] Analyze limpo: `flutter analyze --no-fatal-infos` → exit 0
- [ ] Sem `unused_local_variable` ou `unused_import`
- [ ] Commit message segue convenção: `tipo(escopo): descrição`
