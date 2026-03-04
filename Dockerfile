FROM ubuntu:24.04

# Build-time configuration
ARG VARIANT=linux-x64-cuda-13.1.0
ARG MODEL=tiny

# Runtime defaults (can be overridden via environment variables)
ENV GS_MODEL=${MODEL}
ENV GS_PORT=8080
ENV GS_HOST=0.0.0.0
ENV GS_THREADS=4
ENV GS_PROCESSORS=1

# Install Node.js 24, CUDA runtime libs, and system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    libgomp1 \
    libstdc++6 \
    wget \
    gnupg \
    && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb \
    && dpkg -i cuda-keyring_1.1-1_all.deb \
    && apt-get update && apt-get install -y \
    libcuda1 \
    libcudart-13-1 \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* cuda-keyring_1.1-1_all.deb

# Install ghost-story globally
RUN npm install -g @storyteller-platform/ghost-story

# Pre-install the whisper.cpp binary and model at build time
# This avoids slow downloads on every container start
RUN ghost-story install binary ${VARIANT} --force
RUN ghost-story install model ${MODEL}

EXPOSE ${GS_PORT}

# Start the whisper server using environment variables
CMD ["sh", "-c", "ghost-story server --model ${GS_MODEL} --port ${GS_PORT} --host ${GS_HOST} --threads ${GS_THREADS} --processors ${GS_PROCESSORS} --no-auto-install"]
