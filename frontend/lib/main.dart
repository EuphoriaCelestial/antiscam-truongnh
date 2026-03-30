import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/room_provider.dart';
import 'providers/document_provider.dart';
import 'screens/splash_screen.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game/quiz_screen.dart';
import 'screens/game/result_screen.dart';
import 'screens/multiplayer/room_lobby_screen.dart';
import 'screens/multiplayer/create_room_screen.dart';
import 'screens/multiplayer/join_room_screen.dart';
import 'screens/multiplayer/multiplayer_leaderboard_screen.dart';
import 'screens/documents/document_list_screen.dart';
import 'screens/documents/document_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
      ],
      child: MaterialApp.router(
        title: 'Quiz Game - Educational Edition',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.robotoTextTheme(),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        routerConfig: _router(),
      ),
    );
  }

  GoRouter _router() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/quiz',
          builder: (context, state) {
            final mode = state.uri.queryParameters['mode'] ?? 'single';
            final roomCode = state.uri.queryParameters['roomCode'];
            final questionCount = state.uri.queryParameters['questionCount'];
            return QuizScreen(
              mode: mode,
              roomCode: roomCode,
              questionCount: questionCount != null ? int.tryParse(questionCount) : null,
            );
          },
        ),
        GoRoute(
          path: '/result',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ResultScreen(
              score: extra['score'] ?? 0,
              correctAnswers: extra['correctAnswers'] ?? 0,
              totalQuestions: extra['totalQuestions'] ?? 10,
              timeTaken: extra['timeTaken'] ?? 0.0,
              mode: extra['mode'] ?? 'single',
            );
          },
        ),
        GoRoute(
          path: '/create-room',
          builder: (context, state) {
            final playerName = globalPlayerName ?? '';
            return CreateRoomScreen(playerName: playerName);
          },
        ),
        GoRoute(
          path: '/join-room',
          builder: (context, state) {
            final playerName = globalPlayerName ?? '';
            return JoinRoomScreen(playerName: playerName);
          },
        ),
        GoRoute(
          path: '/room/:roomCode',
          builder: (context, state) {
            final roomCode = state.pathParameters['roomCode']!;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final playerName = extra['playerName'] ?? (globalPlayerName ?? '');
            final isCreator = extra['isCreator'] ?? false;
            return RoomLobbyScreen(roomCode: roomCode, playerName: playerName, isCreator: isCreator);
          },
        ),
        GoRoute(
          path: '/room-lobby/:roomCode',
          builder: (context, state) {
            final roomCode = state.pathParameters['roomCode']!;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final playerName = extra['playerName'] ?? (globalPlayerName ?? '');
            final isCreator = extra['isCreator'] ?? false;
            return RoomLobbyScreen(roomCode: roomCode, playerName: playerName, isCreator: isCreator);
          },
        ),
        GoRoute(
          path: '/multiplayer-result/:roomCode',
          builder: (context, state) {
            final roomCode = state.pathParameters['roomCode']!;
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return MultiplayerLeaderboardScreen(
              roomCode: roomCode,
              myScore: extra['score'] ?? 0,
              myCorrectAnswers: extra['correctAnswers'] ?? 0,
              totalQuestions: extra['totalQuestions'] ?? 10,
              myTimeTaken: extra['timeTaken'] ?? 0.0,
            );
          },
        ),
        GoRoute(
          path: '/documents',
          builder: (context, state) => const DocumentListScreen(),
        ),
        GoRoute(
          path: '/documents/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return DocumentDetailScreen(documentId: id);
          },
        ),
      ],
    );
  }
}
