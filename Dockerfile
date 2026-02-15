FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

# -----------------------------
# Environment
# -----------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/ComfyUI \
    PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    CUDA_VISIBLE_DEVICES=0 \
    TORCH_CUDNN_V8_API_ENABLED=1

# -----------------------------
# System Dependencies
# -----------------------------
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
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Clone ComfyUI
# -----------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}

WORKDIR ${COMFYUI_DIR}

# -----------------------------
# Install PyTorch CUDA 12.1
# -----------------------------
RUN python3 -m pip install --upgrade pip wheel setuptools \
 && python3 -m pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch torchvision torchaudio \
 && python3 -m pip install -r requirements.txt

# Optional speed improvement (safe to ignore failure)
RUN python3 -m pip install xformers --index-url https://download.pytorch.org/whl/cu121 || true

# -----------------------------
# Install ComfyUI-Manager (PROPERLY)
# -----------------------------
RUN mkdir -p ${COMFYUI_DIR}/custom_nodes \
 && git clone https://github.com/ltdrdata/ComfyUI-Manager.git \
      ${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager \
 && if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager/requirements.txt" ]; then \
      python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager/requirements.txt ; \
    fi

# -----------------------------
# Recommended WAN Custom Nodes
# -----------------------------
RUN git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git \
      ${COMFYUI_DIR}/custom_nodes/comfyui_controlnet_aux \
 && if [ -f "${COMFYUI_DIR}/custom_nodes/comfyui_controlnet_aux/requirements.txt" ]; then \
      python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/comfyui_controlnet_aux/requirements.txt ; \
    fi

# Video helper nodes (important for I2V)
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
      ${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite \
 && if [ -f "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" ]; then \
      python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt ; \
    fi

# -----------------------------
# Copy start script
# -----------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

# -----------------------------
# Expose Port
# -----------------------------
EXPOSE 8000

# -----------------------------
# Launch
# -----------------------------
CMD ["/start.sh"]
