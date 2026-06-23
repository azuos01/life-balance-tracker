/// Gera IDs de tarefas no formato AAAAMMDDHHMMSSXX.
///
/// XX = sequência de 2 letras maiúsculas (AA, AB, AC…) para diferenciar
/// tarefas criadas no mesmo segundo. Reinicia a cada novo segundo.
class TaskIdService {
  TaskIdService._();
  static final TaskIdService instance = TaskIdService._();

  String? _lastKey;
  int _seqIndex = 0;

  String generate() {
    final now = DateTime.now();
    final key = _fmtKey(now);
    if (key == _lastKey) {
      _seqIndex++;
    } else {
      _lastKey = key;
      _seqIndex = 0;
    }
    return '$key${_letters(_seqIndex)}';
  }

  String _fmtKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}'
      '${dt.month.toString().padLeft(2, '0')}'
      '${dt.day.toString().padLeft(2, '0')}'
      '${dt.hour.toString().padLeft(2, '0')}'
      '${dt.minute.toString().padLeft(2, '0')}'
      '${dt.second.toString().padLeft(2, '0')}';

  static const _alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  String _letters(int index) {
    final i = index.clamp(0, 675); // max ZZ = 26*26-1 = 675
    return '${_alpha[i ~/ 26 % 26]}${_alpha[i % 26]}';
  }
}
