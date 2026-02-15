FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/ComfyUI

# ---- System dependencies ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    python3 python3-pip python3-venv \
    libgl1 libglib2.0-0 ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# ---- Clone ComfyUI ----
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}
WORKDIR ${COMFYUI_DIR}

# ---- Install PyTorch 2.3.1 CUDA 12.1 (REQUIRED for comfy_kitchen) ----
RUN python3 -m pip install --upgrade pip wheel setuptools \
 && python3 -m pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 \
 && python3 -m pip install -r requirements.txt

# ---- Install ComfyUI Manager only ----
RUN mkdir -p custom_nodes \
 && git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager

# ---- Create model directories ----
RUN mkdir -p \
    models/diffusion_models \
    models/vae \
    models/clip_vision \
    models/text_encoders \
    models/loras \
    models/detection

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000
CMD ["/start.sh"]
