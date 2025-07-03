FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim@sha256:abee452509bff525494b21aea05708bfa026802b12741213594be2be13741a97

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_SYSTEM_PYTHON=true

WORKDIR /app

RUN touch README.md
COPY pyproject.toml uv.lock /app/
# install the project's dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# then the project itself
COPY . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

ENV PATH="/app/.venv/bin:$PATH"

# Reset the entrypoint, don't invoke `uv`
ENTRYPOINT []

CMD ["hello"]
