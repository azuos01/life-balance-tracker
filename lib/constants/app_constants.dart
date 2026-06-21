class AreaConfig {
  final String id;
  final String name;
  final String icon;
  final String description;

  const AreaConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

const List<AreaConfig> kAreas = [
  AreaConfig(
    id: 'health_physical',
    name: 'Saúde Física',
    icon: '💪',
    description: 'Exercício, alimentação, sono e energia corporal',
  ),
  AreaConfig(
    id: 'health_mental',
    name: 'Saúde Mental',
    icon: '🧠',
    description: 'Equilíbrio emocional, gestão do estresse e bem-estar',
  ),
  AreaConfig(
    id: 'career',
    name: 'Carreira e Propósito',
    icon: '🚀',
    description: 'Trabalho, missão profissional e realização',
  ),
  AreaConfig(
    id: 'finances',
    name: 'Finanças Pessoais',
    icon: '💰',
    description: 'Renda, investimentos, dívidas e liberdade financeira',
  ),
  AreaConfig(
    id: 'relationships',
    name: 'Relacionamentos Íntimos',
    icon: '❤️',
    description: 'Parceiro(a), amor, cumplicidade e conexão',
  ),
  AreaConfig(
    id: 'family',
    name: 'Família e Amizades',
    icon: '👨‍👩‍👧',
    description: 'Laços familiares, amizades e rede de apoio',
  ),
  AreaConfig(
    id: 'intellectual',
    name: 'Desenvolvimento Intelectual',
    icon: '📚',
    description: 'Aprendizado, leitura, habilidades e crescimento',
  ),
  AreaConfig(
    id: 'spirituality',
    name: 'Espiritualidade e Propósito',
    icon: '🌟',
    description: 'Fé, meditação, sentido e conexão com algo maior',
  ),
  AreaConfig(
    id: 'leisure',
    name: 'Lazer e Criatividade',
    icon: '🎨',
    description: 'Hobbies, diversão, arte e descanso criativo',
  ),
  AreaConfig(
    id: 'contribution',
    name: 'Contribuição e Legado',
    icon: '🌍',
    description: 'Impacto social, voluntariado e deixar um legado',
  ),
];

// App identity
const String kAppName = 'Life Balance Tracker';
const String kAppVersion = '2.3.0';
const String kAppTagline = 'Monitore e melhore as 10 áreas\nfundamentais da sua vida.';

// ── Changelog da última versão ────────────────────────────────────────────────
// ⚠️  Estes campos são atualizados automaticamente pelo protocolo de versionamento
//     descrito em CLAUDE.md. Não edite manualmente fora do fluxo de release.
const String kLastChangeVersion = 'v2.3.0';
const String kLastChangeDate    = 'Jun 2026';
const String kLastChangeType    = 'MINOR';   // MAJOR | MINOR | PATCH
const String kLastChangeSummary =
    'Assistente IA integrado à aba Tarefas: sugere tarefas priorizadas por '
    'Eisenhower com base no perfil de vida do usuário via OpenAI GPT-4o-mini. '
    'Chave API configurável nas Configurações. 256 testes, CI/CD verde.';

// XP rewards
const int kXpEasy = 10;
const int kXpMedium = 25;
const int kXpHard = 50;
const int kXpHabit = 15;
const int kXpStreakBonus = 100;
const int kXpObjective = 500;
const int kXpCheckIn = 20;

// Level thresholds
const List<Map<String, dynamic>> kLevels = [
  {'min': 0, 'max': 1000, 'tier': 'Iniciante', 'levels': [1, 10]},
  {'min': 1001, 'max': 5000, 'tier': 'Praticante', 'levels': [11, 25]},
  {'min': 5001, 'max': 15000, 'tier': 'Guerreiro', 'levels': [26, 50]},
  {'min': 15001, 'max': 35000, 'tier': 'Mestre', 'levels': [51, 75]},
  {'min': 35001, 'max': 999999, 'tier': 'Lenda', 'levels': [76, 100]},
];

String tierFromXP(int xp) {
  if (xp <= 1000) return 'Iniciante';
  if (xp <= 5000) return 'Praticante';
  if (xp <= 15000) return 'Guerreiro';
  if (xp <= 35000) return 'Mestre';
  return 'Lenda';
}

int levelFromXP(int xp) {
  if (xp <= 1000) return ((xp / 100).floor() + 1).clamp(1, 10);
  if (xp <= 5000) return (((xp - 1000) / 267).floor() + 11).clamp(11, 25);
  if (xp <= 15000) return (((xp - 5000) / 400).floor() + 26).clamp(26, 50);
  if (xp <= 35000) return (((xp - 15000) / 800).floor() + 51).clamp(51, 75);
  return (((xp - 35000) / 1600).floor() + 76).clamp(76, 100);
}

int xpForNextLevel(int currentXP) {
  final level = levelFromXP(currentXP);
  if (level < 10) return (level * 100);
  if (level < 25) return 1000 + ((level - 10) * 267);
  if (level < 50) return 5000 + ((level - 25) * 400);
  if (level < 75) return 15000 + ((level - 50) * 800);
  return 35000 + ((level - 75) * 1600);
}
