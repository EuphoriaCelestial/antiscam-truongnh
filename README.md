# Quiz Game Web Application

A comprehensive quiz game web application with multiplayer support, real-time leaderboards, and educational document management.

## Tech Stack

**Backend:**
- Python 3.8+ with FastAPI
- SQLAlchemy ORM with SQLite
- WebSocket for real-time multiplayer
- JWT authentication

**Frontend:**
- Flutter Web 3.0+
- Provider state management
- WebSocket client
- Syncfusion PDF viewer

## Quick Setup

### Backend
```bash
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1  # Windows
pip install -r requirements.txt
python -c "from database import init_db; init_db()"
python seed_documents.py
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

## Features

- **Single Player**: 10 questions quiz with hearts system
- **Multiplayer**: Create/join rooms with 5-20 configurable questions
- **Real-time Leaderboard**: Live ranking with medals
- **Documents**: Search, filter, sort with PDF viewer support
- **Authentication**: JWT-based user system
- **WebSocket**: Real-time player synchronization

## API Endpoints

- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/questions` - Get quiz questions
- `POST /api/game-sessions` - Submit game results
- `GET /api/documents` - Get documents list
- `WebSocket /ws/room/{room_code}` - Multiplayer connection
