import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import '../../providers/game_provider.dart';
// import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../models/models.dart';

class CreateRoomScreen extends StatefulWidget {
  final String playerName;
  const CreateRoomScreen({super.key, required this.playerName});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  int _maxPlayers = 4;
  int _questionCount = 10;
  bool _isCreating = false;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final room = await roomProvider.createRoom(maxPlayers: _maxPlayers, questionCount: _questionCount);

      if (room != null && mounted) {
        // Navigate to room lobby
        context.go('/room-lobby/${room.roomCode}', extra: {
          'isCreator': true,
          'playerName': widget.playerName,
          'questionCount': _questionCount,
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tạo phòng. Vui lòng thử lại.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo phòng: $e'),
            backgroundColor: const Color(0xFFFF2D55),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Tạo phòng thi',
          style: GoogleFonts.bungee(
            color: const Color(0xFFFFD60A),
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667eea).withOpacity(0.2),
                    const Color(0xFF764ba2).withOpacity(0.2),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B4EFF), Color(0xFF9D50BB)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B4EFF).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.group_add,
                        size: 60,
                        color: Colors.white,
                      ),
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(height: 24),

                    Text(
                      'Thiết lập phòng thi',
                      style: GoogleFonts.bungee(
                        fontSize: 24,
                        color: const Color(0xFFFFD60A),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD60A).withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 32),

                    // Max Players
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF5B4EFF).withOpacity(0.3),
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
                                'Số người chơi tối đa',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00F2FF), Color(0xFF4FACFE)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_maxPlayers',
                                  style: GoogleFonts.bungee(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFF00F2FF),
                              inactiveTrackColor: Colors.white.withOpacity(0.1),
                              thumbColor: const Color(0xFF00F2FF),
                              overlayColor: const Color(0xFF00F2FF).withOpacity(0.3),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                            ),
                            child: Slider(
                              value: _maxPlayers.toDouble(),
                              min: 2,
                              max: 10,
                              divisions: 8,
                              onChanged: (value) {
                                setState(() => _maxPlayers = value.toInt());
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Question Count
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF5B4EFF).withOpacity(0.3),
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
                                'Số câu hỏi',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD60A), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_questionCount',
                                  style: GoogleFonts.bungee(
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFFFFD60A),
                              inactiveTrackColor: Colors.white.withOpacity(0.1),
                              thumbColor: const Color(0xFFFFD60A),
                              overlayColor: const Color(0xFFFFD60A).withOpacity(0.3),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                            ),
                            child: Slider(
                              value: _questionCount.toDouble(),
                              min: 5,
                              max: 20,
                              divisions: 15,
                              onChanged: (value) {
                                setState(() => _questionCount = value.toInt());
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Create Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B4EFF), Color(0xFF9D50BB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5B4EFF).withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _createRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isCreating
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
                                  const Icon(Icons.add_circle, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tạo phòng',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2, duration: 400.ms),
          ),
        ),
      ),
    );
  }
}
