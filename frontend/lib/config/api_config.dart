class ApiConfig {
  static const String _backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8000',
  );

  static String get baseUrl => _backendUrl;
  static String get apiUrl => '$_backendUrl/api';
  static String get wsBaseUrl => _backendUrl
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');

  // Endpoints
  static String get register => '$apiUrl/register';
  static String get login => '$apiUrl/token';
  static String get userMe => '$apiUrl/users/me';
  static String get rooms => '$apiUrl/rooms';
  static String get gameSessions => '$apiUrl/game-sessions';
  static String get documents => '$apiUrl/documents';
  static String get leaderboard => '$apiUrl/leaderboard/global';

  // Quiz
  static String get questions => '$apiUrl/quiz/questions';

  // Admin
  static String get adminUploadQuestions => '$apiUrl/admin/upload/questions';
  static String get adminUploadPdf => '$apiUrl/admin/upload/pdf';
  static String get adminUploadVideo => '$apiUrl/admin/upload/video';
  static String get adminDocuments => '$apiUrl/admin/documents';

  // WebSocket
  static String roomWebSocket(String roomCode) => '$wsBaseUrl/ws/room/$roomCode';
}
