import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/learning_progress.dart';

class LearningService {
  static const _chessBase = 'https://api.chess.com/pub/player';
  static const _timeout = Duration(seconds: 15);

  Future<ChessStats> fetchChessStats(String username) async {
    final name = username.trim().toLowerCase();
    final uri = Uri.parse('$_chessBase/$name/stats');

    final http.Response response;
    try {
      response = await http
          .get(uri, headers: {'User-Agent': 'LifeBalanceTracker/2.4.0'})
          .timeout(_timeout);
    } catch (e) {
      throw Exception(
          'Não foi possível conectar ao Chess.com. Verifique sua conexão.');
    }

    if (response.statusCode == 404) {
      throw Exception('Usuário "$username" não encontrado no Chess.com.');
    }
    if (response.statusCode != 200) {
      throw Exception(
          'Erro ao buscar dados do Chess.com (${response.statusCode}).');
    }

    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ChessStats.fromApi(username, json);
  }
}
