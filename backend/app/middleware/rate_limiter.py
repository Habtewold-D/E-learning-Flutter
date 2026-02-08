from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request, HTTPException

# Initialize rate limiter
general_limiter = Limiter(key_func=get_remote_address)

# Handle rate limit exceeded errors
async def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded):
    return HTTPException(
        status_code=429,
        detail="Too many requests. Please try again later."
    )

# Register the handler
general_limiter.error_handler = rate_limit_exceeded_handler
