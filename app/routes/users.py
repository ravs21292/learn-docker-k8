"""
User management endpoints
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from models.database import get_db
from models.user import User
from services.database_service import DatabaseService

router = APIRouter()


class UserCreate(BaseModel):
    email: str
    username: str
    full_name: str = None


class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    full_name: str = None
    is_active: bool
    created_at: str
    
    class Config:
        from_attributes = True


@router.post("/users", response_model=UserResponse)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    """Create a new user"""
    db_service = DatabaseService(db)
    
    # Check if user already exists
    existing_user = db_service.get_user_by_email(user.email)
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    existing_username = db_service.get_user_by_username(user.username)
    if existing_username:
        raise HTTPException(status_code=400, detail="Username already taken")
    
    # Create new user
    new_user = db_service.create_user(user)
    return new_user


@router.get("/users", response_model=List[UserResponse])
async def get_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all users with pagination"""
    db_service = DatabaseService(db)
    users = db_service.get_users(skip=skip, limit=limit)
    return users


@router.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get user by ID"""
    db_service = DatabaseService(db)
    user = db_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.delete("/users/{user_id}")
async def delete_user(user_id: int, db: Session = Depends(get_db)):
    """Delete user by ID"""
    db_service = DatabaseService(db)
    user = db_service.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db_service.delete_user(user_id)
    return {"message": "User deleted successfully"}
