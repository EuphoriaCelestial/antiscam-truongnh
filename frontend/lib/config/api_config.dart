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

  // WebSocket
  static String roomWebSocket(String roomCode) => '$wsBaseUrl/ws/room/$roomCode';
}
