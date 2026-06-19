import os
import aiofiles
from pathlib import Path
from typing import List, Optional

class ProjectStorageService:
    def __init__(self, base_workspace_dir: str):
        self.base_workspace_dir = Path(base_workspace_dir)
        self.base_workspace_dir.mkdir(parents=True, exist_ok=True)

    def get_project_dir(self, project_id: str) -> Path:
        project_dir = self.base_workspace_dir / project_id
        project_dir.mkdir(parents=True, exist_ok=True)
        return project_dir

    async def read_file(self, project_id: str, file_path: str) -> str:
        project_dir = self.get_project_dir(project_id)
        full_path = project_dir / file_path
        
        # Security check to prevent path traversal
        if not str(full_path.resolve()).startswith(str(project_dir.resolve())):
            raise ValueError("Invalid file path: path traversal detected")
            
        async with aiofiles.open(full_path, mode='r', encoding='utf-8') as f:
            return await f.read()

    async def write_file(self, project_id: str, file_path: str, content: str) -> None:
        project_dir = self.get_project_dir(project_id)
        full_path = project_dir / file_path
        
        # Security check to prevent path traversal
        if not str(full_path.resolve()).startswith(str(project_dir.resolve())):
            raise ValueError("Invalid file path: path traversal detected")
            
        # Ensure parent directories exist
        full_path.parent.mkdir(parents=True, exist_ok=True)
        
        async with aiofiles.open(full_path, mode='w', encoding='utf-8') as f:
            await f.write(content)

    def list_files(self, project_id: str, sub_dir: Optional[str] = None) -> List[str]:
        project_dir = self.get_project_dir(project_id)
        target_dir = project_dir
        
        if sub_dir:
            target_dir = project_dir / sub_dir
            if not str(target_dir.resolve()).startswith(str(project_dir.resolve())):
                raise ValueError("Invalid sub_dir: path traversal detected")
                
        if not target_dir.exists():
            return []
            
        files = []
        for root, _, filenames in os.walk(target_dir):
            for filename in filenames:
                full_path = Path(root) / filename
                rel_path = full_path.relative_to(project_dir)
                files.append(str(rel_path).replace("\\", "/"))
        return files
