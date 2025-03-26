from fastapi import FastAPI

from .settings import Settings

settings = Settings()

app = FastAPI(
    title="Chipmunks",
    summary="Cute little inventory manager",
    debug=settings.debug_tracebacks,
    version=settings.version,
)


@app.get("/")
async def hello() -> dict[str, str]:
    return {"message": "Hello, Chipmunks!"}
