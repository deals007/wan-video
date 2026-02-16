FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

SHELL ["/bin/bash", "-lc"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/ComfyUI

# ---------------------------------------------------------
# System dependencies
# ---------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    python3 python3-pip python3-venv \
    libgl1 libglib2.0-0 ffmpeg \
 && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Install ComfyUI
# ---------------------------------------------------------
RUN git clone https://github.com/comfyanonymous/ComfyUI.git ${COMFYUI_DIR}
WORKDIR ${COMFYUI_DIR}

RUN python3 -m pip install --upgrade pip wheel setuptools \
 && python3 -m pip install --index-url https://download.pytorch.org/whl/cu121 \
      torch torchvision torchaudio \
 && python3 -m pip install -r requirements.txt

# ---------------------------------------------------------
# Install ComfyUI Manager
# ---------------------------------------------------------
RUN mkdir -p ${COMFYUI_DIR}/custom_nodes \
 && git clone https://github.com/ltdrdata/ComfyUI-Manager.git \
      ${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager || true

# ---------------------------------------------------------
# Install required custom nodes for WanVideo workflow
# ---------------------------------------------------------

# WanVideo nodes
RUN git clone https://github.com/Kijai/WanVideo_ComfyUI.git \
    ${COMFYUI_DIR}/custom_nodes/WanVideo_ComfyUI || true

# KJ nodes (ImageResizeKJv2, BlockifyMask, GrowMaskWithBlur, etc.)
RUN git clone https://github.com/Kijai/ComfyUI-KJNodes.git \
    ${COMFYUI_DIR}/custom_nodes/ComfyUI-KJNodes || true

# SAM2 segmentation
RUN git clone https://github.com/ltdrdata/ComfyUI-SAM2.git \
    ${COMFYUI_DIR}/custom_nodes/ComfyUI-SAM2 || true

# ViTPose + detection models
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git \
    ${COMFYUI_DIR}/custom_nodes/ComfyUI_essentials || true

# VHS video nodes (VHS_LoadVideo, VHS_VideoInfo, VHS_VideoCombine)
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
    ${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite || true

# Onnx detection loader
RUN git clone https://github.com/spacepxl/ComfyUI-ONNXNodes.git \
    ${COMFYUI_DIR}/custom_nodes/ComfyUI-ONNXNodes || true

# ---------------------------------------------------------
# Copy start script
# ---------------------------------------------------------
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 8000
CMD ["/start.sh"]
