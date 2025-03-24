import pytest
from asgi_lifespan import LifespanManager
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
async def client():
    async with LifespanManager(app) as manager:
        client = AsyncClient(
            transport=ASGITransport(manager.app, root_path="/api/v1"),
            base_url="http://testserver/api/v1",
        )
        async with client:
            yield client
