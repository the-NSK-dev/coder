from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List

from app.database import engine, Base, get_db
from app import models, schemas

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Band.ai Agentic IDE Orchestrator")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],            # local dev; lock down in prod
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        # Create tables
        await conn.run_sync(Base.metadata.create_all)

@app.get("/")
def read_root():
    return {"message": "Band.ai Orchestrator API is running"}

@app.post("/projects/", response_model=schemas.ProjectMemory)
async def create_project(project: schemas.ProjectMemoryCreate, db: AsyncSession = Depends(get_db)):
    db_project = models.ProjectMemoryModel(**project.model_dump())
    db.add(db_project)
    await db.commit()
    await db.refresh(db_project)
    return db_project

@app.get("/projects/{project_id}", response_model=schemas.ProjectMemory)
async def get_project(project_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.ProjectMemoryModel).where(models.ProjectMemoryModel.project_id == project_id))
    db_project = result.scalars().first()
    if db_project is None:
        raise HTTPException(status_code=404, detail="Project not found")
    return db_project

@app.get("/projects/", response_model=List[schemas.ProjectMemory])
async def list_projects(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.ProjectMemoryModel))
    return result.scalars().all()

@app.patch("/projects/{project_id}/complete-task")
async def complete_task(
    project_id: str, task: str, db: AsyncSession = Depends(get_db)
):
    result = await db.get(models.ProjectMemoryModel, project_id)
    if not result:
        raise HTTPException(404, "Project not found")
    pending = list(result.pending_tasks or [])
    completed = list(result.completed_tasks or [])
    if task in pending:
        pending.remove(task)
        completed.append(task)
    result.pending_tasks = pending
    result.completed_tasks = completed
    await db.commit()
    await db.refresh(result)
    return result
