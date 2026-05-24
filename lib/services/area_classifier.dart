import '../constants/app_constants.dart';

/// Classifica automaticamente uma tarefa em uma das 10 áreas da Roda da Vida
/// com base em palavras-chave presentes no título/descrição.
///
/// Usa um sistema de pontuação: a área com mais matches de keywords vence.
/// Se nenhuma keyword corresponder, retorna 'career' como padrão.
class AreaClassifier {
  AreaClassifier._();
  static final AreaClassifier instance = AreaClassifier._();

  static const Map<String, List<String>> _keywords = {
    'health_physical': [
      'academia', 'treino', 'exercício', 'exercicios', 'correr', 'corrida',
      'natação', 'natacao', 'musculação', 'musculacao', 'dieta', 'alimentação',
      'alimentacao', 'dormir', 'sono', 'médico', 'medico', 'saúde', 'saude',
      'fisio', 'fisioterapia', 'personal', 'ginástica', 'ginastica', 'caminhada',
      'ciclismo', 'bike', 'bicicleta', 'alongamento', 'yoga', 'pilates',
      'dor', 'remédio', 'remedio', 'exame', 'consulta', 'nutrição', 'nutricao',
      'emagrecer', 'peso', 'calorias', 'proteína', 'proteina', 'hidratação',
      'hidratacao', 'suplemento', 'crossfit', 'funcional', 'cardio',
    ],
    'health_mental': [
      'terapia', 'ansiedade', 'estresse', 'stress', 'meditação', 'meditacao',
      'mindfulness', 'psicólogo', 'psicologo', 'psiquiatra', 'mental',
      'emoção', 'emocao', 'relaxar', 'respiração', 'respiracao', 'burnout',
      'depressão', 'depressao', 'humor', 'paz', 'calma', 'autocuidado',
      'autoconhecimento', 'equilíbrio', 'equilibrio', 'bem-estar',
    ],
    'career': [
      'trabalho', 'projeto', 'reunião', 'reuniao', 'apresentação', 'apresentacao',
      'relatório', 'relatorio', 'chefe', 'cliente', 'entrega', 'deadline',
      'sprint', 'código', 'codigo', 'programação', 'programacao', 'marketing',
      'vendas', 'proposta', 'contrato', 'meeting', 'standup', 'deploy',
      'empresa', 'negócio', 'negocio', 'profissional', 'cargo', 'promoção',
      'promocao', 'startup', 'produto', 'feature', 'backlog', 'task',
      'liderança', 'lideranca', 'gestão', 'gestao', 'processo', 'meta',
      'resultado', 'performance', 'feedback', 'entrevista', 'currículo', 'curriculo',
    ],
    'finances': [
      'banco', 'investimento', 'investir', 'dívida', 'divida', 'conta',
      'financiamento', 'imposto', 'ir', 'declaração', 'declaracao', 'orçamento',
      'orcamento', 'poupança', 'poupanca', 'ação', 'acao', 'cripto', 'bitcoin',
      'seguro', 'cartão', 'cartao', 'crédito', 'credito', 'financeiro',
      'dinheiro', 'renda', 'salário', 'salario', 'aposentadoria', 'previdência',
      'previdencia', 'tesouro', 'fundo', 'bolsa', 'dividendo', 'juros',
      'financiar', 'empréstimo', 'emprestimo', 'pagar', 'receber', 'cobrar',
    ],
    'relationships': [
      'namorado', 'namorada', 'esposo', 'esposa', 'marido', 'parceiro',
      'parceira', 'casal', 'relacionamento', 'encontro', 'date', 'amor',
      'romance', 'namoro', 'casamento', 'noivo', 'noiva', 'sexo', 'intimidade',
      'presente', 'surpresa', 'jantar', 'viagem a dois', 'reconciliação',
    ],
    'family': [
      'família', 'familia', 'pai', 'mãe', 'mae', 'filho', 'filha', 'irmão',
      'irmao', 'irmã', 'irma', 'avô', 'avó', 'avo', 'parentes', 'familiar',
      'aniversário', 'aniversario', 'natal', 'páscoa', 'pascoa', 'amigos',
      'amigo', 'amiga', 'social', 'confraternização', 'confraternizacao',
      'churrasco', 'almoço família', 'visitar', 'ligar para',
    ],
    'intellectual': [
      'livro', 'ler', 'leitura', 'curso', 'estudar', 'estudo', 'aprender',
      'aprendizado', 'aula', 'pesquisa', 'artigo', 'podcast', 'palestra',
      'graduação', 'graduacao', 'faculdade', 'mba', 'certificação', 'certificacao',
      'workshop', 'treinamento', 'habilidade', 'idioma', 'inglês', 'ingles',
      'espanhol', 'concurso', 'prova', 'resenha', 'resumo', 'anotação',
      'anotacao', 'flashcard', 'anki', 'video aula', 'tutorial',
    ],
    'spirituality': [
      'oração', 'oracao', 'rezar', 'missa', 'templo', 'espiritual', 'fé', 'fe',
      'gratidão', 'gratidao', 'propósito', 'proposito', 'ioga', 'budismo',
      'buda', 'diário', 'diario', 'agradecer', 'benção', 'bencao', 'devocional',
      'religião', 'religiao', 'deus', 'universo', 'retiro', 'silêncio',
      'silencio', 'contemplação', 'contemplacao', 'natureza', 'conexão interior',
    ],
    'leisure': [
      'hobby', 'hobbies', 'viagem', 'viajar', 'filme', 'série', 'serie',
      'jogo', 'jogar', 'game', 'arte', 'música', 'musica', 'restaurante',
      'passeio', 'lazer', 'férias', 'ferias', 'descansar', 'parque', 'praia',
      'show', 'teatro', 'cinema', 'concerto', 'festival', 'diversão', 'diversao',
      'fotografia', 'pintura', 'escultura', 'cozinhar', 'cozinha', 'receita',
      'trilha', 'acampamento', 'camping', 'pesca', 'surf', 'dança', 'danca',
    ],
    'contribution': [
      'voluntário', 'voluntario', 'doação', 'doacao', 'ong', 'comunidade',
      'projeto social', 'impacto', 'legado', 'ajudar', 'solidariedade',
      'caridade', 'filantropia', 'sustentabilidade', 'meio ambiente', 'ambiental',
      'clima', 'reciclagem', 'mentoria', 'mentorar', 'ensinar', 'compartilhar',
    ],
  };

  /// Classifica o texto e retorna o ID da área com maior pontuação.
  /// Considera tanto o título quanto a descrição da tarefa.
  String classify(String title, [String description = '']) {
    final combined = '${title.toLowerCase()} ${description.toLowerCase()}';
    final words = combined
        .split(RegExp(r'[\s,;.!?()]+'))
        .where((w) => w.length > 2)
        .toList();

    final scores = <String, int>{};
    for (final area in kAreas) {
      final keywords = _keywords[area.id] ?? [];
      int score = 0;
      for (final word in words) {
        for (final kw in keywords) {
          if (word.contains(kw) || kw.contains(word)) {
            score++;
          }
        }
      }
      if (score > 0) scores[area.id] = score;
    }

    if (scores.isEmpty) return 'career'; // padrão

    return scores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Retorna as top-3 sugestões de áreas com suas pontuações
  List<_AreaScore> topSuggestions(String title, [String description = '']) {
    final combined = '${title.toLowerCase()} ${description.toLowerCase()}';
    final words = combined
        .split(RegExp(r'[\s,;.!?()]+'))
        .where((w) => w.length > 2)
        .toList();

    final scores = <String, int>{};
    for (final area in kAreas) {
      final keywords = _keywords[area.id] ?? [];
      int score = 0;
      for (final word in words) {
        for (final kw in keywords) {
          if (word.contains(kw) || kw.contains(word)) score++;
        }
      }
      scores[area.id] = score;
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(3)
        .map((e) => _AreaScore(areaId: e.key, score: e.value))
        .toList();
  }
}

class _AreaScore {
  final String areaId;
  final int score;
  const _AreaScore({required this.areaId, required this.score});
}
