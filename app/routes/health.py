"""
Health check endpoints
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from models.database import get_db

router = APIRouter()


@router.get("/health")
async def health_check():
    """Basic health check"""
    return {"status": "healthy", "service": "python-k8s-app"}


@router.get("/health/ready")
async def readiness_check(db: Session = Depends(get_db)):
    """Readiness check with database connectivity"""
    try:
        # Test database connection
        db.execute(text("SELECT 1"))
        return {
            "status": "ready",
            "database": "connected",
            "service": "python-k8s-app"
        }
    except Exception as e:
        return {
            "status": "not_ready",
            "database": "disconnected",
            "error": str(e),
            "service": "python-k8s-app"
        }


@router.get("/health/live")
async def liveness_check():
    """Liveness check"""
    return {"status": "alive", "service": "python-k8s-app"}
