FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

# -------------------------
# Environment
# -------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/ComfyUI \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    CUDA_VISIBLE_DEVICES=0 \
    TORCH_CUDNN_V8_API_ENABLED=1

# -------------------------
# System Dependencies
# -------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    libgl1 \
    libglib2.0-0 \
    ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# -------------------------
# Clone ComfyUI
# -------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}

WORKDIR ${COMFYUI_DIR}

# -------------------------
# Python + PyTorch (CUDA 12.1)
# -------------------------
RUN python3 -m pip install --upgrade pip wheel setuptools \
 && python3 -m pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch torchvision torchaudio \
 && python3 -m pip install -r requirements.txt

# Optional but recommended for performance
RUN python3 -m pip install xformers --index-url https://download.pytorch.org/whl/cu121 || true

# -------------------------
# Copy startup script
# -------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

# -------------------------
# Expose ComfyUI Port
# -------------------------
EXPOSE 8000

# -------------------------
# Launch
# -------------------------
CMD ["/start.sh"]
