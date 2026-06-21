import 'package:flutter/foundation.dart';
import '../models/task_suggestion.dart';
import '../models/task_model.dart';
import '../services/openai_service.dart';

class AiAgentProvider extends ChangeNotifier {
  final _service = OpenAIService();

  List<TaskSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastGenerated;
  final Set<String> _dismissed = {};

  List<TaskSuggestion> get suggestions =>
      _suggestions.where((s) => !_dismissed.contains(s.id)).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastGenerated => _lastGenerated;
  bool get hasSuggestions => suggestions.isNotEmpty;

  Future<void> generate({
    required String apiKey,
    required List<TaskModel> currentTasks,
    required Map<String, double> areaScores,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suggestions = await _service.generateTaskSuggestions(
        apiKey: apiKey,
        currentTasks: currentTasks,
        areaScores: areaScores,
      );
      _dismissed.clear();
      _lastGenerated = DateTime.now();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void dismiss(String id) {
    _dismissed.add(id);
    notifyListeners();
  }

  void clear() {
    _suggestions = [];
    _dismissed.clear();
    _error = null;
    _lastGenerated = null;
    notifyListeners();
  }
}
