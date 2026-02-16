FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/ComfyUI \
    PATH="/opt/venv/bin:$PATH" \
    CUDA_HOME=/usr/local/cuda

# ----------------------------------
# System packages
# ----------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates \
    python3 python3-pip python3-venv \
    build-essential \
    ffmpeg libgl1 libglib2.0-0 \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------------
# Python venv
# ----------------------------------
RUN python3 -m venv /opt/venv
RUN pip install --upgrade pip setuptools wheel

# ----------------------------------
# Install PyTorch CUDA 12.1
# ----------------------------------
RUN pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch==2.2.0 torchvision torchaudio

# ----------------------------------
# Clone ComfyUI
# ----------------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}

WORKDIR ${COMFYUI_DIR}

RUN pip install -r requirements.txt

# ----------------------------------
# ONNX Runtime GPU
# ----------------------------------
RUN pip install onnxruntime-gpu

# ----------------------------------
# Triton (must match torch 2.2)
# ----------------------------------
RUN pip install triton==2.2.0

# ----------------------------------
# Custom nodes
# ----------------------------------
RUN cd custom_nodes \
 && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
 && git clone https://github.com/woct0rdho/SageAttention.git

# ----------------------------------
# Install SageAttention (now nvcc exists)
# ----------------------------------
RUN cd custom_nodes/SageAttention && pip install .

# ----------------------------------
# Copy start script
# ----------------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000

CMD ["/start.sh"]
