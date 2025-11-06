# =======================================
# Stage 1: Base Image (Lite)
# =======================================
FROM python:3.10-slim AS lite

# System dependencies
RUN apt-get update -qqy && \
    apt-get install -y --no-install-recommends \
        ssh \
        git \
        gcc \
        g++ \
        poppler-utils \
        libpoppler-dev \
        unzip \
        curl \
        cargo && \
    rm -rf /var/lib/apt/lists/*

# Environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    UV_SYSTEM_PYTHON=1

# Working directory
WORKDIR /app

# Install uv (fast Python package manager)
ADD https://astral.sh/uv/install.sh /uv-installer.sh
RUN sh /uv-installer.sh && rm /uv-installer.sh
ENV PATH="/root/.local/bin/:$PATH"

# Copy relevant source code
COPY packages/kotaemon /app/kotaemon
COPY packages/rag-system /app/rag-system

# Download pdfjs
RUN chmod +x /app/kotaemon/scripts/download_pdfjs.sh
ENV PDFJS_PREBUILT_DIR="/app/kotaemon/libs/ktem/ktem/assets/prebuilt/pdfjs-dist"
RUN bash /app/kotaemon/scripts/download_pdfjs.sh $PDFJS_PREBUILT_DIR

# Install project dependencies using uv
RUN uv pip install -e "/app/kotaemon/libs/kotaemon" \
    && uv pip install -e "/app/kotaemon/libs/ktem" \
    && uv pip install -e "/app/kotaemon/libs/pipelineblocks" \
    && uv pip install "pdfservices-sdk@git+https://github.com/niallcm/pdfservices-python-sdk.git@bump-and-unfreeze-requirements"

# Copy launcher and environment files
COPY packages/kotaemon/launch.sh /app/launch.sh
COPY packages/kotaemon/settings.yaml.example /app/settings.yaml
RUN chmod +x /app/launch.sh

# Cleanup
RUN apt-get autoremove -y && apt-get clean && rm -rf ~/.cache

ENTRYPOINT ["sh", "/app/launch.sh"]

# =======================================
# Stage 2: Full Image (with optional extras)
# =======================================
FROM lite AS full

# Additional system dependencies
RUN apt-get update -qqy && \
    apt-get install -y --no-install-recommends \
        tesseract-ocr \
        tesseract-ocr-jpn \
        libsm6 \
        libxext6 \
        libreoffice \
        ffmpeg \
        libmagic-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Torch and extras with uv
RUN uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
RUN uv pip install psycopg2-binary logfire "pydantic==2.10.6"

# Install advanced and unstructured dependencies
RUN uv pip install -e "/app/kotaemon/libs/kotaemon[adv]" \
    && uv pip install "unstructured[all-docs]" \
    && uv pip install "docling<=2.5.2"

# Final cleanup
RUN apt-get autoremove -y && apt-get clean && rm -rf ~/.cache

CMD ["sh", "/app/launch.sh"]
