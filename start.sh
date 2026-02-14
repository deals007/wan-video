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
  "WanAnimate_relight_lora_fp16.safetensors"
)

FILE_URLS=(
  "https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors?download=true"
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true"
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors?download=true"
  "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true"
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors?download=true"
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/WanAnimate_relight_lora_fp16.safetensors?download=true"
)

FILE_DIRS=(
  "models/diffusion_models"
  "models/clip_vision"
  "models/loras"
  "models/vae"
  "models/text_encoders"
  "models/loras"
)

AUTH_HEADER=()
if [ -n "${HF_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${HF_TOKEN}")
  echo "HF_TOKEN detected — authenticated Hugging Face downloads enabled"
fi

download_file() {
  local url="$1"
  local out="$2"
  local tmp="${out}.partial"

  mkdir -p "$(dirname "${out}")"

  if [ -f "${out}" ]; then
    local size
    size=$(stat -c%s "${out}" 2>/dev/null || echo 0)
    if [ "${size}" -ge "${MIN_BYTES}" ]; then
      echo "✔ Already exists: ${out} (${size} bytes)"
      return 0
    else
      echo "⚠ Existing file too small, re-downloading: ${out}"
      rm -f "${out}"
    fi
  fi

  echo "⬇ Downloading:"
  echo "   ${url}"

  curl -fL \
    --retry 10 \
    --retry-delay 5 \
    --connect-timeout 30 \
    -H "User-Agent: Mozilla/5.0" \
    -H "Accept: application/octet-stream" \
    "${AUTH_HEADER[@]}" \
    -o "${tmp}" \
    "${url}"

  local bytes
  bytes=$(stat -c%s "${tmp}" 2>/dev/null || echo 0)

  if [ "${bytes}" -lt "${MIN_BYTES}" ]; then
    echo "❌ ERROR: Download too small (${bytes} bytes)."
    echo "Likely 403/429 or HTML error page from Hugging Face."
    head -c 300 "${tmp}" || true
    rm -f "${tmp}"
    exit 1
  fi

  mv "${tmp}" "${out}"
  echo "✔ Saved ${out} (${bytes} bytes)"
}

for i in "${!FILE_NAMES[@]}"; do
  echo "----------------------------------------"
  echo "Preparing ${FILE_NAMES[$i]}"
  download_file "${FILE_URLS[$i]}" "${COMFYUI_DIR}/${FILE_DIRS[$i]}/${FILE_NAMES[$i]}"
done

cd "${COMFYUI_DIR}"

exec python3 main.py \
  --listen 0.0.0.0 \
  --port "${PORT}" \
  --disable-auto-launch