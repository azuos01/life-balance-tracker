/// Serviço de frases filosóficas diárias.
///
/// As frases são selecionadas deterministicamente pelo dia do ano,
/// garantindo que a mesma frase apareça durante todo o dia e mude
/// automaticamente à meia-noite.
///
/// Fonte inspiradora: pensador.com/as_frases_mais_inteligentes_do_mundo
/// Base ampliada com 150 citações cobrindo filosofia clássica, estoicismo,
/// pensamento oriental, filosofia moderna e grandes líderes.
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
    // ── SÓCRATES ──────────────────────────────────────────────────────────────
    Quote(
      text: 'A vida não examinada não vale a pena ser vivida.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'Só sei que nada sei.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'Conhece-te a ti mesmo.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'O segredo da mudança é focar toda a sua energia não em lutar contra o velho, mas em construir o novo.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'A educação é acender uma chama, não encher um recipiente vazio.',
      author: 'Sócrates',
    ),
    Quote(
      text: 'Seja a mudança que você deseja ver no mundo interior antes de exigi-la no exterior.',
      author: 'Sócrates',
    ),

    // ── PLATÃO ────────────────────────────────────────────────────────────────
    Quote(
      text: 'A necessidade é a mãe da invenção.',
      author: 'Platão',
    ),
    Quote(
      text: 'Quem aprende e aprende e não pratica o que sabe, é como quem ara e ara e nunca semeia.',
      author: 'Platão',
    ),
    Quote(
      text: 'O começo é a parte mais importante de qualquer trabalho.',
      author: 'Platão',
    ),
    Quote(
      text: 'A opinião é a mediadora entre o conhecimento e a ignorância.',
      author: 'Platão',
    ),

    // ── ARISTÓTELES ───────────────────────────────────────────────────────────
    Quote(
      text: 'Somos o que fazemos repetidamente. Excelência, então, não é um ato, mas um hábito.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'A raiz da educação é amarga, mas seus frutos são doces.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'A felicidade é o significado e o propósito da vida, o objetivo e o fim da existência humana.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'O homem sábio não diz tudo que pensa, mas sempre pensa tudo que diz.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'É durante os momentos mais difíceis que encontramos a verdadeira medida do caráter.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'A virtude é o meio-termo entre dois extremos, ambos viciosos.',
      author: 'Aristóteles',
    ),
    Quote(
      text: 'Devemos ser donos de nossas próprias decisões, não escravos das circunstâncias.',
      author: 'Aristóteles',
    ),

    // ── MARCO AURÉLIO (ESTOICISMO) ────────────────────────────────────────────
    Quote(
      text: 'Você tem poder sobre sua mente, não sobre os eventos externos. Perceba isso e encontrará força.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'A melhor vingança é não ser como seu inimigo.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'Perde seu tempo quem busca a aprovação dos outros.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'Quando você acorda de manhã, pense no precioso privilégio de estar vivo: respirar, pensar, desfrutar e amar.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'A qualidade da sua vida é determinada pela qualidade dos seus pensamentos.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'Nunca estime algo como lucrativo se te forçar a quebrar sua palavra ou perder seu autorrespeito.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'Não desperdice o resto de sua vida em pensamentos sobre outras pessoas.',
      author: 'Marco Aurélio',
    ),
    Quote(
      text: 'O homem que faz tudo o que pode dentro das limitações que lhe foram impostas faz o suficiente.',
      author: 'Marco Aurélio',
    ),

    // ── EPICTETO (ESTOICISMO) ─────────────────────────────────────────────────
    Quote(
      text: 'Não é o que acontece com você, mas como você reage ao que acontece com você que importa.',
      author: 'Epicteto',
    ),
    Quote(
      text: 'Faça todo o possível para não depender de circunstâncias externas.',
      author: 'Epicteto',
    ),
    Quote(
      text: 'Não procure que as coisas que acontecem sejam como você quer. Deseje que as coisas que acontecem sejam como são e você encontrará tranquilidade.',
      author: 'Epicteto',
    ),
    Quote(
      text: 'Temos dois ouvidos e uma boca para que possamos ouvir duas vezes mais do que falamos.',
      author: 'Epicteto',
    ),
    Quote(
      text: 'A riqueza consiste não em ter grandes posses, mas em ter poucas necessidades.',
      author: 'Epicteto',
    ),
    Quote(
      text: 'Primeiro diga a si mesmo o que você será; depois faça o que tem a fazer.',
      author: 'Epicteto',
    ),

    // ── SÊNECA (ESTOICISMO) ───────────────────────────────────────────────────
    Quote(
      text: 'Não é que tenhamos pouco tempo, mas que desperdiçamos muito.',
      author: 'Sêneca',
    ),
    Quote(
      text: 'Enquanto adiamos, a vida passa.',
      author: 'Sêneca',
    ),
    Quote(
      text: 'É uma força grande não precisar de força.',
      author: 'Sêneca',
    ),
    Quote(
      text: 'Retire-se para dentro de si mesmo tanto quanto puder com aqueles que vão fazer de você uma pessoa melhor.',
      author: 'Sêneca',
    ),
    Quote(
      text: 'A dificuldade que você supera hoje é a sabedoria que você carrega amanhã.',
      author: 'Sêneca',
    ),
    Quote(
      text: 'Cuide do corpo para que a mente possa habitá-lo com prazer.',
      author: 'Sêneca',
    ),
    Quote(
      text: 'Comece. Não há nada que tanto retarde o progresso quanto esperar por ele.',
      author: 'Sêneca',
    ),
    Quote(
      text: 'Viva com os seres humanos como se Deus te visse; fale com Deus como se os seres humanos te ouvissem.',
      author: 'Sêneca',
    ),

    // ── HERÁCLITO ─────────────────────────────────────────────────────────────
    Quote(
      text: 'A mudança é a única constante da vida.',
      author: 'Heráclito',
    ),
    Quote(
      text: 'Não é possível pisar duas vezes no mesmo rio.',
      author: 'Heráclito',
    ),
    Quote(
      text: 'O caráter é o destino.',
      author: 'Heráclito',
    ),
    Quote(
      text: 'Muito aprender não ensina a ter bom senso.',
      author: 'Heráclito',
    ),

    // ── LAO TZU / TAOÍSMO ─────────────────────────────────────────────────────
    Quote(
      text: 'A jornada de mil milhas começa com um único passo.',
      author: 'Lao Tzu',
    ),
    Quote(
      text: 'Aquele que se conhece é sábio. Aquele que conquista os outros é forte. Aquele que conquista a si mesmo é poderoso.',
      author: 'Lao Tzu',
    ),
    Quote(
      text: 'A natureza não tem pressa, mas realiza tudo.',
      author: 'Lao Tzu',
    ),
    Quote(
      text: 'Quando eu deixo de ser o que sou, torno-me o que poderia ser.',
      author: 'Lao Tzu',
    ),
    Quote(
      text: 'Seja cuidadoso com seus pensamentos, eles se tornam suas palavras. Seja cuidadoso com suas palavras, elas se tornam suas ações.',
      author: 'Lao Tzu',
    ),
    Quote(
      text: 'Agir sem expectativa, realizar sem fazer alarde — isso é a virtude suprema.',
      author: 'Lao Tzu',
    ),

    // ── CONFÚCIO ──────────────────────────────────────────────────────────────
    Quote(
      text: 'Não importa quão devagar você vá, desde que não pare.',
      author: 'Confúcio',
    ),
    Quote(
      text: 'Fazer o bem por obrigação é virtude; fazer o bem por amor é sabedoria.',
      author: 'Confúcio',
    ),
    Quote(
      text: 'A pessoa que move uma montanha começa carregando pequenas pedras.',
      author: 'Confúcio',
    ),
    Quote(
      text: 'Escolha um trabalho que você ame e não terá que trabalhar um único dia em sua vida.',
      author: 'Confúcio',
    ),
    Quote(
      text: 'Antes de se aventurar a melhorar o mundo, dê três voltas em torno de sua própria casa.',
      author: 'Confúcio',
    ),
    Quote(
      text: 'Aquele que aprende mas não pensa está perdido. Aquele que pensa mas não aprende está em grande perigo.',
      author: 'Confúcio',
    ),

    // ── BUDA ──────────────────────────────────────────────────────────────────
    Quote(
      text: 'O que você pensa, você se torna. O que você sente, você atrai. O que você imagina, você cria.',
      author: 'Buda',
    ),
    Quote(
      text: 'A mente é tudo. O que você pensa, você se torna.',
      author: 'Buda',
    ),
    Quote(
      text: 'Três coisas não podem ser escondidas por muito tempo: o sol, a lua e a verdade.',
      author: 'Buda',
    ),
    Quote(
      text: 'Não viva no passado, não sonhe com o futuro, concentre a mente no momento presente.',
      author: 'Buda',
    ),
    Quote(
      text: 'A paz vem de dentro. Não a procure fora.',
      author: 'Buda',
    ),
    Quote(
      text: 'Você mesmo, mais do que qualquer outra pessoa no universo, merece seu amor e afeto.',
      author: 'Buda',
    ),

    // ── NIETZSCHE ─────────────────────────────────────────────────────────────
    Quote(
      text: 'O que não me mata, me fortalece.',
      author: 'Friedrich Nietzsche',
    ),
    Quote(
      text: 'Aquele que tem um porquê para viver suporta quase qualquer como.',
      author: 'Friedrich Nietzsche',
    ),
    Quote(
      text: 'A grandeza do homem está em ser uma ponte, não um fim.',
      author: 'Friedrich Nietzsche',
    ),
    Quote(
      text: 'Sem música a vida seria um erro.',
      author: 'Friedrich Nietzsche',
    ),
    Quote(
      text: 'Torne-se quem você é.',
      author: 'Friedrich Nietzsche',
    ),
    Quote(
      text: 'Aquele que luta com monstros deve tomar cuidado para não se tornar um monstro.',
      author: 'Friedrich Nietzsche',
    ),

    // ── DESCARTES ─────────────────────────────────────────────────────────────
    Quote(
      text: 'Penso, logo existo.',
      author: 'René Descartes',
    ),
    Quote(
      text: 'Divida cada dificuldade em tantas partes quanto for necessário para resolvê-la.',
      author: 'René Descartes',
    ),

    // ── KANT ──────────────────────────────────────────────────────────────────
    Quote(
      text: 'Age de tal forma que a máxima de tua vontade possa valer como princípio de uma legislação universal.',
      author: 'Immanuel Kant',
    ),
    Quote(
      text: 'Duas coisas me enchem de admiração: o céu estrelado acima de mim e a lei moral dentro de mim.',
      author: 'Immanuel Kant',
    ),
    Quote(
      text: 'Aja apenas segundo uma máxima tal que possa ao mesmo tempo querer que ela se torne uma lei universal.',
      author: 'Immanuel Kant',
    ),

    // ── SARTRE ────────────────────────────────────────────────────────────────
    Quote(
      text: 'O homem está condenado a ser livre.',
      author: 'Jean-Paul Sartre',
    ),
    Quote(
      text: 'A existência precede a essência.',
      author: 'Jean-Paul Sartre',
    ),
    Quote(
      text: 'A vida não tem sentido a priori. Antes de você vivê-la, ela não é nada; cabe a você dar-lhe um sentido.',
      author: 'Jean-Paul Sartre',
    ),

    // ── CAMUS ─────────────────────────────────────────────────────────────────
    Quote(
      text: 'É preciso imaginar Sísifo feliz.',
      author: 'Albert Camus',
    ),
    Quote(
      text: 'No meio do inverno aprendi, finalmente, que havia em mim um verão invencível.',
      author: 'Albert Camus',
    ),
    Quote(
      text: 'A rebeldia é um dos únicos atos humanos coerentes.',
      author: 'Albert Camus',
    ),

    // ── SCHOPENHAUER ──────────────────────────────────────────────────────────
    Quote(
      text: 'O talento acerta alvos que ninguém mais pode acertar; o gênio acerta alvos que ninguém mais pode ver.',
      author: 'Arthur Schopenhauer',
    ),
    Quote(
      text: 'Riqueza é como a água do mar: quanto mais você bebe, mais sede tem.',
      author: 'Arthur Schopenhauer',
    ),

    // ── SPINOZA ───────────────────────────────────────────────────────────────
    Quote(
      text: 'A paz não é ausência de guerra; é uma virtude, um estado de espírito, uma disposição para a benevolência, confiança e justiça.',
      author: 'Baruch Spinoza',
    ),
    Quote(
      text: 'O desejo é a própria essência do homem.',
      author: 'Baruch Spinoza',
    ),

    // ── EINSTEIN ──────────────────────────────────────────────────────────────
    Quote(
      text: 'A imaginação é mais importante que o conhecimento.',
      author: 'Albert Einstein',
    ),
    Quote(
      text: 'No meio de toda dificuldade há uma oportunidade.',
      author: 'Albert Einstein',
    ),
    Quote(
      text: 'A mente que se abre a uma nova ideia jamais voltará ao seu tamanho original.',
      author: 'Albert Einstein',
    ),
    Quote(
      text: 'Insanidade é continuar fazendo a mesma coisa esperando resultados diferentes.',
      author: 'Albert Einstein',
    ),
    Quote(
      text: 'A vida é como andar de bicicleta: para manter o equilíbrio é preciso continuar em movimento.',
      author: 'Albert Einstein',
    ),
    Quote(
      text: 'Aprenda as regras do jogo. E depois jogue melhor do que ninguém.',
      author: 'Albert Einstein',
    ),

    // ── SUN TZU ───────────────────────────────────────────────────────────────
    Quote(
      text: 'Conhece o inimigo e conhece a ti mesmo; em cem batalhas nunca correrás perigo.',
      author: 'Sun Tzu',
    ),
    Quote(
      text: 'Oportunidades se multiplicam quando são aproveitadas.',
      author: 'Sun Tzu',
    ),
    Quote(
      text: 'A vitória suprema é vencer sem combater.',
      author: 'Sun Tzu',
    ),
    Quote(
      text: 'Em meio ao caos existe também oportunidade.',
      author: 'Sun Tzu',
    ),

    // ── GANDHI ────────────────────────────────────────────────────────────────
    Quote(
      text: 'Viva como se fosse morrer amanhã. Aprenda como se fosse viver para sempre.',
      author: 'Mahatma Gandhi',
    ),
    Quote(
      text: 'Seja a mudança que você deseja ver no mundo.',
      author: 'Mahatma Gandhi',
    ),
    Quote(
      text: 'A força não vem da capacidade física. Vem de uma vontade indomável.',
      author: 'Mahatma Gandhi',
    ),
    Quote(
      text: 'Primeiro eles te ignoram, depois riem de você, depois lutam contra você. Então você vence.',
      author: 'Mahatma Gandhi',
    ),

    // ── MANDELA ───────────────────────────────────────────────────────────────
    Quote(
      text: 'A maior glória em viver não está em nunca cair, mas em se levantar sempre que caímos.',
      author: 'Nelson Mandela',
    ),
    Quote(
      text: 'Tudo parece impossível até que seja feito.',
      author: 'Nelson Mandela',
    ),
    Quote(
      text: 'A educação é a arma mais poderosa que você pode usar para mudar o mundo.',
      author: 'Nelson Mandela',
    ),

    // ── CHURCHILL ─────────────────────────────────────────────────────────────
    Quote(
      text: 'O sucesso é tropeçar de fracasso em fracasso sem perder o entusiasmo.',
      author: 'Winston Churchill',
    ),
    Quote(
      text: 'Se você está passando pelo inferno, continue andando.',
      author: 'Winston Churchill',
    ),
    Quote(
      text: 'Atitude é uma pequena coisa que faz uma grande diferença.',
      author: 'Winston Churchill',
    ),

    // ── LINCOLN ───────────────────────────────────────────────────────────────
    Quote(
      text: 'A melhor maneira de prever o futuro é criá-lo.',
      author: 'Abraham Lincoln',
    ),
    Quote(
      text: 'Dê-me seis horas para cortar uma árvore e passarei as primeiras quatro afiando o machado.',
      author: 'Abraham Lincoln',
    ),

    // ── STEVE JOBS ────────────────────────────────────────────────────────────
    Quote(
      text: 'A única maneira de fazer um ótimo trabalho é amar o que você faz.',
      author: 'Steve Jobs',
    ),
    Quote(
      text: 'Sua visão de mundo já está moldada antes de você perceber que tem uma. A vida é curta demais para viver a dos outros.',
      author: 'Steve Jobs',
    ),
    Quote(
      text: 'Fique com fome. Fique tolo.',
      author: 'Steve Jobs',
    ),

    // ── BERTRAND RUSSELL ──────────────────────────────────────────────────────
    Quote(
      text: 'O tempo que você gosta de perder não é tempo perdido.',
      author: 'Bertrand Russell',
    ),
    Quote(
      text: 'A conquista da felicidade não é algo que acontece — é algo que você constrói.',
      author: 'Bertrand Russell',
    ),
    Quote(
      text: 'O segredo da felicidade é muito simples: encontre o que te interessa genuinamente e faça isso.',
      author: 'Bertrand Russell',
    ),

    // ── GOETHE ────────────────────────────────────────────────────────────────
    Quote(
      text: 'Trate um homem como ele pode se tornar e você o tornará no que ele pode ser.',
      author: 'Goethe',
    ),
    Quote(
      text: 'Seja ousado e poderosas forças virão em seu auxílio.',
      author: 'Goethe',
    ),
    Quote(
      text: 'O que não te mata, te fortalece — e o que te fortalece, transforma.',
      author: 'Goethe',
    ),
    Quote(
      text: 'Pensar é fácil, agir é difícil, e transformar o pensamento em ação é o mais difícil de tudo.',
      author: 'Goethe',
    ),

    // ── DOSTOIÉVSKI ───────────────────────────────────────────────────────────
    Quote(
      text: 'Acima de tudo, não minta para si mesmo. O homem que mente para si mesmo e escuta suas próprias mentiras chega ao ponto em que não consegue distinguir a verdade dentro de si.',
      author: 'Fiódor Dostoiévski',
    ),
    Quote(
      text: 'A beleza salvará o mundo.',
      author: 'Fiódor Dostoiévski',
    ),
    Quote(
      text: 'Amar alguém é vê-los como Deus os planejou ser.',
      author: 'Fiódor Dostoiévski',
    ),

    // ── TOLSTÓI ───────────────────────────────────────────────────────────────
    Quote(
      text: 'Todos pensam em mudar o mundo, mas ninguém pensa em mudar a si mesmo.',
      author: 'Leon Tolstói',
    ),
    Quote(
      text: 'Só há uma coisa que importa: fazer o bem agora neste momento.',
      author: 'Leon Tolstói',
    ),

    // ── SHAKESPEARE ───────────────────────────────────────────────────────────
    Quote(
      text: 'Ser ou não ser, eis a questão.',
      author: 'William Shakespeare',
    ),
    Quote(
      text: 'Não há escuridão, apenas ignorância.',
      author: 'William Shakespeare',
    ),
    Quote(
      text: 'Covardes morrem muitas vezes antes da morte; os valentes provam a morte uma única vez.',
      author: 'William Shakespeare',
    ),

    // ── DALAI LAMA ────────────────────────────────────────────────────────────
    Quote(
      text: 'Minha religião é muito simples. Minha religião é a bondade.',
      author: 'Dalai Lama',
    ),
    Quote(
      text: 'Se você quer que os outros sejam felizes, pratique a compaixão. Se você quer ser feliz, pratique a compaixão.',
      author: 'Dalai Lama',
    ),
    Quote(
      text: 'Lembre-se que o melhor relacionamento é aquele em que o amor por cada um supera a necessidade um pelo outro.',
      author: 'Dalai Lama',
    ),
    Quote(
      text: 'Uma vez por semana, fique em silêncio e ouça o que a sua alma tem a dizer.',
      author: 'Dalai Lama',
    ),

    // ── MIYAMOTO MUSASHI ──────────────────────────────────────────────────────
    Quote(
      text: 'Faça de hoje sua obra-prima.',
      author: 'Miyamoto Musashi',
    ),
    Quote(
      text: 'Não busque prazer pelo prazer. Não aja movido apenas pelo interesse pessoal. Perceba o que é verdadeiro em tudo.',
      author: 'Miyamoto Musashi',
    ),
    Quote(
      text: 'Você só pode lutar do jeito que pratica.',
      author: 'Miyamoto Musashi',
    ),

    // ── DESENVOLVIMENTO PESSOAL ───────────────────────────────────────────────
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
      text: 'A vida é 10% o que acontece comigo e 90% como eu reajo a isso.',
      author: 'Charles R. Swindoll',
    ),
    Quote(
      text: 'Sua vida não é um acidente. É um reflexo de suas decisões.',
      author: 'Tony Robbins',
    ),
    Quote(
      text: 'Comece onde você está. Use o que você tem. Faça o que você pode.',
      author: 'Arthur Ashe',
    ),
    Quote(
      text: 'Nunca confunda movimento com ação.',
      author: 'Ernest Hemingway',
    ),
    Quote(
      text: 'Em tempos de mudança, quem aprende herda o futuro. Quem sabe, descobre que está equipado para um mundo que não existe mais.',
      author: 'Eric Hoffer',
    ),
    Quote(
      text: 'Onde a disposição existe, os meios geralmente se seguem.',
      author: 'George S. Patton',
    ),

    // ── PROVÉRBIOS E SABEDORIA POPULAR ───────────────────────────────────────
    Quote(
      text: 'A melhor hora para plantar uma árvore foi há 20 anos. A segunda melhor hora é agora.',
      author: 'Provérbio Chinês',
    ),
    Quote(
      text: 'Não tenha medo de crescer devagar; tenha medo de ficar parado.',
      author: 'Provérbio Chinês',
    ),
    Quote(
      text: 'Quando os ventos de mudança sopram, alguns constroem muros, outros moinhos de vento.',
      author: 'Provérbio Chinês',
    ),
    Quote(
      text: 'Caia sete vezes, levante-se oito.',
      author: 'Provérbio Japonês',
    ),
    Quote(
      text: 'Visão sem execução é apenas alucinação.',
      author: 'Thomas Edison',
    ),

    // ── CIÊNCIA E EXPLORAÇÃO ──────────────────────────────────────────────────
    Quote(
      text: 'O maior inimigo do conhecimento não é a ignorância, mas a ilusão do conhecimento.',
      author: 'Stephen Hawking',
    ),
    Quote(
      text: 'A ciência não apenas descreve, mas justifica e, ao justificar, engrandece.',
      author: 'Carl Sagan',
    ),
    Quote(
      text: 'Em algum lugar, algo incrível está esperando para ser descoberto.',
      author: 'Carl Sagan',
    ),
    Quote(
      text: 'O Universo não é obrigado a fazer sentido para você.',
      author: 'Neil deGrasse Tyson',
    ),

    // ── VIKTOR FRANKL ─────────────────────────────────────────────────────────
    Quote(
      text: 'Quando não podemos mais mudar uma situação, somos desafiados a mudar a nós mesmos.',
      author: 'Viktor Frankl',
    ),
    Quote(
      text: 'Entre o estímulo e a resposta há um espaço. Nesse espaço está o nosso poder de escolher nossa resposta.',
      author: 'Viktor Frankl',
    ),
    Quote(
      text: 'Aquele que tem um porquê para viver pode suportar quase qualquer como.',
      author: 'Viktor Frankl',
    ),

    // ── LITERATURA BRASILEIRA ─────────────────────────────────────────────────
    Quote(
      text: 'Não há caminho para a felicidade: a felicidade é o caminho.',
      author: 'Thich Nhat Hanh',
    ),
    Quote(
      text: 'A coragem não é ausência de medo, mas o julgamento de que algo mais importa.',
      author: 'Ambrose Redmoon',
    ),
    Quote(
      text: 'O único modo de fazer algo de grande valor é amar o que se faz.',
      author: 'Steve Jobs',
    ),
  ];
}

class Quote {
  final String text;
  final String author;

  const Quote({required this.text, required this.author});
}
