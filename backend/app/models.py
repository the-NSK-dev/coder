import uuid
from sqlalchemy import Column, String, JSON
from app.database import Base

class ProjectMemoryModel(Base):
    __tablename__ = "project_memories"

    project_id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    project_name = Column(String, index=True)
    framework = Column(String)
    architecture = Column(String)
    
    # Store lists as JSON strings in SQLite
    completed_tasks = Column(JSON, default=list)
    pending_tasks = Column(JSON, default=list)
    generated_files = Column(JSON, default=list)
    verification_history = Column(JSON, default=list)
    documentation_files = Column(JSON, default=list)
