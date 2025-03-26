import tomllib
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


def read_pyproject_version() -> str:
    """Read version number from pyproject.toml or fall back to '0.0.0+unknown'"""
    path = Path(__file__).parent.parent / "pyproject.toml"
    if path.exists():
        with path.open("rb") as file:
            return str(tomllib.load(file)["project"]["version"])

    return "0.0.0+unknown"


class Settings(BaseSettings):
    """App settings from (in order) environment variables, .env, and Docker secrets"""

    model_config = SettingsConfigDict(
        env_prefix="chipmunks_",
        env_file=".env",
        secrets_dir="/var/run",
    )

    debug_tracebacks: bool = Field(
        default=False,
        description="Return debug tracebacks to the client on server errors",
    )

    version: str = Field(
        default_factory=read_pyproject_version,
        alias="chipmunks_api_version",
        description="Version number, from pyproject.toml by default, enabling "
        "a build to specify a development version",
    )


# Debug environment configuration by executing this file
if __name__ == "__main__":
    print(Settings().model_dump_json(indent=2))
