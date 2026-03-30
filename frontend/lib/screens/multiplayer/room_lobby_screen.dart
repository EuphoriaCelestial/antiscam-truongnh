import '../home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/game_provider.dart';
// import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final bool isCreator;

  const RoomLobbyScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.isCreator,
  });

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  bool _isStarting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeRoom();
  }

  Future<void> _initializeRoom() async {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    
    // Set up game start listener
    roomProvider.addGameStartListener((roomCode, questionCount) {
      if (mounted) {
        context.go('/quiz?mode=multiplayer&roomCode=$roomCode&questionCount=$questionCount');
      }
    });

    // Connect to the room
    await roomProvider.connectToRoom(widget.roomCode, widget.playerName, isCreator: widget.isCreator);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Disconnect WebSocket when leaving
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    roomProvider.removeGameStartListener();
    roomProvider.disconnect();
    super.dispose();
  }

  Future<void> _copyRoomCode() async {
    await Clipboard.setData(ClipboardData(text: widget.roomCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã sao chép mã phòng: ${widget.roomCode}',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: const Color(0xFF00F2FF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startGame() async {
    setState(() => _isStarting = true);

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final questionCount = roomProvider.currentRoom?.questionCount ?? 10;
      
      print('Host sending game_started message for room: ${widget.roomCode}');
      roomProvider.sendMessage({
        'type': 'game_started',
        'roomCode': widget.roomCode,
        'questionCount': questionCount,
      });

      // Wait a bit for WebSocket to broadcast
      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        // Navigate to quiz screen
        context.go('/quiz?mode=multiplayer&roomCode=${widget.roomCode}&questionCount=$questionCount');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start game: $e'),
            backgroundColor: const Color(0xFFFF2D55),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _leaveRoom() async {
    try {
      // TODO: Call API to leave room
      // await gameProvider.leaveRoom(roomCode: widget.roomCode);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave room: $e'),
            backgroundColor: const Color(0xFFFF2D55),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        final players = roomProvider.players;
        final currentRoom = roomProvider.currentRoom;
        final currentUsername = widget.playerName;
        // Determine if current user is host
        final isHost = widget.isCreator;
        final maxPlayers = currentRoom?.maxPlayers ?? 4;
        final questionCount = roomProvider.questionCount;

        if (_isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F0F1A),
                    Color(0xFF1A0033),
                    Color(0xFF0F0F1A),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF00F2FF)),
              ),
            ),
          );
        }

        return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667eea).withOpacity(0.3),
                const Color(0xFF764ba2).withOpacity(0.3),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF5B4EFF).withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
        ),
        title: Text(
          'Phòng chờ',
          style: GoogleFonts.bungee(
            color: const Color(0xFFFFD60A),
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A0033),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: const Color(0xFF5B4EFF).withOpacity(0.5),
                    width: 2,
                  ),
                ),
                title: Text(
                  'Rời phòng?',
                  style: GoogleFonts.bungee(color: const Color(0xFFFFD60A)),
                ),
                content: Text(
                  'Bạn có chắc muốn rời khỏi phòng này?',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Hủy',
                      style: GoogleFonts.montserrat(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _leaveRoom();
                    },
                    child: Text(
                      'Rời phòng',
                      style: GoogleFonts.montserrat(color: const Color(0xFFFF2D55)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F1A),
              Color(0xFF1A0033),
              Color(0xFF0F0F1A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Room Code Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea).withOpacity(0.3),
                        const Color(0xFF764ba2).withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF5B4EFF).withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B4EFF).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Mã phòng',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.roomCode,
                            style: GoogleFonts.bungee(
                              fontSize: 32,
                              color: const Color(0xFFFFD60A),
                              letterSpacing: 8,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFFFD60A).withOpacity(0.5),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: _copyRoomCode,
                            icon: const Icon(Icons.copy, color: Color(0xFF00F2FF)),
                            tooltip: 'Sao chép mã',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$questionCount câu hỏi • Tối đa $maxPlayers người chơi',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF00F2FF),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, duration: 400.ms),
              ),
              const SizedBox(height: 24),

              // Players List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667eea).withOpacity(0.2),
                          const Color(0xFF764ba2).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00F2FF).withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Người chơi',
                              style: GoogleFonts.bungee(
                                fontSize: 18,
                                color: const Color(0xFFFFD60A),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00F2FF), Color(0xFF4FACFE)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${players.length}/$maxPlayers',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: players.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Backend not implemented yet. No players.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: players.length,
                                  itemBuilder: (context, index) {
                                    final player = players[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: player['isHost']
                                        ? const Color(0xFFFFD60A).withOpacity(0.5)
                                        : Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF5B4EFF),
                                      child: Text(
                                        player['username'][0].toUpperCase(),
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        player['username'],
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (player['isHost'])
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFFD60A), Color(0xFFFFA500)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Host',
                                          style: GoogleFonts.montserrat(
                                            color: Colors.black,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ).animate().fadeIn().slideX(begin: -0.1);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status/Action Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isHost
                    ? Column(
                        children: [
                          // Start Game Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00F2FF), Color(0xFF4FACFE)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F2FF).withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: players.length >= 2 && !_isStarting
                                  ? _startGame
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                              ),
                              child: _isStarting
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.play_arrow, size: 28),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Bắt đầu trò chơi',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          if (players.length < 2)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Cần ít nhất 2 người chơi để bắt đầu',
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFFFF2D55),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667eea).withOpacity(0.3),
                              const Color(0xFF764ba2).withOpacity(0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD60A).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFD60A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Đang chờ host bắt đầu...',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().then().shimmer(duration: 2000.ms, curve: Curves.easeInOut),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
