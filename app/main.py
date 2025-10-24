"""
FastAPI Application with PostgreSQL Integration
"""
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from pydantic_settings import BaseSettings

from models.database import Base, get_db
from routes import users, health
from services.database_service import DatabaseService


class Settings(BaseSettings):
    """Application settings"""
    database_url: str = "postgresql://user:password@localhost:5432/mydb"
    app_name: str = "Python K8s App"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 8000
    
    class Config:
        env_file = ".env"


settings = Settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    print("Starting up the application...")
    
    # Create database tables
    engine = create_engine(settings.database_url)
    Base.metadata.create_all(bind=engine)
    
    yield
    
    # Shutdown
    print("Shutting down the application...")


# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    description="A production-ready Python application with PostgreSQL and Kubernetes",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router, prefix="/api/v1", tags=["health"])
app.include_router(users.router, prefix="/api/v1", tags=["users"])


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Welcome to Python K8s Application",
        "version": "1.0.0",
        "status": "running"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )
