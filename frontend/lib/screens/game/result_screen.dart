import '../home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/game_provider.dart';
// import '../../providers/auth_provider.dart';
import '../../models/models.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final double timeTaken;
  final String mode;

  const ResultScreen({
    super.key,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeTaken,
    required this.mode,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confettiController;
  late PropagandaMessage _message;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    // Get random propaganda message
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    _message = gameProvider.getRandomMessage();
    
    // Show confetti if score is good
    if (widget.correctAnswers >= 7) {
      _confettiController.play();
    }
    
    // Save game session
    _saveGameSession();
  }

  Future<void> _saveGameSession() async {
    // TODO: Call API to save game session
    // Use globalPlayerName for player identification
    print('Saving game session for player: ${globalPlayerName ?? "Player"}');
  }

  Future<void> _playAudio() async {
    if (_message.audioUrl == null) return;
    
    if (_isPlayingAudio) {
      await _audioPlayer.stop();
      setState(() => _isPlayingAudio = false);
    } else {
      await _audioPlayer.play(AssetSource(_message.audioUrl!));
      setState(() => _isPlayingAudio = true);
      
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() => _isPlayingAudio = false);
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _getResultTitle() {
    final percentage = (widget.correctAnswers / widget.totalQuestions) * 100;
    
    if (percentage >= 90) return '🏆 Outstanding!';
    if (percentage >= 70) return '⭐ Great Job!';
    if (percentage >= 50) return '👍 Good Effort!';
    return '💪 Keep Trying!';
  }

  Color _getResultColor() {
    final percentage = (widget.correctAnswers / widget.totalQuestions) * 100;
    
    if (percentage >= 90) return Colors.amber;
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
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
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.amber,
              ],
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    _getResultTitle(),
                    style: GoogleFonts.bungee(
                      fontSize: 48,
                      color: const Color(0xFFFFD60A),
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFFD60A).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Score Card
                  _buildScoreCard(),
                  
                  const SizedBox(height: 30),
                  
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle,
                          label: 'Correct',
                          value: '${widget.correctAnswers}',
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.cancel,
                          label: 'Wrong',
                          value: '${widget.totalQuestions - widget.correctAnswers}',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildStatCard(
                    icon: Icons.timer,
                    label: 'Time Taken',
                    value: '${widget.timeTaken.toStringAsFixed(1)}s',
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Propaganda Message
                  _buildMessageCard(),
                  
                  const SizedBox(height: 40),
                  
                  // Action Buttons
                  _buildActionButtons(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.3),
            const Color(0xFF764ba2).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
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
            'Your Score',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              color: const Color(0xFFFFD60A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: widget.correctAnswers / widget.totalQuestions,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00F2FF)),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${widget.score}',
                    style: GoogleFonts.bungee(
                      fontSize: 56,
                      color: const Color(0xFF00F2FF),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00F2FF).withOpacity(0.5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'points',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.correctAnswers}/${widget.totalQuestions} Correct',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(
      duration: 500.ms,
      begin: 0.2,
      curve: Curves.easeOut,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final List<Color> gradientColors = color == Colors.green
        ? [const Color(0xFF00F2FF), const Color(0xFF4FACFE)]
        : color == Colors.red
            ? [const Color(0xFFFF2D55), const Color(0xFFFF6B9D)]
            : [const Color(0xFF5B4EFF), const Color(0xFF9D50BB)];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors.map((c) => c.withOpacity(0.2)).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradientColors[0].withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: gradientColors[0]),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.bungee(
              fontSize: 28,
              color: gradientColors[0],
            ),
          ),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(
      duration: 400.ms,
      delay: 200.ms,
    );
  }

  Widget _buildMessageCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD60A).withOpacity(0.1),
            const Color(0xFFFFA500).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD60A).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD60A).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFFFFD60A), size: 28),
              const SizedBox(width: 8),
              Text(
                'Important Message',
                style: GoogleFonts.bungee(
                  fontSize: 20,
                  color: const Color(0xFFFFD60A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _message.message,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              height: 1.5,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Audio Player Button
          if (_message.audioUrl != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _playAudio,
              icon: Icon(_isPlayingAudio ? Icons.stop : Icons.play_arrow),
              label: Text(_isPlayingAudio ? 'Stop Audio' : 'Play Audio'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(
      duration: 500.ms,
      begin: 0.2,
      delay: 400.ms,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
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
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              final gameProvider = Provider.of<GameProvider>(context, listen: false);
              gameProvider.reset();
              context.go('/quiz?mode=${widget.mode}');
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
            child: Text(
              'Play Again',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD60A),
              width: 2,
            ),
          ),
          child: OutlinedButton(
            onPressed: () => context.go('/home'),
            style: OutlinedButton.styleFrom(
              side: BorderSide.none,
              foregroundColor: const Color(0xFFFFD60A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Back to Home',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }
}
