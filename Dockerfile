# Distroless uv image, declared here 
FROM ghcr.io/astral-sh/uv:0.6.9@sha256:cbc016e49b55190e17bfd0b89a1fdc1a54e0a54a8f737dfacc72eca9ad078338 AS uv

# Official Python image, keep version in sync with .python-version
FROM docker.io/python:3.13.2-alpine@sha256:323a717dc4a010fee21e3f1aac738ee10bb485de4e7593ce242b36ee48d6b352 AS base

# Create service working directory
WORKDIR /srv/chipmunks/api/

# Create an unprivileged app user (chipmunks-api)
RUN addgroup --system chipmunks-api && \
    adduser --system --no-create-home chipmunks-api -G chipmunks-api

# Expose app on port 8080 (HTTP Alternate)
EXPOSE 8080

# Shared environment variables
# 
# * Activate the soon-to-be virtual environment by adding it to the system path
# * Granian:
#   * Listen on all interfaces on port 8080
#   * Mount an ASGI app (specified with CMD below) under /api/v1
#   * Enable access log
# * Python:
#   * Turn off buffering for stdout and stderr for container logging
# * Uv:
#   * Compile bytecode for faster container start, at a 5-10% image size tradeoff
#   * Actually copy the dependencies into the image, since the uv cache is on a 
#     cache mount, linking them wouldn't work
#   * Disable downloading interpreters because we're in the official Python image 
ENV PATH="/srv/chipmunks/api/.venv/bin:$PATH" \
    GRANIAN_PORT=8080 \
    GRANIAN_HOST=0.0.0.0 \
    GRANIAN_INTERFACE=asgi \
    GRANIAN_URL_PATH_PREFIX=/api/v1 \
    GRANIAN_LOG_ACCESS_ENABLED=true \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

# Serve the app with Granian
CMD [ "granian", "app.main" ]

# Development target
FROM base AS dev

# Development environment variables
#
# * Granian: Set up hot reload
# * Return debug tracebacks to the client on server errors
ENV GRANIAN_RELOAD=true \
    GRANIAN_RELOAD_IGNORE_WORKER_FAILURE=true \
    GRANIAN_RELOAD_PATHS=app \
    CHIPMUNKS_DEBUG_TRACEBACKS=true

# Install uv
COPY --from=uv /uv /uvx /usr/local/bin/

# Give the working directory to the app user
RUN chown chipmunks-api:chipmunks-api /srv/chipmunks/api

# Install dependencies including dev dependencies
COPY --chown=chipmunks-api:chipmunks-api uv.lock pyproject.toml ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen

# Copy everything
COPY --chown=chipmunks-api:chipmunks-api . ./

# Switch to app user
USER chipmunks-api

# Production target
FROM base as main

# Install dependencies with compiled bytecode in a layer before the rest of the app
COPY uv.lock pyproject.toml ./
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=from=uv,source=/uv,target=/bin/uv \
    uv sync --frozen --no-dev 

# Add docs and license, followed by code
COPY *.md LICENSE.txt ./
COPY app ./app

# Compile app bytecode for faster startup
RUN python -m compileall app

# Switch to app user
USER chipmunks-api
