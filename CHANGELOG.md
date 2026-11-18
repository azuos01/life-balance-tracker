# Changelog

All notable changes to Life Balance Tracker are documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Tag convention:** `V{MAJOR}.{MINOR}.{PATCH}` (capital V, without build number)

---

## [V2.8.0] - 2026-11-18

### Fixed
- **Quadrantes Eisenhower corrigidos para a numeração de Covey** ("7 Hábitos das Pessoas Altamente Eficazes"):
  - Q2 = −Urgente +Importante → **Agende** 🟢 → 75 pts (quadrante estratégico)
  - Q3 = +Urgente −Importante → **Delegue** 🟡 → 50 pts
  - A V2.7.0 havia invertido Q2/Q3; esta versão restaura a convenção correta
- Lógica de Urgente/Importante no formulário de criação de tarefa corrigida (`_eisenhowerQ`)
- Cores dos badges de quadrante consistentes em todas as telas (Q2=verde, Q3=laranja)
- Padrão de novas tarefas e importações de calendário: Q2 (−Urgente +Importante)
- `.claude/settings.local.json` removido do versionamento e adicionado ao `.gitignore`
- Contagem de testes no `CLAUDE.md` corrigida: 273 → 344

### Added
- **Aviso de segurança** na tela de configuração da chave OpenAI: explica que a chave é salva
  no `localStorage` do navegador e enviada diretamente ao servidor da OpenAI (aceitável para
  uso pessoal; em produção, prefira uma Cloud Function como proxy)
- **Guard no login com LinkedIn**: se `YOUR_LINKEDIN_CLIENT_ID` ainda não foi substituído,
  o app exibe uma mensagem clara ao invés de redirecionar para uma URL inválida
- Comentário no código documenta as duas limitações conhecidas do fluxo LinkedIn
  (placeholder de Client ID + restrição de CORS na troca do token via browser)

---

## [V2.7.0] - 2026-06-23

### Added
- Campos padronizados em **todas** as tarefas (novas e importadas):
  - **ID timestamp** no formato `YYYYMMDDHHMMSSXX` via `TaskIdService` (conflitos no mesmo segundo usam sufixo AA, AB, …)
  - **Ambiente** Indoor/Outdoor/Auto — tarefas outdoor recebem alertas de clima no Dashboard
  - **Tempo Estimado** (slider 30 min – 24 h, passo de 30 min)
  - **Pontuação por quadrante**: Q1 = 100 pts, Q3 = 75 pts, Q2 = 50 pts, Q4 = 25 pts (×1,5 se MIT)
  - **Barra de progresso manual** nos cards Kanban (0–100 %)
- Coluna **Bloqueado** no Kanban (4ª coluna, scroll horizontal)
- `AreaClassifier` integrado ao `syncCalendarTasks()` para classificar área automaticamente em importações de calendário
- 344 testes automatizados (unitários, integração e stress)

### Changed
- Quadrantes Eisenhower redefinidos corretamente:
  - **Q2 = +Urgente −Importante → Delegue 🟡** (antes era Agende)
  - **Q3 = −Urgente +Importante → Agende 🟢** (antes era Delegue)
- Dashboard usa `task.isOutdoor` para detectar tarefas sensíveis ao clima (antes usava palavras-chave)
- Tarefa de calendário criada com Q3 (Agende) como padrão (antes Q2)

### Fixed
- Labels Q2/Q3 corrigidos em todos os arquivos: modelos, telas, prompts de IA e testes
- `task.progress` → `task.subtaskProgress` / `task.progressPercent` (getter renomeado)
- `task.totalEstimatedHours` → `task.estimatedHours` (campo nullable)

---

## [V2.6.0] - 2026-06-23

### Added
- **Aba E-mail** na tela de Tarefas
- Integração Gmail via OAuth2 (`gmail.readonly`) + análise por OpenAI GPT-4o-mini
- Configuração de remetentes monitorados e janela de tempo (1 dia a 1 ano)
- Geração automática de tarefas priorizadas por Eisenhower a partir de e-mails
- 327 testes automatizados

### Dependencies
- Novo escopo OAuth: `https://www.googleapis.com/auth/gmail.readonly`
- Novos arquivos: `email_model.dart`, `gmail_service.dart`, `gmail_tasks_provider.dart`, `email_tasks_tab.dart`

---

## [V2.5.0] - 2026-06-22

### Added
- **Previsão do tempo** no Dashboard via [Open-Meteo](https://open-meteo.com/) (sem API key, CORS-friendly)
- Alertas automáticos para tarefas sensíveis ao clima (detectadas por palavras-chave nesta versão)
- Aba **Aprender** expandida com 4 novas plataformas:
  - Goodreads, NotebookLM, MEC Livros, MEC Idiomas
- 313 testes automatizados

---

## [V2.4.0] - 2026-06-22

### Added
- Aba **Aprender** com tracking de 3 plataformas de aprendizado:
  - **DataCamp** — cursos e capítulos concluídos
  - **Duolingo** — streak diário e XP
  - **Chess.com** — ratings via API pública
- 273 testes automatizados

---

## [V2.3.0] - 2026-06-21

### Added
- **Assistente IA** com OpenAI GPT-4o-mini na aba Tarefas
- Sugestões de tarefas priorizadas por Eisenhower/MIT com base no perfil de vida do usuário
- Configuração de chave OpenAI em Configurações (armazenada localmente via SharedPreferences)
- 256 testes automatizados

---

## [V2.2.0] - 2026-06-03

### Added
- Campo **Localização** com integração Google Maps em todas as tarefas
- 244 testes automatizados

### Fixed
- Filtros de status na aba Relatórios garantidamente funcionais

---

## [V2.1.1] - 2026-06-03

### Fixed
- Bug de toque nos filtros de status da aba Relatórios

---

## [V2.1.0] - 2026-06-03

### Added
- **Aba Relatórios** com filtros por status, gráficos e taxa de conclusão por período
- Edição universal de tarefas (qualquer campo editável após criação)
- Protocolo de versionamento documentado em `CLAUDE.md`

### Fixed
- Filtros de relatório corrigidos
- Warnings de `unused_local_variable` que bloqueavam o CI/CD

---

## [V2.0.0] - 2026-05-26

### Added
- **Sincronização Google Agenda → Tarefas** (Eisenhower + Kanban)
- 134 testes unitários e de integração
- Pipeline CI/CD com gate de qualidade (`flutter analyze` + `flutter test`) via GitHub Actions
- Deploy automático para GitHub Pages

### Changed
- Arquitetura migrada para suportar `ChangeNotifierProxyProvider2` (CalendarProvider → TasksProvider)

---

## [V1.0.0] - 2026-05 (MVP inicial)

### Added
- Dashboard com 10 áreas de vida, gamificação (XP, nível, streak) e frase diária
- **Aba Tarefas**: Matriz de Eisenhower, Kanban (3 colunas), Tarefas MIT (máx. 3/dia), subtarefas
- **Aba Atividades**: check-ins, histórico e streaks
- **Aba Metas**: objetivos por área de vida
- **Aba Calendário**: integração Google Calendar
- Autenticação social: Google e LinkedIn (OAuth2 PKCE)
- Backend Cloud Firestore para persistência de dados por usuário
- Suporte web Flutter com deploy em GitHub Pages
- Tema claro/escuro + suporte PT/EN
- Design com fundo animado e glassmorphism

---

## Links

- Repositório: https://github.com/azuos01/life-balance-tracker
- Deploy: https://azuos01.github.io/life-balance-tracker/
