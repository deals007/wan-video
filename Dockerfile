FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/ComfyUI \
    HF_HOME=/root/.cache/huggingface \
    TORCH_CUDA_ARCH_LIST="8.6" \
    FORCE_CUDA=1

# =========================
# System Dependencies
# =========================
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    python3 python3-pip python3-venv \
    build-essential \
    libgl1 libglib2.0-0 ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# =========================
# Clone ComfyUI
# =========================
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}

WORKDIR ${COMFYUI_DIR}

# =========================
# Install PyTorch (CUDA 12.1)
# =========================
RUN python3 -m pip install --upgrade pip wheel setuptools \
 && python3 -m pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch torchvision torchaudio \
 && python3 -m pip install -r requirements.txt

# =========================
# Install Performance Extensions
# =========================
RUN python3 -m pip install \
    sageattention \
    xformers \
    triton

# If sageattention fails to install, uncomment this instead:
# RUN python3 -m pip install git+https://github.com/thu-ml/SageAttention.git

# =========================
# Custom Nodes
# =========================
RUN mkdir -p ${COMFYUI_DIR}/custom_nodes && cd custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git || true && \
    git clone https://github.com/Kijai/ComfyUI-WanVideo.git || true && \
    git clone https://github.com/kijai/ComfyUI-WanAnimatePreprocess.git || true && \
    git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git || true && \
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git || true && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git || true && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git || true && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git || true

# Install custom node requirements if present
RUN find custom_nodes -name "requirements.txt" -exec pip install -r {} \; || true

# =========================
# Create Model Directories
# =========================
RUN mkdir -p \
    models/diffusion_models \
    models/vae \
    models/clip_vision \
    models/text_encoders \
    models/loras \
    models/detection

# =========================
# Copy Start Script
# =========================
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000

CMD ["/start.sh"]
