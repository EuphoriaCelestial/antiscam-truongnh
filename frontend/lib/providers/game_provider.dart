import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../config/api_config.dart';

class GameProvider extends ChangeNotifier {
  List<Question> _questions = [];
  List<PropagandaMessage> _messages = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _correctAnswers = 0;
  DateTime? _gameStartTime;
  bool _isGameActive = false;

  List<Question> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get correctAnswers => _correctAnswers;
  bool get isGameActive => _isGameActive;
  Question? get currentQuestion =>
      _questions.isNotEmpty ? _questions[_currentQuestionIndex] : null;
  int get totalQuestions => _questions.length;
  int get remainingQuestions => totalQuestions - _currentQuestionIndex;

  Future<void> loadQuestions() async {
    // Try API first, fall back to bundled JSON
    try {
      final response = await http.get(Uri.parse(ApiConfig.questions))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        if (jsonData.isNotEmpty) {
          _questions = jsonData.map((q) => Question.fromJson(q)).toList();
          _questions.shuffle();
          _questions = _questions.take(10).toList();
          notifyListeners();
          return;
        }
      }
    } catch (_) {}

    // Fallback: load from bundled asset
    try {
      final String data = await rootBundle.loadString('assets/data/questions.json');
      final List<dynamic> jsonData = jsonDecode(data);
      _questions = jsonData.map((q) => Question.fromJson(q)).toList();
      _questions.shuffle();
      _questions = _questions.take(10).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading questions: $e');
    }
  }

  Future<void> loadMessages() async {
    try {
      final String data = await rootBundle.loadString('assets/data/messages.json');
      final List<dynamic> jsonData = jsonDecode(data);
      _messages = jsonData.map((m) => PropagandaMessage.fromJson(m)).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void startGame({int? questionCount}) {
    _currentQuestionIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    _gameStartTime = DateTime.now();
    _isGameActive = true;
    
    // If custom question count provided, limit the questions
    if (questionCount != null && questionCount < _questions.length) {
      _questions = _questions.sublist(0, questionCount);
    }
    
    notifyListeners();
  }

  bool answerQuestion(String answer) {
    if (!_isGameActive || currentQuestion == null) return false;

    final isCorrect = answer == currentQuestion!.correctAnswer;
    
    if (isCorrect) {
      _correctAnswers++;
      _score += 10; // 10 points per correct answer
    }

    notifyListeners();
    return isCorrect;
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    } else {
      endGame();
    }
  }

  void endGame() {
    _isGameActive = false;
    notifyListeners();
  }

  double getTimeTaken() {
    if (_gameStartTime == null) return 0.0;
    return DateTime.now().difference(_gameStartTime!).inSeconds.toDouble();
  }

  PropagandaMessage getRandomMessage() {
    if (_messages.isEmpty) return PropagandaMessage(
      id: '0',
      message: 'Congratulations on completing the quiz!',
    );
    
    final random = Random();
    return _messages[random.nextInt(_messages.length)];
  }

  void reset() {
    _currentQuestionIndex = 0;
    _score = 0;
    _correctAnswers = 0;
    _gameStartTime = null;
    _isGameActive = false;
    notifyListeners();
  }
}
