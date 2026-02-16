FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/ComfyUI \
    PATH="/opt/venv/bin:$PATH" \
    CUDA_HOME=/usr/local/cuda \
    TORCH_CUDA_ARCH_LIST="8.0"

# --------------------------------------------------
# SYSTEM DEPENDENCIES (FIXED)
# --------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl wget ca-certificates \
    python3 python3-pip python3-venv python3-dev \
    build-essential ninja-build \
    ffmpeg libgl1 libglib2.0-0 \
 && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# PYTHON ENV
# --------------------------------------------------
RUN python3 -m venv /opt/venv
RUN pip install --upgrade pip setuptools wheel

# --------------------------------------------------
# TORCH CUDA 12.1
# --------------------------------------------------
RUN pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch==2.2.0 torchvision torchaudio

# --------------------------------------------------
# COMFYUI
# --------------------------------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}
WORKDIR ${COMFYUI_DIR}

RUN pip install -r requirements.txt

# --------------------------------------------------
# ONNX GPU
# --------------------------------------------------
RUN pip install onnxruntime-gpu

# --------------------------------------------------
# TRITON
# --------------------------------------------------
RUN pip install triton==2.2.0

# --------------------------------------------------
# CUSTOM NODES
# --------------------------------------------------
RUN cd custom_nodes \
 && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
 && git clone https://github.com/woct0rdho/SageAttention.git

# --------------------------------------------------
# INSTALL SAGEATTENTION (NOW WILL WORK)
# --------------------------------------------------
RUN cd custom_nodes/SageAttention && pip install .

# --------------------------------------------------
# START SCRIPT
# --------------------------------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000

CMD ["/start.sh"]
