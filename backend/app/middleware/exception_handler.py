from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from app.core.exceptions import ValidationError, NotFoundError, handle_business_exception
import logging

logger = logging.getLogger(__name__)

async def business_exception_handler(request: Request, exc: Exception):
    """Handle business exceptions and return standardized JSON responses."""
    logger.error(f"Business exception: {str(exc)}")
    
    # Convert to HTTPException
    http_exc = handle_business_exception(exc)
    
    return JSONResponse(
        status_code=http_exc.status_code,
        content={
            "error": {
                "message": http_exc.detail,
                "type": exc.__class__.__name__
            }
        }
    )

async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions."""
    logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
    
    return JSONResponse(
        status_code=500,
        content={
            "error": {
                "message": "Internal server error",
                "type": "InternalServerError"
            }
        }
    )
