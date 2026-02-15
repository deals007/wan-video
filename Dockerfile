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
    git curl ca-certificates \
    python3 python3-pip python3-venv \
    build-essential \
    ffmpeg \
    libgl1 libglib2.0-0 \
    libsm6 libxext6 libxrender1 \
 && rm -rf /var/lib/apt/lists/*

# -------------------------
# Clone ComfyUI
# -------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}

WORKDIR ${COMFYUI_DIR}

# -------------------------
# Install PyTorch (CUDA 12.1)
# -------------------------
RUN python3 -m pip install --upgrade pip wheel setuptools \
 && python3 -m pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch torchvision torchaudio \
 && python3 -m pip install -r requirements.txt

# Optional performance boost
RUN python3 -m pip install xformers --index-url https://download.pytorch.org/whl/cu121 || true

# -------------------------
# ComfyUI Manager
# -------------------------
RUN mkdir -p custom_nodes \
 && git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager \
 && python3 -m pip install -r custom_nodes/ComfyUI-Manager/requirements.txt || true

# -------------------------
# ControlNet Auxiliary (VitPose + ONNX Detection)
# -------------------------
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git \
      custom_nodes/comfyui_controlnet_aux

# Critical: install dependencies manually to avoid silent failures
RUN python3 -m pip install \
      onnxruntime-gpu \
      opencv-python-headless \
      mediapipe \
      insightface \
      numpy \
      scipy \
      scikit-image \
      pillow

# -------------------------
# Video Helper Suite (I2V Required)
# -------------------------
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
      custom_nodes/ComfyUI-VideoHelperSuite \
 && python3 -m pip install -r custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt || true

# -------------------------
# Copy Startup Script
# -------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

# -------------------------
# Expose Port
# -------------------------
EXPOSE 8000

# -------------------------
# Start ComfyUI
# -------------------------
CMD ["/start.sh"]
