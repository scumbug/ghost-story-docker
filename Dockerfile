FROM node:24-slim

# Build-time configuration
ARG VARIANT=windows-x64-cuda-13.1.0
ARG MODEL=tiny

# Runtime defaults (can be overridden via environment variables)
ENV GS_MODEL=${MODEL}
ENV GS_PORT=8080
ENV GS_HOST=0.0.0.0
ENV GS_THREADS=4
ENV GS_PROCESSORS=1

# Install system dependencies required by whisper.cpp binaries
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install ghost-story globally
RUN npm install -g @storyteller-platform/ghost-story

# Pre-install the whisper.cpp binary and model at build time
# This avoids slow downloads on every container start
RUN ghost-story install binary ${VARIANT} --force
RUN ghost-story install model ${MODEL}

EXPOSE ${GS_PORT}

# Start the whisper server using environment variables
CMD ghost-story server \
    --model ${GS_MODEL} \
    --port ${GS_PORT} \
    --host ${GS_HOST} \
    --threads ${GS_THREADS} \
    --processors ${GS_PROCESSORS} \
    --no-auto-install
