import '../home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/room_provider.dart';
// import '../../providers/auth_provider.dart';

class MultiplayerLeaderboardScreen extends StatefulWidget {
  final String roomCode;
  final int myScore;
  final int myCorrectAnswers;
  final int totalQuestions;
  final double myTimeTaken;

  const MultiplayerLeaderboardScreen({
    super.key,
    required this.roomCode,
    required this.myScore,
    required this.myCorrectAnswers,
    required this.totalQuestions,
    required this.myTimeTaken,
  });

  @override
  State<MultiplayerLeaderboardScreen> createState() => _MultiplayerLeaderboardScreenState();
}

class _MultiplayerLeaderboardScreenState extends State<MultiplayerLeaderboardScreen> {
  late ConfettiController _confettiController;
  bool _hasSubmittedScore = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _submitScore();
  }

  Future<void> _submitScore() async {
    if (_hasSubmittedScore) return;
    _hasSubmittedScore = true;

    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    final playerName = globalPlayerName ?? 'Unknown';

    // Send score to other players via WebSocket
    roomProvider.sendMessage({
      'type': 'player_finished',
      'username': playerName,
      'score': widget.myScore,
      'correctAnswers': widget.myCorrectAnswers,
      'timeTaken': widget.myTimeTaken,
    });

    // Check if I won
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      final leaderboard = roomProvider.leaderboard;
      if (leaderboard.isNotEmpty && 
          leaderboard[0]['username'] != null &&
          leaderboard[0]['username'] == playerName) {
        _confettiController.play();
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${rank + 1}';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return const Color(0xFFFFD60A);
      case 1:
        return const Color(0xFFC0C0C0);
      case 2:
        return const Color(0xFFCD7F32);
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
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
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Color(0xFFFF2D55),
                Color(0xFF5B4EFF),
                Color(0xFFFFD60A),
                Color(0xFF00F2FF),
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Consumer<RoomProvider>(
              builder: (context, roomProvider, child) {
                final leaderboard = roomProvider.leaderboard;
                final currentUsername = globalPlayerName ?? 'Unknown';
                final allPlayersFinished = roomProvider.allPlayersFinished;

                return Column(
                  children: [
                    const SizedBox(height: 40),

                    // Title
                    Text(
                      'BẢNG XẾP HẠNG',
                      style: GoogleFonts.bungee(
                        fontSize: 32,
                        color: const Color(0xFFFFD60A),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD60A).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(),

                    const SizedBox(height: 8),

                    // Room code
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF5B4EFF).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'Phòng: ${widget.roomCode}',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF00F2FF),
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Waiting or Finished indicator
                    if (!allPlayersFinished)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
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
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFD60A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Đang chờ người chơi khác...',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().then().shimmer(duration: 2000.ms),

                    const SizedBox(height: 24),

                    // Leaderboard
                    Expanded(
                      child: leaderboard.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Color(0xFF00F2FF),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Đang tải kết quả...',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: leaderboard.length,
                              itemBuilder: (context, index) {
                                final player = leaderboard[index];
                                final isCurrentUser = player['username'] == currentUsername;
                                final rank = index;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: rank < 3
                                          ? [
                                              _getRankColor(rank).withOpacity(0.3),
                                              _getRankColor(rank).withOpacity(0.1),
                                            ]
                                          : [
                                              Colors.white.withOpacity(0.1),
                                              Colors.white.withOpacity(0.05),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isCurrentUser
                                          ? const Color(0xFF00F2FF)
                                          : _getRankColor(rank).withOpacity(0.5),
                                      width: isCurrentUser ? 2 : 1,
                                    ),
                                    boxShadow: isCurrentUser
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00F2FF).withOpacity(0.3),
                                              blurRadius: 15,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Rank
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _getRankColor(rank).withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _getRankColor(rank),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getRankEmoji(rank),
                                            style: const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Player info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    player['username'] ?? 'Unknown',
                                                    style: GoogleFonts.montserrat(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isCurrentUser) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [
                                                          Color(0xFF00F2FF),
                                                          Color(0xFF4FACFE)
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      'Bạn',
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  '${player['correctAnswers']}/${widget.totalQuestions} đúng',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  '⏱️ ${player['timeTaken'].toStringAsFixed(1)}s',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 12,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Score
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _getRankColor(rank),
                                              _getRankColor(rank).withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getRankColor(rank).withOpacity(0.3),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '${player['score']}',
                                          style: GoogleFonts.bungee(
                                            fontSize: 20,
                                            color: rank < 3 ? Colors.black : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().slideX(
                                      begin: 0.2,
                                      duration: 400.ms,
                                      delay: (index * 100).ms,
                                    );
                              },
                            ),
                    ),

                    // Bottom buttons
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          // Back to home button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF5B4EFF).withOpacity(0.8),
                                    const Color(0xFF9D50BB).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5B4EFF).withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final roomProvider = Provider.of<RoomProvider>(
                                    context,
                                    listen: false,
                                  );
                                  roomProvider.disconnect();
                                  context.go('/home');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.home, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Về trang chủ',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
