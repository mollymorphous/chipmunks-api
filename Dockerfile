# Distroless uv image
FROM ghcr.io/astral-sh/uv:0.6.10@sha256:57da96c4557243fc0a732817854084e81af9393f64dc7d172f39c16465b5e2ba AS uv

# Official Python image, keep version in sync with .python-version
FROM docker.io/python:3.13.2-alpine@sha256:323a717dc4a010fee21e3f1aac738ee10bb485de4e7593ce242b36ee48d6b352 AS main

# Create service working directory
WORKDIR /srv/chipmunks/api/

# Create an unprivileged app user (chipmunks-api)
RUN addgroup --system chipmunks-api && \
    adduser --system --no-create-home chipmunks-api -G chipmunks-api

# Static environment variables, set before app build for caching 
#
# PATH: Activate the soon-to-be-created virtual environment
# GRANIAN_*: Listen on port 8080, all interfaces, expect an ASGI app, enable access
#            log, serve the app under /api/v1
# PYTHONUNBUFFERED: Disables buffering no STDOUT and STDERR, which improves logging
#                   performance because the container engine handles buffering
# PYTHONWRITEBYTECODE: Disable writing bytecode at runtime, because we precompile 
#                      bytecode, and the app user doesn't have write access anyway
ENV PATH="/srv/chipmunks/api/.venv/bin:$PATH" \
    GRANIAN_PORT=8080 \
    GRANIAN_HOST=0.0.0.0 \
    GRANIAN_INTERFACE=asgi \
    GRANIAN_LOG_ACCESS_ENABLED=true \
    GRANIAN_URL_PATH_PREFIX=/api/v1 \
    PYTHONUNBUFFERED=1 \
    PYTHONWRITEBYTECODE=0

# Expose app on port 8080 (HTTP Alternate)
EXPOSE 8080

# Serve the app with Granian
CMD [ "granian", "app.main" ]

# Add minimum files to install dependencies, plus the license because it's static
COPY pyproject.toml uv.lock LICENSE.txt ./

# Install dependencies with compiled bytecode in a layer before the rest of the app
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=from=uv,source=/uv,target=/bin/uv \
    uv sync --frozen --no-dev --compile-bytecode --link-mode=copy --no-python-downloads

# Add code and compile bytecode
COPY app ./app
RUN python -m compileall app

# Switch to app user
USER chipmunks-api
