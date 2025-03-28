import tomllib
from pathlib import Path

from pydantic import AnyUrl, Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import URL, make_url


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
        env_prefix="chipmunks_api_",
        env_file=".env",
        secrets_dir="/var/run",
    )

    database_url: AnyUrl = Field(
        description="SQLAlchemy Database URL, if a driver isn't specified, a "
        "supported async driver will be used"
    )

    database_password: SecretStr | None = Field(
        default=None,
        description="Specify a database password separately from URL, allowing the "
        "URL to be set by environment variable and the password by Docker secret",
    )

    debug_tracebacks: bool = Field(
        default=False,
        description="Return debug tracebacks to the client on server errors",
    )

    version: str = Field(
        default_factory=read_pyproject_version,
        description="Version number, from pyproject.toml by default, enabling "
        "a build to specify a development version",
    )

    def sqlalchemy_url(self) -> URL:
        """
        Covert database_url and database_password (if set) into a SQLAlchemy URL and
        set the driver to a supported async driver
        """

        url = make_url(str(self.database_url))

        password = None
        if self.database_password is not None:
            password = self.database_password.get_secret_value()

        driver = url.drivername
        if driver == "sqlite":
            driver = "sqlite+aiosqlite"

        return url.set(password=password, drivername=driver)


# Debug environment configuration by executing this file
if __name__ == "__main__":
    print(Settings().model_dump_json(indent=2))  # type: ignore
