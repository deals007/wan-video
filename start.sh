#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/opt/ComfyUI}"
PORT="${PORT:-8000}"
MIN_BYTES=50000000

echo "Starting Wan2.2 Animate Server..."

AUTH_HEADER=()
if [ -n "${HF_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${HF_TOKEN}")
fi

download_file() {
  local url="$1"
  local out="$2"
  local tmp="${out}.partial"

  mkdir -p "$(dirname "${out}")"

  if [ -f "${out}" ] && [ "$(stat -c%s "${out}")" -ge "${MIN_BYTES}" ]; then
    echo "✔ Exists: ${out}"
    return 0
  fi

  echo "⬇ Downloading: $url"
  curl -fL --retry 20 --retry-delay 5 \
       "${AUTH_HEADER[@]}" \
       -o "${tmp}" "$url"

  mv "${tmp}" "${out}"
  echo "✔ Saved: ${out}"
}

# ---------------------------
# MODEL DOWNLOADS
# ---------------------------

download_file \
"https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors" \
"${COMFYUI_DIR}/models/diffusion_models/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"

download_file \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors" \
"${COMFYUI_DIR}/models/vae/Wan2_1_VAE_bf16.safetensors"

download_file \
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" \
"${COMFYUI_DIR}/models/clip_vision/clip_vision_h.safetensors"

download_file \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors" \
"${COMFYUI_DIR}/models/text_encoders/umt5-xxl-enc-bf16.safetensors"

download_file \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
"${COMFYUI_DIR}/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"

download_file \
"https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors" \
"${COMFYUI_DIR}/models/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors"

download_file \
"https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx" \
"${COMFYUI_DIR}/models/detection/yolov10m.onnx"

download_file \
"https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx" \
"${COMFYUI_DIR}/models/detection/vitpose-l-wholebody.onnx"

# ---------------------------
# INSTALL SAGE ATTENTION
# ---------------------------

/install_sage_triton.sh

cd "${COMFYUI_DIR}"

exec python main.py \
  --listen 0.0.0.0 \
  --port "${PORT}" \
  --disable-auto-launch
