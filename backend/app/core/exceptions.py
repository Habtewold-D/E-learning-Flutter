class ValidationError(Exception):
    """Raised when validation fails."""
    pass


class NotFoundError(Exception):
    """Raised when a resource is not found."""
    pass


class BusinessError(Exception):
    """Base class for business logic errors."""
    pass


def handle_business_exception(e: Exception):
    """Convert business exceptions to HTTPException format."""
    from fastapi import HTTPException

    if isinstance(e, HTTPException):
        return e
    
    if isinstance(e, NotFoundError):
        return HTTPException(status_code=404, detail=str(e))
    elif isinstance(e, ValidationError):
        return HTTPException(status_code=400, detail=str(e))
    else:
        return HTTPException(status_code=500, detail="Internal server error")
