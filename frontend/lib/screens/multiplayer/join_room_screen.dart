import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';

class JoinRoomScreen extends StatefulWidget {
  final String playerName;
  const JoinRoomScreen({super.key, required this.playerName});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isJoining = true);

    try {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final roomCode = _roomCodeController.text.trim().toUpperCase();

      final success = await roomProvider.joinRoom(roomCode);

      if (success && mounted) {
        // Navigate to room lobby
        context.go('/room-lobby/$roomCode', extra: {
          'isCreator': false,
          'playerName': widget.playerName,
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể tham gia phòng. Vui lòng kiểm tra mã phòng.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tham gia phòng: $e'),
            backgroundColor: const Color(0xFFFF2D55),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
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
          'Tham gia phòng thi',
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
                          colors: [Color(0xFF00F2FF), Color(0xFF4FACFE)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F2FF).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.meeting_room,
                        size: 60,
                        color: Colors.white,
                      ),
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(height: 24),

                    Text(
                      'Nhập mã phòng',
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

                    // Room Code Input
                    TextFormField(
                      controller: _roomCodeController,
                      style: GoogleFonts.bungee(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'ABC123',
                        hintStyle: GoogleFonts.bungee(
                          color: Colors.white30,
                          fontSize: 24,
                          letterSpacing: 8,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: const Color(0xFF5B4EFF).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF00F2FF),
                            width: 3,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF2D55),
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF2D55),
                            width: 3,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                        LengthLimitingTextInputFormatter(6),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          return newValue.copyWith(
                            text: newValue.text.toUpperCase(),
                          );
                        }),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mã phòng';
                        }
                        if (value.length != 6) {
                          return 'Mã phòng phải có 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Join Button
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
                        onPressed: _isJoining ? null : _joinRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isJoining
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
                                  const Icon(Icons.login, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tham gia',
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
