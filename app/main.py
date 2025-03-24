from fastapi import FastAPI

app = FastAPI(
    title="Chipmunks",
    summary="Cute little inventory manager",
)


@app.get("/")
async def hello() -> dict[str, str]:
    return {"message": "Hello, Chipmunks!"}
