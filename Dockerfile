FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/ComfyUI \
    PATH="/opt/venv/bin:$PATH"

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates \
    python3 python3-pip python3-venv \
    build-essential \
    ffmpeg libgl1 libglib2.0-0 \
 && rm -rf /var/lib/apt/lists/*

# Create virtualenv
RUN python3 -m venv /opt/venv

# Install PyTorch CUDA 12.1
RUN pip install --upgrade pip setuptools wheel \
 && pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch==2.2.0 torchvision torchaudio

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}

WORKDIR ${COMFYUI_DIR}

# Install ComfyUI requirements
RUN pip install -r requirements.txt

# Install ONNX Runtime GPU
RUN pip install onnxruntime-gpu

# Install required custom nodes
RUN cd custom_nodes \
 && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
 && git clone https://github.com/DazzleML/DazzleNodes.git \
 && git clone https://github.com/woct0rdho/SageAttention.git \
 && git clone https://github.com/woct0rdho/SpargeAttn.git

# Install Triton (required for SageAttention)
RUN pip install triton==2.2.0

# Copy scripts
COPY install_sage_triton.sh /install_sage_triton.sh
RUN chmod +x /install_sage_triton.sh

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000

CMD ["/start.sh"]
