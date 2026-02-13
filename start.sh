#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/opt/ComfyUI}"
PORT="${PORT:-8000}"
MIN_BYTES=50000000

FILE_NAMES=(
  "Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"
  "clip_vision_h.safetensors"
  "lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
  "wan_2.1_vae.safetensors"
  "umt5_xxl_fp8_e4m3fn_scaled.safetensors"
)

FILE_URLS=(
  "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors?download=true"
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true"
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors?download=true"
  "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true"
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors?download=true"
)

FILE_DIRS=(
  "models/diffusion_models"
  "models/clip_visions"
  "models/loras"
  "models/vae"
  "models/text_encoders"
)

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
    echo "✔ Already exists: ${out}"
    return 0
  fi

  curl -fL --retry 10 --retry-delay 5 -H "User-Agent: Mozilla/5.0" \
       -H "Accept: application/octet-stream" \
       "${AUTH_HEADER[@]}" -o "${tmp}" "${url}"

  if [ "$(stat -c%s "${tmp}")" -lt "${MIN_BYTES}" ]; then
    echo "ERROR: Corrupt download"
    exit 1
  fi

  mv "${tmp}" "${out}"
}

for i in "${!FILE_NAMES[@]}"; do
  download_file "${FILE_URLS[$i]}" "${COMFYUI_DIR}/${FILE_DIRS[$i]}/${FILE_NAMES[$i]}"
done

cd "${COMFYUI_DIR}"

exec python3 main.py \
  --listen 0.0.0.0 \
  --port "${PORT}" \
  --disable-auto-launch