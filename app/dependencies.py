from typing import Annotated, AsyncGenerator

from fastapi import Depends, Request
from sqlmodel.ext.asyncio.session import AsyncSession


async def database_session(request: Request) -> AsyncGenerator[AsyncSession]:
    """Get a SQLModel-wrapped SQLAlchemy AsyncSession from app's database engine"""

    async with AsyncSession(request.state.database_engine) as session:
        yield session


DatabaseSession = Annotated[AsyncSession, Depends(database_session)]
