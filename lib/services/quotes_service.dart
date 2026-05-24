/// Serviço de frases filosóficas diárias.
///
/// As frases são selecionadas deterministicamente pelo dia do ano,
/// garantindo que a mesma frase apareça durante todo o dia e mude
/// automaticamente à meia-noite.
///
/// Fonte inspiradora: pensador.com/as_frases_mais_inteligentes_do_mundo
class QuotesService {
  QuotesService._();
  static final QuotesService instance = QuotesService._();

  /// Retorna a frase do dia atual
  Quote getDailyQuote() {
    final now = DateTime.now();
    final dayOfYear = _dayOfYear(now);
    return _quotes[dayOfYear % _quotes.length];
  }

  int _dayOfYear(DateTime d) {
    return d.difference(DateTime(d.year, 1, 1)).inDays;
  }

  static const List<Quote> _quotes = [
    Quote(
      text: 'A vida não examinada não vale a pena ser vivida.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'Somos o que fazemos repetidamente. Excelência, então, não é um ato, mas um hábito.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'Você tem poder sobre sua mente, não sobre os eventos externos. Perceba isso e encontrará força.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'O que não me mata, me fortalece.',
      author: 'Friedrich Nietzsche',
    ),
    Quote(
      text: 'A imaginação é mais importante que o conhecimento.',
      author: 'Albert Einstein',
    ),
    Quote(
      text: 'A jornada de mil milhas começa com um único passo.',
      author: 'Lao Tzu',
    ),
    Quote(
      text: 'Não é o que acontece com você, mas como você reage ao que acontece com você que importa.',
      author: 'Epicteto',
    ),
    Quote(
      text: 'A raiz da educação é amarga, mas seus frutos são doces.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'A melhor vingança é não ser como seu inimigo.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'A mudança é a única constante da vida.',
      author: 'Heráclito',
    ),
    Quote(
      text: 'O segredo da mudança é focar toda a sua energia não em lutar contra o velho, mas em construir o novo.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'Aquele que tem um porquê para viver suporta quase qualquer como.',
      author: 'Friedrich Nietzsche',
    ),
    Quote(
      text: 'Penso, logo existo.',
      author: 'René Descartes',
    ),
    Quote(
      text: 'A felicidade é o significado e o propósito da vida, o objetivo e o fim da existência humana.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'Nunca confunda movimento com ação.',
      author: 'Ernest Hemingway',
    ),
    Quote(
      text: 'Comece onde você está. Use o que você tem. Faça o que você pode.',
      author: 'Arthur Ashe',
    ),
    Quote(
      text: 'A disciplina é a ponte entre metas e conquistas.',
      author: 'Jim Rohn',
    ),
    Quote(
      text: 'O sucesso é a soma de pequenos esforços repetidos dia após dia.',
      author: 'Robert Collier',
    ),
    Quote(
      text: 'Não espere. O momento nunca será perfeito.',
      author: 'Napoleon Hill',
    ),
    Quote(
      text: 'O homem está condenado a ser livre.',
      author: 'Jean-Paul Sartre',
    ),
    Quote(
      text: 'Trate um homem como ele pode se tornar e você o tornará no que ele pode ser.',
      author: 'Goethe',
    ),
    Quote(
      text: 'No meio de toda dificuldade há uma oportunidade.',
      author: 'Albert Einstein',
    ),
    Quote(
      text: 'A vida é 10% o que acontece comigo e 90% como eu reajo a isso.',
      author: 'Charles R. Swindoll',
    ),
    Quote(
      text: 'O que você pensa, você se torna. O que você sente, você atrai. O que você imagina, você cria.',
      author: 'Buda',
    ),
    Quote(
      text: 'Conhece-te a ti mesmo.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'A única maneira de fazer um ótimo trabalho é amar o que você faz.',
      author: 'Steve Jobs',
    ),
    Quote(
      text: 'Não é possível pisar duas vezes no mesmo rio.',
      author: 'Heráclito',
    ),
    Quote(
      text: 'Age de tal forma que a máxima de tua vontade possa valer como princípio de uma legislação universal.',
      author: 'Immanuel Kant',
    ),
    Quote(
      text: 'A grandeza do homem está em ser uma ponte, não um fim.',
      author: 'Friedrich Nietzsche',
    ),
    Quote(
      text: 'Só sei que nada sei.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'O tempo que você gosta de perder não é tempo perdido.',
      author: 'Bertrand Russell',
    ),
    Quote(
      text: 'Sua vida não é um acidente. É um reflexo de suas decisões.',
      author: 'Tony Robbins',
    ),
    Quote(
      text: 'A existência precede a essência.',
      author: 'Jean-Paul Sartre',
    ),
    Quote(
      text: 'A mente que se abre a uma nova ideia jamais voltará ao seu tamanho original.',
      author: 'Albert Einstein',
    ),
    Quote(
      text: 'Fazer o bem por obrigação é virtude; fazer o bem por amor é sabedoria.',
      author: 'Confúcio',
    ),
    Quote(
      text: 'Onde a disposição existe, os meios geralmente se seguem.',
      author: 'George S. Patton',
    ),
    Quote(
      text: 'Não importa quão devagar você vá, desde que não pare.',
      author: 'Confúcio',
    ),
    Quote(
      text: 'O homem sábio não diz tudo que pensa, mas sempre pensa tudo que diz.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'A melhor hora para plantar uma árvore foi há 20 anos. A segunda melhor hora é agora.',
      author: 'Provérbio Chinês',
    ),
    Quote(
      text: 'Viva como se fosse morrer amanhã. Aprenda como se fosse viver para sempre.',
      author: 'Mahatma Gandhi',
    ),
    Quote(
      text: 'Não tenha medo de crescer devagar; tenha medo de ficar parado.',
      author: 'Provérbio Chinês',
    ),
    Quote(
      text: 'A maior glória em viver não está em nunca cair, mas em se levantar sempre que caímos.',
      author: 'Nelson Mandela',
    ),
    Quote(
      text: 'Em tempos de mudança, quem aprende herda o futuro. Quem sabe, descobre que está equipado para um mundo que não existe mais.',
      author: 'Eric Hoffer',
    ),
  ];
}

class Quote {
  final String text;
  final String author;

  const Quote({required this.text, required this.author});
}
