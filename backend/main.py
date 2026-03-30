from fastapi import FastAPI, Depends, HTTPException, status, WebSocket, WebSocketDisconnect, Request
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import timedelta, datetime
from pydantic import BaseModel, ValidationError
import string
import random
import json

from database import get_db, init_db
from models import User, Room, GameSession, Document, Leaderboard, RoomStatus, GameMode
from auth import (
    authenticate_user, create_access_token, get_current_user,
    UserCreate, UserResponse, Token, create_user, sanitize_input,
    rate_limiter, ACCESS_TOKEN_EXPIRE_MINUTES
)

app = FastAPI(title="Quiz Game API", version="1.0.0")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom validation error handler
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    print(f"Validation error: {errors}")  # Log for debugging
    
    # Format errors to be JSON serializable
    formatted_errors = []
    for error in errors:
        formatted_error = {
            "loc": error["loc"],
            "msg": error["msg"],
            "type": error["type"]
        }
        formatted_errors.append(formatted_error)
    
    return JSONResponse(
        status_code=422,
        content={"detail": formatted_errors}
    )


# Initialize database on startup
@app.on_event("startup")
async def startup_event():
    init_db()
    print("Database initialized successfully")


# ===========================
# Pydantic Schemas
# ===========================

class RoomCreate(BaseModel):
    max_players: int = 10


class RoomResponse(BaseModel):
    id: int
    room_code: str
    status: str
    current_players: int
    max_players: int
    created_at: datetime

    class Config:
        from_attributes = True


class GameSessionCreate(BaseModel):
    mode: str
    room_id: Optional[int] = None
    score: int
    correct_answers: int
    total_questions: int = 10
    time_taken: Optional[float] = None


class GameSessionResponse(BaseModel):
    id: int
    score: int
    correct_answers: int
    total_questions: int
    mode: str
    time_taken: Optional[float]
    completed_at: Optional[datetime]

    class Config:
        from_attributes = True


class DocumentCreate(BaseModel):
    title: str
    content: str
    author: Optional[str] = None
    category: Optional[str] = None
    thumbnail_url: Optional[str] = None
    audio_url: Optional[str] = None
    video_url: Optional[str] = None
    pdf_url: Optional[str] = None
    tags: Optional[str] = None


class DocumentUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    author: Optional[str] = None
    category: Optional[str] = None
    thumbnail_url: Optional[str] = None
    audio_url: Optional[str] = None
    video_url: Optional[str] = None
    pdf_url: Optional[str] = None
    tags: Optional[str] = None
    is_published: Optional[bool] = None


class DocumentResponse(BaseModel):
    id: int
    title: str
    content: str
    author: Optional[str]
    category: Optional[str]
    thumbnail_url: Optional[str]
    audio_url: Optional[str]
    video_url: Optional[str]
    pdf_url: Optional[str]
    tags: Optional[str]
    is_published: bool
    views_count: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class LeaderboardEntry(BaseModel):
    username: str
    total_score: int
    games_played: int
    average_score: float
    rank: int

    class Config:
        from_attributes = True


# ===========================
# Authentication Endpoints
# ===========================

@app.post("/api/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    try:
        # Sanitize inputs
        user.username = sanitize_input(user.username, 50)
        user.email = sanitize_input(user.email, 100)
        if user.full_name:
            user.full_name = sanitize_input(user.full_name, 100)
        
        db_user = create_user(db, user)
        return db_user
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )


@app.post("/api/token", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login and get access token"""
    user = authenticate_user(db, form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@app.get("/api/users/me", response_model=UserResponse)
def read_users_me(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    return current_user


@app.patch("/api/users/me/play-attempts")
def update_play_attempts(
    attempts: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update user's play attempts (admin or reward system)"""
    current_user.play_attempts = max(0, attempts)
    db.commit()
    return {"play_attempts": current_user.play_attempts}


# ===========================
# Room Management Endpoints
# ===========================

def generate_room_code() -> str:
    """Generate unique 6-character room code"""
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))


@app.post("/api/rooms", response_model=RoomResponse)
def create_room(
    room_data: RoomCreate,
    db: Session = Depends(get_db)
):
    """Create a new multiplayer room"""
    # Generate unique room code
    room_code = generate_room_code()
    while db.query(Room).filter(Room.room_code == room_code).first():
        room_code = generate_room_code()
    
    room = Room(
        room_code=room_code,
        creator_id=None,  # No auth, so no creator
        max_players=min(room_data.max_players, 50),  # Cap at 50 players
        status=RoomStatus.WAITING
    )
    db.add(room)
    db.commit()
    db.refresh(room)
    return room


@app.get("/api/rooms/{room_code}", response_model=RoomResponse)
def get_room(room_code: str, db: Session = Depends(get_db)):
    """Get room details by code"""
    room_code = sanitize_input(room_code, 10).upper()
    room = db.query(Room).filter(Room.room_code == room_code).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    return room


@app.post("/api/rooms/{room_code}/join")
def join_room(
    room_code: str,
    db: Session = Depends(get_db)
):
    """Join an existing room"""
    room_code = sanitize_input(room_code, 10).upper()
    room = db.query(Room).filter(Room.room_code == room_code).first()
    
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    if room.status != RoomStatus.WAITING:
        raise HTTPException(status_code=400, detail="Room is not accepting new players")
    
    if room.current_players >= room.max_players:
        raise HTTPException(status_code=400, detail="Room is full")
    
    room.current_players += 1
    db.commit()
    
    return {"message": "Joined room successfully", "room": room}


@app.post("/api/rooms/{room_code}/start")
def start_room(
    room_code: str,
    db: Session = Depends(get_db)
):
    """Start the game in a room"""
    room_code = sanitize_input(room_code, 10).upper()
    room = db.query(Room).filter(Room.room_code == room_code).first()
    
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    if room.status != RoomStatus.WAITING:
        raise HTTPException(status_code=400, detail="Room already started or finished")
    
    room.status = RoomStatus.IN_PROGRESS
    room.started_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Game started", "room": room}


# ===========================
# Game Session Endpoints
# ===========================

@app.post("/api/game-sessions", response_model=GameSessionResponse)
def create_game_session(
    session_data: GameSessionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Record a completed game session"""
    # Check play attempts for single player
    if session_data.mode == "single_player":
        if current_user.play_attempts <= 0:
            raise HTTPException(
                status_code=400,
                detail="No play attempts remaining"
            )
        current_user.play_attempts -= 1
    
    # Create game session
    game_session = GameSession(
        user_id=current_user.id,
        room_id=session_data.room_id,
        mode=GameMode(session_data.mode),
        score=session_data.score,
        correct_answers=session_data.correct_answers,
        total_questions=session_data.total_questions,
        time_taken=session_data.time_taken,
        completed_at=datetime.utcnow()
    )
    db.add(game_session)
    
    # Update user stats
    current_user.total_score += session_data.score
    current_user.games_played += 1
    
    # Update or create leaderboard entry
    leaderboard_entry = db.query(Leaderboard).filter(
        Leaderboard.user_id == current_user.id
    ).first()
    
    if leaderboard_entry:
        leaderboard_entry.total_score = current_user.total_score
        leaderboard_entry.games_played = current_user.games_played
        leaderboard_entry.average_score = current_user.total_score / current_user.games_played
        if session_data.time_taken:
            if not leaderboard_entry.best_time or session_data.time_taken < leaderboard_entry.best_time:
                leaderboard_entry.best_time = session_data.time_taken
    else:
        leaderboard_entry = Leaderboard(
            user_id=current_user.id,
            total_score=current_user.total_score,
            games_played=current_user.games_played,
            average_score=current_user.total_score / current_user.games_played,
            best_time=session_data.time_taken
        )
        db.add(leaderboard_entry)
    
    db.commit()
    db.refresh(game_session)
    
    return game_session


@app.get("/api/game-sessions/my-history", response_model=List[GameSessionResponse])
def get_my_game_history(
    skip: int = 0,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's game history"""
    sessions = db.query(GameSession).filter(
        GameSession.user_id == current_user.id
    ).order_by(GameSession.completed_at.desc()).offset(skip).limit(limit).all()
    
    return sessions


@app.get("/api/rooms/{room_code}/leaderboard", response_model=List[LeaderboardEntry])
def get_room_leaderboard(room_code: str, db: Session = Depends(get_db)):
    """Get leaderboard for a specific room"""
    room_code = sanitize_input(room_code, 10).upper()
    room = db.query(Room).filter(Room.room_code == room_code).first()
    
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    
    # Get all sessions for this room
    sessions = db.query(GameSession).filter(
        GameSession.room_id == room.id
    ).order_by(GameSession.score.desc(), GameSession.time_taken.asc()).all()
    
    leaderboard = []
    for rank, session in enumerate(sessions, start=1):
        user = db.query(User).filter(User.id == session.user_id).first()
        if user:
            leaderboard.append({
                "username": user.username,
                "total_score": session.score,
                "games_played": 1,
                "average_score": float(session.score),
                "rank": rank
            })
    
    return leaderboard


@app.get("/api/leaderboard/global", response_model=List[LeaderboardEntry])
def get_global_leaderboard(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get global leaderboard"""
    leaderboard_entries = db.query(Leaderboard, User).join(
        User, Leaderboard.user_id == User.id
    ).order_by(
        Leaderboard.total_score.desc(),
        Leaderboard.best_time.asc()
    ).offset(skip).limit(limit).all()
    
    result = []
    for rank, (entry, user) in enumerate(leaderboard_entries, start=1):
        result.append({
            "username": user.username,
            "total_score": entry.total_score,
            "games_played": entry.games_played,
            "average_score": entry.average_score,
            "rank": rank
        })
    
    return result


# ===========================
# Document Management Endpoints
# ===========================

@app.post("/api/documents", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
def create_document(
    document: DocumentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new document (admin feature)"""
    # Sanitize inputs
    document.title = sanitize_input(document.title, 200)
    document.content = sanitize_input(document.content, 50000)
    
    db_document = Document(
        title=document.title,
        content=document.content,
        author=document.author or current_user.username,
        category=document.category,
        thumbnail_url=document.thumbnail_url,
        audio_url=document.audio_url,
        video_url=document.video_url,
        pdf_url=document.pdf_url,
        tags=document.tags
    )
    db.add(db_document)
    db.commit()
    db.refresh(db_document)
    return db_document


@app.get("/api/documents", response_model=List[DocumentResponse])
def get_documents(
    skip: int = 0,
    limit: int = 20,
    category: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get all published documents"""
    query = db.query(Document).filter(Document.is_published == True)
    
    if category:
        category = sanitize_input(category, 50)
        query = query.filter(Document.category == category)
    
    documents = query.order_by(Document.created_at.desc()).offset(skip).limit(limit).all()
    return documents


@app.get("/api/documents/{document_id}", response_model=DocumentResponse)
def get_document(document_id: int, db: Session = Depends(get_db)):
    """Get a specific document and increment view count"""
    document = db.query(Document).filter(Document.id == document_id).first()
    
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    
    # Increment view count
    document.views_count += 1
    db.commit()
    db.refresh(document)
    
    return document


@app.patch("/api/documents/{document_id}", response_model=DocumentResponse)
def update_document(
    document_id: int,
    document_update: DocumentUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a document (admin feature)"""
    document = db.query(Document).filter(Document.id == document_id).first()
    
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    
    # Update fields
    update_data = document_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        if field in ['title', 'content', 'author']:
            value = sanitize_input(str(value), 50000 if field == 'content' else 200)
        setattr(document, field, value)
    
    document.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(document)
    
    return document


@app.delete("/api/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a document (admin feature)"""
    document = db.query(Document).filter(Document.id == document_id).first()
    
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    
    db.delete(document)
    db.commit()
    
    return None


# ===========================
# WebSocket for Multiplayer
# ===========================

class ConnectionManager:
    """Manage WebSocket connections for multiplayer rooms"""
    def __init__(self):
        self.active_connections: dict[str, List[tuple[WebSocket, str]]] = {}  # room_code -> [(websocket, username)]
        self.room_players: dict[str, List[dict]] = {}  # room_code -> [player_info]
    
    async def connect(self, room_code: str, websocket: WebSocket, username: str):
        await websocket.accept()
        if room_code not in self.active_connections:
            self.active_connections[room_code] = []
            self.room_players[room_code] = []
        
        self.active_connections[room_code].append((websocket, username))
        
        # Add player to room
        is_host = len(self.room_players[room_code]) == 0
        player_info = {
            'username': username,
            'isHost': is_host
        }
        self.room_players[room_code].append(player_info)
        
        # Broadcast updated player list to all clients in room
        await self.broadcast(room_code, {
            'type': 'players_updated',
            'players': self.room_players[room_code]
        })
    
    def disconnect(self, room_code: str, websocket: WebSocket):
        if room_code in self.active_connections:
            # Find and remove the connection
            username = None
            for conn, uname in self.active_connections[room_code]:
                if conn == websocket:
                    username = uname
                    break
            
            self.active_connections[room_code] = [(ws, un) for ws, un in self.active_connections[room_code] if ws != websocket]
            
            # Remove player from room
            if username and room_code in self.room_players:
                self.room_players[room_code] = [p for p in self.room_players[room_code] if p['username'] != username]
            
            # Clean up empty rooms
            if not self.active_connections[room_code]:
                del self.active_connections[room_code]
                if room_code in self.room_players:
                    del self.room_players[room_code]
    
    async def send_personal_message(self, message: dict, websocket: WebSocket):
        await websocket.send_text(json.dumps(message))
    
    async def broadcast(self, room_code: str, message: dict):
        if room_code in self.active_connections:
            connections = self.active_connections[room_code][:]
            for websocket, username in connections:
                try:
                    await websocket.send_text(json.dumps(message))
                except WebSocketDisconnect:
                    await self.disconnect(room_code, websocket)


manager = ConnectionManager()


@app.websocket("/ws/room/{room_code}")
async def websocket_endpoint(websocket: WebSocket, room_code: str, username: str = "Anonymous"):
    """WebSocket endpoint for real-time room communication"""
    await manager.connect(room_code, websocket, username)
    print(f"WebSocket connected: room={room_code}, user={username}")
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data) 
            print(f"WebSocket message received in room {room_code}: {message}")
            
            # Handle different message types
            if message.get("type") == "game_started":
                print(f"Broadcasting game_started for room {room_code}")
                await manager.broadcast(room_code, {
                    "type": "game_started",
                    "roomCode": room_code,
                    "questionCount": message.get("questionCount", 10),
                    "timestamp": datetime.utcnow().isoformat()
                })
            elif message.get("type") == "player_finished":
                print(f"Player finished: {message}")
                await manager.broadcast(room_code, {
                    "type": "player_finished",
                    "username": message.get("username"),
                    "score": message.get("score"),
                    "correctAnswers": message.get("correctAnswers"),
                    "timeTaken": message.get("timeTaken")
                })
            elif message.get("type") == "game_ended":
                await manager.broadcast(room_code, {
                    "type": "game_ended",
                    "leaderboard": message.get("leaderboard")
                })
            else:
                # Echo other messages
                await manager.broadcast(room_code, message)
    
    except WebSocketDisconnect:
        await manager.disconnect(room_code, websocket)
        # Broadcast updated player list after disconnect
        if room_code in manager.room_players:
            await manager.broadcast(room_code, {
                "type": "players_updated",
                "players": manager.room_players[room_code]
            })


# ===========================
# Health Check
# ===========================

@app.get("/")
def root():
    return {"message": "Quiz Game API is running", "version": "1.0.0"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
