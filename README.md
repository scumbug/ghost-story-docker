# ghost-story Docker

A Dockerized [ghost-story](https://storyteller-platform.gitlab.io/storyteller/docs/tutorials/offloading-transcription) whisper.cpp transcription server for offloading transcription from [Storyteller](https://storyteller-platform.gitlab.io/storyteller/).

## Prerequisites

- Docker & Docker Compose
- (For CUDA variants) NVIDIA Container Toolkit installed on the host

## Quick Start

```bash
docker compose up -d
```

This builds and starts the server with the default variant (`windows-x64-cuda-13.1.0`) and model (`tiny`) on port `8080`.

## Configuration

### Build arguments

The variant and model are baked into the image at build time. Edit `docker-compose.yml` to change the defaults:

```yaml
args:
  VARIANT: windows-x64-cuda-13.1.0  # whisper.cpp binary variant
  MODEL: tiny                         # Whisper model to use
```

Or pass them directly via CLI:

```bash
docker compose build \
  --build-arg VARIANT=linux-x64-cuda-12.9.0 \
  --build-arg MODEL=large-v3-turbo
```

> **Important:** `GS_MODEL` in the `environment` section must match the `MODEL` build arg. They need to stay in sync since the model is baked into the image.

### Available variants

| Variant | Hardware |
|---|---|
| `windows-x64-cuda-13.1.0` | Windows, NVIDIA GPU (CUDA 13.1) |
| `windows-x64-cuda-12.9.0` | Windows, NVIDIA GPU (CUDA 12.9) |
| `windows-x64-cuda-11.8.0` | Windows, NVIDIA GPU (CUDA 11.8) |
| `windows-x64-vulkan` | Windows, Vulkan GPU |
| `windows-x64-cpu` | Windows, CPU only |
| `linux-x64-cuda-13.1.0` | Linux, NVIDIA GPU (CUDA 13.1) |
| `linux-x64-cuda-12.9.0` | Linux, NVIDIA GPU (CUDA 12.9) |
| `linux-x64-cuda-11.8.0` | Linux, NVIDIA GPU (CUDA 11.8) |
| `linux-x64-vulkan` | Linux, Vulkan GPU |
| `linux-x64-rocm` | Linux, AMD GPU |
| `linux-x64-sycl` | Linux, Intel GPU |
| `linux-x64-blas` | Linux, BLAS-accelerated CPU |
| `linux-x64-cpu` | Linux, CPU only |
| `linux-arm64-cpu` | Linux ARM64 (e.g. Raspberry Pi), CPU only |
| `darwin-arm64-coreml` | macOS Apple Silicon, CoreML |
| `darwin-arm64-cpu` | macOS Apple Silicon, CPU only |
| `darwin-x64-cpu` | macOS Intel, CPU only |

### Available models

| Model | Notes |
|---|---|
| `tiny`, `tiny.en` | Fastest, lowest accuracy |
| `base`, `base.en` | |
| `small`, `small.en` | Good balance of speed and accuracy |
| `medium`, `medium.en` | |
| `large-v1`, `large-v2`, `large-v3` | Most accurate, slowest |
| `large-v3-turbo` | Recommended for most use cases |
| `large-v3-turbo-q5_0`, `large-v3-turbo-q8_0` | Quantized — smaller, faster |

Quantized models (`-q5_1`, `-q5_0`, `-q8_0`) are not available with the `coreml` variant on macOS.

### Runtime environment variables

These can be set in `docker-compose.yml` under `environment` without rebuilding the image:

| Variable | Default | Description |
|---|---|---|
| `GS_MODEL` | `tiny` | Whisper model to load (must match build-time `MODEL`) |
| `GS_PORT` | `8080` | Port the server listens on |
| `GS_HOST` | `0.0.0.0` | Host to bind to |
| `GS_THREADS` | `4` | Number of CPU threads |
| `GS_PROCESSORS` | `1` | Number of processors (higher = faster but may cause alignment issues) |

## Connecting Storyteller

In Storyteller's settings under **Transcription settings**:

- **Transcription engine:** `whisper.cpp (remote)`
- **API Key:** leave empty (not required)
- **Base URL:** depends on your setup:

| Setup | Base URL |
|---|---|
| Same Compose stack | `http://ghost-story:8080` |
| Storyteller in Docker on Linux | `http://host.docker.internal:8080` (add `--add-host=host.docker.internal:host-gateway` to Storyteller container) |
| Storyteller in Docker on macOS/Windows | `http://host.docker.internal:8080` |
| Storyteller on a different machine | `http://<host-lan-ip>:8080` |

### Running Storyteller in the same Compose stack

Uncomment the `storyteller` service block in `docker-compose.yml`:

```yaml
storyteller:
  image: storytellerplatform/storyteller:latest
  ports:
    - "8001:8001"
  environment:
    STORYTELLER_TRANSCRIPTION_ENGINE: whisper.cpp (remote)
    STORYTELLER_TRANSCRIPTION_BASE_URL: http://ghost-story:8080
  depends_on:
    - ghost-story
```

## GPU Support (CUDA)

Add the NVIDIA runtime to the `ghost-story` service in `docker-compose.yml`:

```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: 1
          capabilities: [gpu]
```

Also ensure the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) is installed on the host.

## Data Persistence

The named volume `ghost-story-data` persists the installed binary and model across container restarts and rebuilds, avoiding redundant downloads.

## References

- [Storyteller: Offloading Transcription](https://storyteller-platform.gitlab.io/storyteller/docs/tutorials/offloading-transcription)
- [ghost-story on npm](https://www.npmjs.com/package/@storyteller-platform/ghost-story)
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp)
