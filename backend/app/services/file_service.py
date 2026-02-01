import os
from fastapi import UploadFile
from app.core.config import settings
from app.models.course import ContentType
from pathlib import Path
import cloudinary
import cloudinary.uploader


def _ensure_cloudinary_configured() -> None:
    if not settings.CLOUDINARY_CLOUD_NAME or not settings.CLOUDINARY_API_KEY or not settings.CLOUDINARY_API_SECRET:
        raise ValueError("Cloudinary is not configured")

    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True,
    )


async def save_uploaded_file(file: UploadFile, course_id: int, content_type: ContentType) -> str:
    """Upload an uploaded file to Cloudinary and return its URL."""
    _ensure_cloudinary_configured()

    if not file.filename:
        raise ValueError("File must have a filename")

    file_extension = Path(file.filename).suffix
    public_id = f"courses/{course_id}/{content_type.value}_{os.urandom(8).hex()}"

    if content_type == ContentType.VIDEO:
        result = cloudinary.uploader.upload_large(
            file.file,
            resource_type="video",
            public_id=public_id,
            use_filename=True,
            unique_filename=True,
            overwrite=False,
        )
    else:
        result = cloudinary.uploader.upload(
            file.file,
            resource_type="raw",
            public_id=public_id,
            use_filename=True,
            unique_filename=True,
            overwrite=False,
        )

    return result.get("secure_url") or result.get("url")

