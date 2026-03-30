from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float, Enum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime
import enum

Base = declarative_base()


class User(Base):
    """User model with authentication and game state"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    play_attempts = Column(Integer, default=5)  # Hearts/Credits
    total_score = Column(Integer, default=0)
    games_played = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    # Relationships
    game_sessions = relationship("GameSession", back_populates="user")
    created_rooms = relationship("Room", back_populates="creator")


class RoomStatus(str, enum.Enum):
    WAITING = "waiting"
    IN_PROGRESS = "in_progress"
    FINISHED = "finished"


class Room(Base):
    """Multiplayer room model"""
    __tablename__ = "rooms"

    id = Column(Integer, primary_key=True, index=True)
    room_code = Column(String(6), unique=True, index=True, nullable=False)  # e.g., "XYS12A"
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    status = Column(Enum(RoomStatus), default=RoomStatus.WAITING)
    max_players = Column(Integer, default=10)
    current_players = Column(Integer, default=1)
    created_at = Column(DateTime, default=datetime.utcnow)
    started_at = Column(DateTime, nullable=True)
    finished_at = Column(DateTime, nullable=True)

    # Relationships
    creator = relationship("User", back_populates="created_rooms")
    game_sessions = relationship("GameSession", back_populates="room")


class GameMode(str, enum.Enum):
    SINGLE_PLAYER = "single_player"
    MULTIPLAYER = "multiplayer"


class GameSession(Base):
    """Individual game session record"""
    __tablename__ = "game_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    room_id = Column(Integer, ForeignKey("rooms.id"), nullable=True)  # NULL for single player
    mode = Column(Enum(GameMode), nullable=False)
    score = Column(Integer, default=0)  # Score out of 10
    correct_answers = Column(Integer, default=0)
    total_questions = Column(Integer, default=10)
    time_taken = Column(Float, nullable=True)  # Seconds
    started_at = Column(DateTime, default=datetime.utcnow)
    completed_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="game_sessions")
    room = relationship("Room", back_populates="game_sessions")


class Document(Base):
    """Document model for reading/propaganda content"""
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    content = Column(Text, nullable=False)
    author = Column(String(100))
    category = Column(String(50))
    thumbnail_url = Column(String(500), nullable=True)
    is_published = Column(Boolean, default=True)
    views_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Metadata for rich content
    audio_url = Column(String(500), nullable=True)
    video_url = Column(String(500), nullable=True)
    pdf_url = Column(String(500), nullable=True)
    tags = Column(String(500), nullable=True)  # Comma-separated tags


class Leaderboard(Base):
    """Global leaderboard cache/view"""
    __tablename__ = "leaderboard"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    total_score = Column(Integer, default=0)
    games_played = Column(Integer, default=0)
    average_score = Column(Float, default=0.0)
    best_time = Column(Float, nullable=True)
    rank = Column(Integer, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User")
