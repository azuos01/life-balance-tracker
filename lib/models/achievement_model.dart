class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;
  DateTime? unlockedAt;

  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  AchievementModel withUnlock(DateTime? date) {
    return AchievementModel(
      id: id,
      name: name,
      description: description,
      icon: icon,
      xpReward: xpReward,
      unlockedAt: date,
    );
  }
}

final List<AchievementModel> kAchievements = [
  AchievementModel(
    id: 'first_step',
    name: 'Primeiro Passo',
    description: 'Logou sua primeira atividade',
    icon: '👣',
    xpReward: 50,
  ),
  AchievementModel(
    id: 'week_streak',
    name: 'Semana Completa',
    description: '7 dias consecutivos de check-in',
    icon: '🔥',
    xpReward: 200,
  ),
  AchievementModel(
    id: 'month_iron',
    name: 'Mês de Ferro',
    description: '30 dias consecutivos',
    icon: '🏆',
    xpReward: 1000,
  ),
  AchievementModel(
    id: 'equilibrist',
    name: 'Equilibrista',
    description: 'Atividade em todas as 10 áreas na semana',
    icon: '⚖️',
    xpReward: 300,
  ),
  AchievementModel(
    id: 'metamorphosis',
    name: 'Metamorfose',
    description: 'Aumentou 2 pontos na Roda da Vida',
    icon: '🦋',
    xpReward: 500,
  ),
  AchievementModel(
    id: 'level_10',
    name: 'Veterano',
    description: 'Alcançou o nível 10',
    icon: '⭐',
    xpReward: 100,
  ),
  AchievementModel(
    id: 'reflective',
    name: 'Reflexivo',
    description: 'Completou 10 check-ins noturnos',
    icon: '🌙',
    xpReward: 150,
  ),
  AchievementModel(
    id: 'goal_crusher',
    name: 'Destruidor de Metas',
    description: 'Completou seu primeiro objetivo',
    icon: '🎯',
    xpReward: 500,
  ),
];
