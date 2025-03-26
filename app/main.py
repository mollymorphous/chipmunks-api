from contextlib import asynccontextmanager
from typing import Any, AsyncGenerator

from fastapi import FastAPI
from sqlalchemy.ext.asyncio import create_async_engine

from .settings import Settings

# Load settings from the environment
settings = Settings()  # type: ignore


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[dict[str, Any]]:
    """Manage app resources, yielded resources end up on Request.state"""

    engine = create_async_engine(settings.sqlalchemy_url())
    yield {
        "database_engine": engine,
        "settings": settings,
    }
    await engine.dispose()


app = FastAPI(
    title="Chipmunks",
    summary="Cute little inventory manager",
    lifespan=lifespan,
    debug=settings.debug_tracebacks,
    version=settings.version,
)


@app.get("/")
async def hello() -> dict[str, str]:
    return {"message": "Hello, Chipmunks!"}
