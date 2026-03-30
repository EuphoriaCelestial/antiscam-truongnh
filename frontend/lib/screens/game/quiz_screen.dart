import '../home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/game_provider.dart';
// import '../../providers/auth_provider.dart';

class QuizScreen extends StatefulWidget {
  final String mode;
  final String? roomCode;
  final int? questionCount;

  const QuizScreen({
    super.key,
    required this.mode,
    this.roomCode,
    this.questionCount,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  String? _selectedAnswer;
  String? _correctAnswer; // Store the correct answer for current question
  bool _isAnswered = false;
  bool _showCorrectFeedback = false;
  bool _showIncorrectFeedback = false;
  int _currentQuestionIndex = -1; // Track which question we're displaying

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Load and start game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      gameProvider.loadQuestions().then((_) {
        gameProvider.loadMessages();
        // Use custom question count if provided (for multiplayer)
        if (widget.questionCount != null) {
          gameProvider.startGame(questionCount: widget.questionCount);
        } else {
          gameProvider.startGame();
        }
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleAnswer(String answer, GameProvider gameProvider) {
    if (_isAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
    });

    final isCorrect = gameProvider.answerQuestion(answer);

    setState(() {
      if (isCorrect) {
        _showCorrectFeedback = true;
        _confettiController.play();
      } else {
        _showIncorrectFeedback = true;
      }
    });

    _animationController.forward();

    // Wait for animation then move to next question
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      if (gameProvider.currentQuestionIndex < gameProvider.totalQuestions - 1) {
        // First reset the question state, then update provider
        setState(() {
          _selectedAnswer = null;
          _isAnswered = false;
          _showCorrectFeedback = false;
          _showIncorrectFeedback = false;
        });
        _animationController.reset();
        
        // Update game provider which will trigger a rebuild with new question
        gameProvider.nextQuestion();
      } else {
        // Game finished
        _navigateToResults(gameProvider);
      }
    });
  }

  void _resetQuestion() {
    if (!mounted) return;
    setState(() {
      _selectedAnswer = null;
      _isAnswered = false;
      _showCorrectFeedback = false;
      _showIncorrectFeedback = false;
    });
    _animationController.reset();
  }

  void _navigateToResults(GameProvider gameProvider) {
    if (widget.mode == 'multiplayer' && widget.roomCode != null) {
      // Navigate to multiplayer leaderboard
      context.go('/multiplayer-result/${widget.roomCode}', extra: {
        'score': gameProvider.score,
        'correctAnswers': gameProvider.correctAnswers,
        'totalQuestions': gameProvider.totalQuestions,
        'timeTaken': gameProvider.getTimeTaken(),
      });
    } else {
      // Navigate to single player result
      context.go('/result', extra: {
        'score': gameProvider.score,
        'correctAnswers': gameProvider.correctAnswers,
        'totalQuestions': gameProvider.totalQuestions,
        'timeTaken': gameProvider.getTimeTaken(),
        'mode': widget.mode,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E3A8A), // Deep blue
                  Color(0xFF3B82F6), // Blue
                  Color(0xFF8B5CF6), // Purple
                  Color(0xFF6B21A8), // Deep purple
                ],
                stops: [0.0, 0.33, 0.66, 1.0],
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
                Colors.purple
              ],
            ),
          ),

          // Content
          SafeArea(
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                if (gameProvider.currentQuestion == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final question = gameProvider.currentQuestion!;
                // Update correct answer when question changes
                if (_currentQuestionIndex != gameProvider.currentQuestionIndex) {
                  _currentQuestionIndex = gameProvider.currentQuestionIndex;
                  _correctAnswer = question.correctAnswer;
                }

                return Column(
                  children: [
                    // Header
                    _buildHeader(gameProvider),
                    const SizedBox(height: 20),
                    // Question Card
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Question Counter
                              Text(
                                'Câu hỏi ${gameProvider.currentQuestionIndex + 1}/${gameProvider.totalQuestions}',
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFF06B6D4),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ).animate().fadeIn().slideY(
                                duration: 400.ms,
                                begin: -0.2,
                                curve: Curves.easeOut,
                              ),
                              
                              const SizedBox(height: 30),
                              
                              // Question Text
                              Container(
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
                                child: Text(
                                  question.question,
                                  style: GoogleFonts.bungee(
                                    fontSize: 24,
                                    color: Colors.white,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ).animate().fadeIn().scale(
                                duration: 500.ms,
                                curve: Curves.easeOut,
                              ),
                              
                              const SizedBox(height: 40),
                              
                              // Answer Options
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Column(
                                    children: [
                                      _buildAnswerButton(
                                        'A',
                                        question.optionA,
                                        gameProvider,
                                        constraints.maxWidth,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildAnswerButton(
                                        'B',
                                        question.optionB,
                                        gameProvider,
                                        constraints.maxWidth,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Feedback Overlays
          if (_showCorrectFeedback)
            _buildFeedbackOverlay(
              icon: Icons.check_circle,
              color: Colors.green,
              text: 'Chính xác!',
            ),
          if (_showIncorrectFeedback)
            _buildFeedbackOverlay(
              icon: Icons.cancel,
              color: Colors.red,
              text: 'Sai rồi!',
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/home'),
          ),
          
          // Play Attempts (Hearts)
          if (widget.mode == 'single')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D55).withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    globalPlayerName ?? 'Player',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD60A), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD60A).withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${gameProvider.score}',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(
    String option,
    String text,
    GameProvider gameProvider,
    double maxWidth,
  ) {
    final isSelected = _selectedAnswer == option;
    final isCorrect = option == _correctAnswer;
    
    // Calculate button width: 1/3 screen or full width if screen is too small
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth < 900 ? maxWidth : screenWidth / 3;
    
    Gradient? buttonGradient;
    Color? solidColor;
    Color shadowColor = const Color(0xFF5B4EFF);
    
    if (_isAnswered) {
      if (isSelected) {
        if (isCorrect) {
          buttonGradient = const LinearGradient(
            colors: [Color(0xFF00F2FF), Color(0xFF4FACFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          shadowColor = const Color(0xFF00F2FF);
        } else {
          buttonGradient = const LinearGradient(
            colors: [Color(0xFFFF2D55), Color(0xFFFF6B9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          shadowColor = const Color(0xFFFF2D55);
        }
      } else if (isCorrect) {
        buttonGradient = LinearGradient(
          colors: [
            const Color(0xFF00F2FF).withOpacity(0.3),
            const Color(0xFF4FACFE).withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        shadowColor = const Color(0xFF00F2FF);
      } else {
        buttonGradient = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        shadowColor = Colors.transparent;
      }
    } else {
      // Default gradient giống home screen buttons
      buttonGradient = LinearGradient(
        colors: [
          const Color(0xFF667eea).withOpacity(0.6),
          const Color(0xFF764ba2).withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      shadowColor = const Color(0xFF5B4EFF);
    }

    return Center(
      child: SizedBox(
        width: buttonWidth,
        child: GestureDetector(
          onTap: _isAnswered ? null : () => _handleAnswer(option, gameProvider),
          child: AnimatedContainer(
            duration: _isAnswered ? const Duration(milliseconds: 300) : Duration.zero,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: buttonGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withOpacity(_isAnswered && isSelected ? 0.6 : 0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isAnswered ? null : () => _handleAnswer(option, gameProvider),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      // Option Letter
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      
                      // Option Text
                      Expanded(
                        child: Text(
                          text,
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      
                      // Feedback Icon - Only show when answered
                      if (_isAnswered && isSelected)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ).animate().then(delay: 200.ms)
         .fadeIn(duration: 400.ms)
         .slideX(begin: -0.1, end: 0),
      ),
    );
  }

  Widget _buildFeedbackOverlay({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      color: color.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ).animate().scale(
          duration: 400.ms,
          curve: Curves.elasticOut,
        ),
      ),
    );
  }
}
