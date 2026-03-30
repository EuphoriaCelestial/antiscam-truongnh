"""
Script to seed sample documents into the database
Run: python seed_documents.py
"""

from sqlalchemy.orm import Session
from database import SessionLocal, init_db
from models import Document
from datetime import datetime

def seed_documents():
    """Add sample documents to the database"""
    # Initialize database tables
    init_db()
    
    db: Session = SessionLocal()
    
    try:
        # Check if documents already exist
        existing = db.query(Document).first()
        if existing:
            print("⚠️  Documents already exist. Skipping seed.")
            print("   To re-seed, delete quiz_game.db and run again.")
            return
        
        # Sample documents with PDF
        documents = [
            {
                "title": "Lorem Ipsum - Tài liệu mẫu",
                "content": """Lorem Ipsum là một đoạn văn bản giả được sử dụng trong ngành in ấn và sắp chữ. 
Lorem Ipsum đã trở thành văn bản mẫu tiêu chuẩn của ngành in ấn từ những năm 1500.

Nội dung đầy đủ có trong file PDF đính kèm. Tài liệu này được sử dụng để kiểm tra và demo 
tính năng hiển thị PDF trong ứng dụng web.""",
                "author": "Admin",
                "category": "Security",
                "thumbnail_url": None,
                "audio_url": None,
                "video_url": None,
                "pdf_url": "assets/pdf/lorem-ipsum.pdf",
                "tags": "demo,pdf,sample",
                "is_published": True,
                "views_count": 0,
            },
            {
                "title": "Hướng dẫn an toàn thông tin mạng",
                "content": """Tài liệu hướng dẫn các biện pháp bảo mật cơ bản khi sử dụng internet.
                
1. Sử dụng mật khẩu mạnh
2. Không chia sẻ thông tin cá nhân
3. Cẩn thận với email và link lạ
4. Cập nhật phần mềm thường xuyên
5. Sử dụng xác thực hai yếu tố

Hãy luôn cảnh giác với các thủ đoạn lừa đảo qua mạng.""",
                "author": "Công An Phường An Hội Tây",
                "category": "Security",
                "thumbnail_url": None,
                "audio_url": None,
                "video_url": None,
                "pdf_url": None,
                "tags": "security,safety,guide",
                "is_published": True,
                "views_count": 0,
            },
            {
                "title": "Nhận biết các chiêu trò lừa đảo phổ biến",
                "content": """Các hình thức lừa đảo phổ biến hiện nay:

🚫 Giả mạo ngân hàng, cơ quan nhà nước
🚫 Đầu tư tài chính hứa lợi nhuận cao
🚫 Mua bán online giao dịch ngoài sàn
🚫 Giả danh người thân qua mạng xã hội
🚫 Phishing qua email, SMS

Luôn kiểm tra kỹ thông tin trước khi giao dịch. Khi nghi ngờ, hãy liên hệ cơ quan chức năng.""",
                "author": "Công An Phường An Hội Tây",
                "category": "Scam Prevention",
                "thumbnail_url": None,
                "audio_url": None,
                "video_url": None,
                "pdf_url": None,
                "tags": "scam,fraud,prevention",
                "is_published": True,
                "views_count": 0,
            },
            {
                "title": "Bảo vệ thông tin cá nhân trên mạng xã hội",
                "content": """Hướng dẫn bảo vệ quyền riêng tư trên các nền tảng mạng xã hội:

✅ Cài đặt quyền riêng tư cho tài khoản
✅ Kiểm soát người xem thông tin cá nhân
✅ Không đăng thông tin nhạy cảm
✅ Cẩn thận với ứng dụng bên thứ ba
✅ Thường xuyên rà soát cài đặt bảo mật

Thông tin cá nhân là tài sản quý giá, hãy bảo vệ nó!""",
                "author": "Chi Đoàn Công An",
                "category": "Privacy",
                "thumbnail_url": None,
                "audio_url": None,
                "video_url": None,
                "pdf_url": None,
                "tags": "privacy,social-media,personal-data",
                "is_published": True,
                "views_count": 0,
            },
            {
                "title": "Quy định pháp luật về an ninh mạng Việt Nam",
                "content": """Tổng quan về các văn bản pháp luật liên quan đến an ninh mạng:

📜 Luật An ninh mạng 2018
📜 Nghị định 85/2016/NĐ-CP về bảo vệ dữ liệu cá nhân
📜 Nghị định 15/2020/NĐ-CP về xử phạt vi phạm hành chính
📜 Luật An toàn thông tin mạng

Mọi công dân có trách nhiệm tuân thủ pháp luật và bảo vệ an ninh mạng quốc gia.""",
                "author": "Công An Phường An Hội Tây",
                "category": "Legal",
                "thumbnail_url": None,
                "audio_url": None,
                "video_url": None,
                "pdf_url": None,
                "tags": "legal,law,regulation",
                "is_published": True,
                "views_count": 0,
            },
        ]
        
        # Add documents to database
        for doc_data in documents:
            document = Document(**doc_data)
            db.add(document)
        
        db.commit()
        print(f"✅ Successfully seeded {len(documents)} documents!")
        print("\nDocuments added:")
        for doc in documents:
            pdf_status = "📄 PDF" if doc.get("pdf_url") else "📝 Text"
            print(f"  {pdf_status} - {doc['title']}")
        
    except Exception as e:
        print(f"❌ Error seeding documents: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("🌱 Seeding documents...")
    seed_documents()
    print("\n✅ Done! Start the server to see documents in the app.")
