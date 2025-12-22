import os
import aiofiles
from fastapi import UploadFile
from app.core.config import settings
from app.models.course import ContentType
from pathlib import Path

UPLOAD_DIR = Path(settings.UPLOAD_DIR)
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


async def save_uploaded_file(file: UploadFile, course_id: int, content_type: ContentType) -> str:
    """Save an uploaded file and return its URL/path."""
    # Create course-specific directory
    course_dir = UPLOAD_DIR / f"course_{course_id}"
    course_dir.mkdir(exist_ok=True)
    
    # Generate unique filename
    file_extension = Path(file.filename).suffix
    unique_filename = f"{content_type.value}_{os.urandom(8).hex()}{file_extension}"
    file_path = course_dir / unique_filename
    
    # Save file
    async with aiofiles.open(file_path, 'wb') as f:
        content = await file.read()
        await f.write(content)
    
    # Return relative path for URL
    return str(file_path.relative_to(UPLOAD_DIR))

