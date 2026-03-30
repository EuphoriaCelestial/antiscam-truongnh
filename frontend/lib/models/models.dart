class Question {
  final String question;
  final String optionA;
  final String optionB;
  final String correctAnswer; // 'A' or 'B'

  Question({
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'],
      optionA: json['optionA'],
      optionB: json['optionB'],
      correctAnswer: json['correctAnswer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'optionA': optionA,
      'optionB': optionB,
      'correctAnswer': correctAnswer,
    };
  }
}

class PropagandaMessage {
  final String id;
  final String message;
  final String? audioUrl;
  final String? imageUrl;

  PropagandaMessage({
    required this.id,
    required this.message,
    this.audioUrl,
    this.imageUrl,
  });

  factory PropagandaMessage.fromJson(Map<String, dynamic> json) {
    return PropagandaMessage(
      id: json['id'],
      message: json['message'],
      audioUrl: json['audioUrl'],
      imageUrl: json['imageUrl'],
    );
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final int playAttempts;
  final int totalScore;
  final int gamesPlayed;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.playAttempts,
    required this.totalScore,
    required this.gamesPlayed,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      playAttempts: json['play_attempts'],
      totalScore: json['total_score'],
      gamesPlayed: json['games_played'],
    );
  }
}

class Room {
  final int id;
  final String roomCode;
  final String status;
  final int currentPlayers;
  final int maxPlayers;
  final int? creatorId;
  final String? creatorName;
  final int questionCount;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.currentPlayers,
    required this.maxPlayers,
    this.creatorId,
    this.creatorName,
    this.questionCount = 10,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      roomCode: json['room_code'],
      status: json['status'],
      currentPlayers: json['current_players'],
      maxPlayers: json['max_players'],
      creatorId: json['creator_id'],
      creatorName: json['creator_name'],
      questionCount: json['question_count'] ?? 10,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class GameSession {
  final int id;
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final String mode;
  final double? timeTaken;
  final DateTime? completedAt;

  GameSession({
    required this.id,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.mode,
    this.timeTaken,
    this.completedAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'],
      score: json['score'],
      correctAnswers: json['correct_answers'],
      totalQuestions: json['total_questions'],
      mode: json['mode'],
      timeTaken: json['time_taken']?.toDouble(),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }
}

class Document {
  final int id;
  final String title;
  final String content;
  final String? author;
  final String? category;
  final String? thumbnailUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? pdfUrl;
  final String? tags;
  final bool isPublished;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.title,
    required this.content,
    this.author,
    this.category,
    this.thumbnailUrl,
    this.audioUrl,
    this.videoUrl,
    this.pdfUrl,
    this.tags,
    required this.isPublished,
    required this.viewsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'],
      category: json['category'],
      thumbnailUrl: json['thumbnail_url'],
      audioUrl: json['audio_url'],
      videoUrl: json['video_url'],
      pdfUrl: json['pdf_url'],
      tags: json['tags'],
      isPublished: json['is_published'],
      viewsCount: json['views_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class LeaderboardEntry {
  final String username;
  final int totalScore;
  final int gamesPlayed;
  final double averageScore;
  final int rank;

  LeaderboardEntry({
    required this.username,
    required this.totalScore,
    required this.gamesPlayed,
    required this.averageScore,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      username: json['username'],
      totalScore: json['total_score'],
      gamesPlayed: json['games_played'],
      averageScore: json['average_score'].toDouble(),
      rank: json['rank'],
    );
  }
}

enum AssetType { image, video, document }

class AssetItem {
  final String id;
  final String title;
  final String path;
  final AssetType type;
  final String? description;
  final DateTime? createdAt;

  AssetItem({
    required this.id,
    required this.title,
    required this.path,
    required this.type,
    this.description,
    this.createdAt,
  });

  factory AssetItem.fromMap(Map<String, dynamic> map) {
    return AssetItem(
      id: map['id'],
      title: map['title'],
      path: map['path'],
      type: AssetType.values.firstWhere((e) => e.name == map['type']),
      description: map['description'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}
