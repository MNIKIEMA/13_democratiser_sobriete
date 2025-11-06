# ===============================
# Stage: Base Builder
# ===============================
FROM python:3.10-slim AS base-builder

RUN apt-get update -qqy && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        libpoppler-dev \
        unzip \
        curl \
        cargo \
        git \
        ssh \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    UV_SYSTEM_PYTHON=1

WORKDIR /app

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

# Copy kotaemon-related files
COPY ../kotaemon /app/kotaemon
COPY flowsettings.py /app/flowsettings.py

# Download pdfjs
RUN chmod +x kotaemon/scripts/download_pdfjs.sh
ENV PDFJS_PREBUILT_DIR="/app/kotaemon/libs/ktem/ktem/assets/prebuilt/pdfjs-dist"
RUN bash kotaemon/scripts/download_pdfjs.sh $PDFJS_PREBUILT_DIR

# Sync dependencies via uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-cache


# ===============================
# Stage: dev (editable installs)
# ===============================
FROM base-builder AS dev

RUN uv pip install -e "/app/kotaemon/libs/kotaemon[adv]" && \
    uv pip install -e "/app/kotaemon/libs/ktem" && \
    uv pip install -e "/app/kotaemon/libs/pipelineblocks" && \
    uv pip install boto3 && \
    uv pip install "pdfservices-sdk@git+https://github.com/niallcm/pdfservices-python-sdk.git@bump-and-unfreeze-requirements"


# ===============================
# Stage: prod (non-editable installs)
# ===============================
FROM base-builder AS prod

RUN uv pip install "/app/kotaemon/libs/kotaemon[adv]" && \
    uv pip install "/app/kotaemon/libs/ktem" && \
    uv pip install "/app/kotaemon/libs/pipelineblocks" && \
    uv pip install boto3 && \
    uv pip install "pdfservices-sdk@git+https://github.com/niallcm/pdfservices-python-sdk.git@bump-and-unfreeze-requirements"


# ===============================
# Shared minimal runtime base
# ===============================
FROM python:3.10-slim AS runtime-base

RUN apt-get update -qqy && \
    apt-get install -y --no-install-recommends \
        ssh \
        git \
        poppler-utils \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8

WORKDIR /app


# ===============================
# Final: dev-runtime
# ===============================
FROM runtime-base AS dev-runtime

COPY --from=dev /app /app
COPY --from=dev /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=dev /usr/local/bin /usr/local/bin

ENTRYPOINT ["/bin/bash"]


# ===============================
# Final: prod-runtime
# ===============================
FROM runtime-base AS prod-runtime

COPY --from=prod /app /app
COPY --from=prod /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=prod /usr/local/bin /usr/local/bin

RUN chmod +x /app/kotaemon/launch.sh
ENTRYPOINT ["sh", "/app/kotaemon/launch.sh"]
