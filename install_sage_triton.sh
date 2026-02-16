#!/usr/bin/env bash
set -e

echo "Installing SageAttention..."

cd ${COMFYUI_DIR}/custom_nodes/SageAttention
pip install -r requirements.txt || true
pip install .

echo "Installing SpargeAttn..."

cd ${COMFYUI_DIR}/custom_nodes/SpargeAttn
pip install .

echo "SageAttention + Triton installed."
