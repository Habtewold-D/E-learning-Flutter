from pydantic import BaseModel, EmailStr
from app.models.user import UserRole


class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: UserRole


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: UserRole

    class Config:
        from_attributes = True
        # Pydantic v2 compatibility
        populate_by_name = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

