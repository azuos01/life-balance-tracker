import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Strings de internacionalização — pt (padrão) e en.
/// Acesso: `context.l10n.someString`
class L10n {
  final bool _en;
  L10n._(this._en);

  static L10n of(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;
    return L10n._(locale == 'en');
  }

  // ── Navegação ──────────────────────────────────────────────────────────────
  String get navHome       => _en ? 'Home'       : 'Início';
  String get navTasks      => _en ? 'Tasks'      : 'Tarefas';
  String get navActivities => _en ? 'Activities' : 'Atividades';
  String get navGoals      => _en ? 'Goals'      : 'Objetivos';
  String get navCalendar   => _en ? 'Calendar'   : 'Agenda';
  String get navProfile    => _en ? 'Profile'    : 'Perfil';

  // ── Botões comuns ──────────────────────────────────────────────────────────
  String get save     => _en ? 'Save'     : 'Salvar';
  String get cancel   => _en ? 'Cancel'   : 'Cancelar';
  String get delete   => _en ? 'Delete'   : 'Excluir';
  String get close    => _en ? 'Close'    : 'Fechar';
  String get back     => _en ? 'Back'     : 'Voltar';
  String get confirm  => _en ? 'Confirm'  : 'Confirmar';
  String get next     => _en ? 'Continue' : 'Continuar';
  String get finish   => _en ? 'Start Journey 🚀' : 'Começar Jornada 🚀';
  String get optional => _en ? 'Optional' : 'Opcional';

  // ── Configurações ──────────────────────────────────────────────────────────
  String get settings       => _en ? 'Settings'      : 'Configurações';
  String get appearance     => _en ? 'Appearance'    : 'Aparência';
  String get theme          => _en ? 'Theme'         : 'Tema';
  String get themeDark      => _en ? 'Dark'          : 'Escuro';
  String get themeLight     => _en ? 'Light'         : 'Claro';
  String get language       => _en ? 'Language'      : 'Idioma';
  String get account        => _en ? 'Account'       : 'Conta';
  String get signOut        => _en ? 'Sign out'      : 'Sair da conta';
  String get resetData      => _en ? 'Reset data'    : 'Resetar dados';
  String get connectedVia   => _en ? 'Connected via' : 'Conectado via';
  String get appInfoSection => _en ? 'App Info'      : 'Informações';
  String get resetTitle     => _en ? 'Reset data?'   : 'Resetar dados?';
  String get resetBody      => _en
      ? 'All data will be permanently deleted.'
      : 'Todos os dados serão apagados permanentemente.';

  // ── Perfil ─────────────────────────────────────────────────────────────────
  String get profile      => _en ? 'Profile'      : 'Perfil';
  String get achievements => _en ? 'Achievements' : 'Conquistas';
  String get activities   => _en ? 'Activities'   : 'Atividades';
  String get totalXP      => _en ? 'Total XP'     : 'XP Total';
  String get record       => _en ? 'Record'       : 'Recorde';
  String get days         => _en ? 'days'         : 'dias';
  String get level        => _en ? 'Level'        : 'Nível';

  // ── Dashboard ──────────────────────────────────────────────────────────────
  String greeting(String name) => _en ? 'Hello, $name!' : 'Olá, $name!';
  String get dailyReflection  => _en ? 'Daily Reflection'   : 'Reflexão do Dia';
  String get morningCheckin   => _en ? 'Morning Check-in'   : 'Check-in Matinal';
  String get eveningCheckout  => _en ? 'Evening Check-out'  : 'Check-out Noturno';
  String get myMITs           => _en ? 'My MITs'            : 'Minhas MITs';
  String get lifeWheel        => _en ? 'Life Wheel'         : 'Roda da Vida';
  String get lifeAreas        => _en ? 'Life Areas'         : 'Áreas da Vida';
  String get viewAll          => _en ? 'View all'           : 'Ver todas';
  String get noMIT            => _en ? 'No MITs for today'  : 'Nenhuma MIT para hoje';
  String get addMIT           => _en ? 'Add MIT'            : 'Adicionar MIT';
  String get done             => _en ? 'done'               : 'concluída';

  // ── Agenda / Calendário ────────────────────────────────────────────────────
  String get calendarTitle      => _en ? 'Calendar'                  : 'Agenda';
  String get newEvent           => _en ? 'New event'                 : 'Novo compromisso';
  String get editEvent          => _en ? 'Edit event'                : 'Editar compromisso';
  String get noEvents           => _en ? 'No events'                 : 'Nenhum compromisso';
  String get allDay             => _en ? 'All day'                   : 'Dia inteiro';
  String get authorizeCalendar  => _en ? 'Authorize access'          : 'Autorizar acesso';
  String get connectCalendar    => _en ? 'Connect Google Calendar'   : 'Conectar Google Calendar';
  String get googleRequired     => _en ? 'Google login required'     : 'Login com Google necessário';
  String get refresh            => _en ? 'Refresh'                   : 'Atualizar';
  String get startTime          => _en ? 'Start'                     : 'Início';
  String get endTime            => _en ? 'End'                       : 'Término';
  String get location           => _en ? 'Location (optional)'       : 'Local (opcional)';
  String get description        => _en ? 'Description (optional)'    : 'Descrição (opcional)';
  String get saveChanges        => _en ? 'Save changes'              : 'Salvar alterações';
  String get createEvent        => _en ? 'Create event'              : 'Criar compromisso';
  String get deleteEvent        => _en ? 'Delete event?'             : 'Excluir compromisso?';
  String get irreversible       => _en ? 'This action cannot be undone.' : 'Esta ação não pode ser desfeita.';

  // ── Tarefas ────────────────────────────────────────────────────────────────
  String get tasksTitle   => _en ? 'Tasks'     : 'Tarefas';
  String get newTask      => _en ? 'New task'  : 'Nova tarefa';
  String get eisenhower   => _en ? 'Eisenhower': 'Eisenhower';
  String get kanban       => _en ? 'Kanban'    : 'Kanban';
  String get history      => _en ? 'History'   : 'Histórico';

  // ── Relatórios ─────────────────────────────────────────────────────────────
  String get reports          => _en ? 'Reports'           : 'Relatórios';
  String get reportsTitle     => _en ? 'Task Report'       : 'Relatório de Tarefas';
  String get allTasks         => _en ? 'All'               : 'Todas';
  String get toDo             => _en ? 'To Do'             : 'A Fazer';
  String get inProgressLabel  => _en ? 'In Progress'       : 'Em Andamento';
  String get completedLabel   => _en ? 'Completed'         : 'Concluídas';
  String get completionRateLbl=> _en ? 'Completion Rate'   : 'Taxa de Conclusão';
  String get byArea           => _en ? 'By Area'           : 'Por Área';
  String get byQuadrant       => _en ? 'By Quadrant'       : 'Por Quadrante';
  String get thisWeek         => _en ? 'This Week'         : 'Esta Semana';
  String get avgTimeLbl       => _en ? 'Avg. completion'   : 'Tempo médio';
  String get noTasksFound     => _en ? 'No tasks found for this filter.' : 'Nenhuma tarefa encontrada para este filtro.';
  String get originLabel      => _en ? 'Origin'            : 'Origem';
  String get userTasksLabel   => _en ? 'Manual'            : 'Manual';
  String get calendarTasksLbl => _en ? 'Calendar'          : 'Agenda';

  // ── Onboarding ─────────────────────────────────────────────────────────────
  String get welcomeTo     => _en ? 'Welcome to'                  : 'Bem-vindo ao';
  String get nameQuestion  => _en ? 'What should we call you?'   : 'Como você quer ser chamado?';
  String get namePlaceholder => _en ? 'Your name'                : 'Seu nome';
  String get howAreas      => _en
      ? 'How is each area of your life? (1 = terrible, 10 = excellent)'
      : 'Avalie sua satisfação atual em cada área (1 = péssimo, 10 = excelente)';
  String get defineGoals   => _en ? 'Define your goals'          : 'Defina seus objetivos';
  String get goalsHint     => _en
      ? 'Optional — add one main goal per area. You can edit later.'
      : 'Opcional — adicione um objetivo principal por área. Você pode editar depois.';
}

extension L10nX on BuildContext {
  L10n get l10n => L10n.of(this);
}
