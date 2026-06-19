from pydantic import BaseModel, Field
from typing import List, Optional

class ProjectMemoryBase(BaseModel):
    project_name: str
    framework: str = "flutter"
    architecture: str = "mobile-first"
    completed_tasks: List[str] = Field(default_factory=list)
    pending_tasks: List[str] = Field(default_factory=list)
    generated_files: List[str] = Field(default_factory=list)
    verification_history: List[str] = Field(default_factory=list)
    documentation_files: List[str] = Field(default_factory=list)

class ProjectMemoryCreate(ProjectMemoryBase):
    pass

class ProjectMemory(ProjectMemoryBase):
    project_id: str

    class Config:
        from_attributes = True
