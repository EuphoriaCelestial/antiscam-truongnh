import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

import '../config/api_config.dart';
import '../models/models.dart';

class RoomProvider extends ChangeNotifier {
  Room? _currentRoom;
  WebSocketChannel? _channel;
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isConnected = false;
  String? _error;
  Function(String, int)? _onGameStarted;
  int _expectedPlayers = 0;
  int _questionCount = 10;

  Room? get currentRoom => _currentRoom;
  List<Map<String, dynamic>> get players => _players;
  List<Map<String, dynamic>> get leaderboard => _leaderboard;
  bool get isConnected => _isConnected;
  String? get error => _error;
  bool get allPlayersFinished => _expectedPlayers > 0 && _leaderboard.length >= _expectedPlayers;
  int get questionCount => _questionCount;

  Future<Room?> createRoom({int maxPlayers = 10, int questionCount = 10}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.rooms),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'max_players': maxPlayers}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentRoom = Room.fromJson(data);
        _questionCount = questionCount;
        notifyListeners();
        return _currentRoom;
      } else {
        _error = 'Failed to create room';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinRoom(String roomCode) async {
    try {
      // Get room details
      final roomResponse = await http.get(
        Uri.parse('${ApiConfig.rooms}/$roomCode'),
      );

      if (roomResponse.statusCode == 200) {
        final roomData = jsonDecode(roomResponse.body);
        _currentRoom = Room.fromJson(roomData);
        _questionCount = 10; // Default for joined rooms
      } else {
        _error = 'Room not found';
        notifyListeners();
        return false;
      }

      // Join room
      final joinResponse = await http.post(
        Uri.parse('${ApiConfig.rooms}/$roomCode/join'),
      );

      if (joinResponse.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to join room';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> connectToRoom(String roomCode, String username, {bool isCreator = false}) async {
    if (!isCreator) {
      // Join the room via API if not creator
      final success = await joinRoom(roomCode);
      if (!success) return;
    }
    
    // Connect WebSocket for real-time player sync
    try {
      final wsUrl = '${ApiConfig.wsBaseUrl}/ws/room/$roomCode?username=$username';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      // Listen to WebSocket messages
      _channel!.stream.listen(
        (message) {
          if (kDebugMode) {
            print('WebSocket message received: $message');
          }
          final data = jsonDecode(message);
          if (data['type'] == 'players_updated') {
            _players = data['players'] != null 
                ? List<Map<String, dynamic>>.from(data['players'])
                : [];
            _expectedPlayers = _players.length;
            notifyListeners();
          } else if (data['type'] == 'game_started') {
            // Handle game start immediately
            if (kDebugMode) {
              print('Game started event received: ${data['roomCode']}, questionCount: ${data['questionCount']}');
            }
            if (_onGameStarted != null && data['roomCode'] != null) {
              final questionCount = data['questionCount'] ?? 10;
              _onGameStarted!(data['roomCode'], questionCount);
            }
          } else {
            _handleWebSocketMessage(data);
          }
        },
        onError: (error) {
          _isConnected = false;
          _error = 'WebSocket error: $error';
          if (kDebugMode) {
            print('WebSocket error: $error');
          }
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          if (kDebugMode) {
            print('WebSocket connection closed');
          }
          notifyListeners();
        },
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to connect WebSocket: $e';
      notifyListeners();
    }
  }

  void connectWebSocket(String roomCode, String username, {bool isHost = false}) {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(ApiConfig.roomWebSocket(roomCode)),
      );

      _isConnected = true;

      // Send join message
      sendMessage({
        'type': 'player_joined',
        'username': username,
        'player_count': (_currentRoom?.currentPlayers ?? 0) + 1,
      });

      // TODO: Wait for backend to send players_updated message

      // Listen to messages
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          _handleWebSocketMessage(data);
        },
        onError: (error) {
          _isConnected = false;
          _error = 'WebSocket error: $error';
          notifyListeners();
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
        },
      );

      notifyListeners();
    } catch (e) {
      _error = 'Failed to connect: $e';
      _isConnected = false;
      notifyListeners();
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'player_joined':
        // Update player list or count
        break;
      case 'game_started':
        // Notify listeners that game has started
        if (_onGameStarted != null && data['roomCode'] != null) {
          final questionCount = data['questionCount'] ?? 10;
          _onGameStarted!(data['roomCode'], questionCount);
        }
        break;
      case 'player_finished':
        // A player finished the game - add to leaderboard
        if (kDebugMode) {
          print('Player finished data: $data');
        }
        
        final existingIndex = _leaderboard.indexWhere(
          (p) => p['username'] == data['username'],
        );
        
        if (existingIndex == -1 && data['username'] != null) {
          final playerData = {
            'username': data['username'] ?? 'Unknown',
            'score': data['score'] ?? 0,
            'correctAnswers': data['correctAnswers'] ?? 0,
            'timeTaken': (data['timeTaken'] ?? 0.0).toDouble(),
          };
          
          if (kDebugMode) {
            print('Adding to leaderboard: $playerData');
          }
          
          _leaderboard.add(playerData);
          
          // Sort leaderboard: higher score first, then faster time
          _leaderboard.sort((a, b) {
            int scoreCompare = ((b['score'] ?? 0) as int).compareTo((a['score'] ?? 0) as int);
            if (scoreCompare != 0) return scoreCompare;
            return ((a['timeTaken'] ?? 0.0) as double).compareTo((b['timeTaken'] ?? 0.0) as double);
          });
          
          if (kDebugMode) {
            print('Updated leaderboard: $_leaderboard');
          }
        }
        break;
      case 'game_ended':
        // Game has ended
        break;
    }
    notifyListeners();
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && _isConnected) {
      final jsonMessage = jsonEncode(message);
      if (kDebugMode) {
        print('Sending WebSocket message: $jsonMessage');
      }
      _channel!.sink.add(jsonMessage);
    } else {
      if (kDebugMode) {
        print('Cannot send message: WebSocket not connected. _channel=$_channel, _isConnected=$_isConnected');
      }
    }
  }

  void addGameStartListener(Function(String, int) callback) {
    _onGameStarted = callback;
  }

  void removeGameStartListener() {
    _onGameStarted = null;
  }

  void setCurrentRoom(Room room) {
    _currentRoom = room;
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _currentRoom = null;
    _players.clear();
    _leaderboard.clear();
    _expectedPlayers = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
