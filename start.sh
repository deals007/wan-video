#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/opt/ComfyUI}"
PORT="${PORT:-8000}"

# 100MB minimum because 14B models are huge
MIN_BYTES="${MIN_BYTES:-100000000}"

# ============================
# Wan 2.2 Remix I2V 14B Models
# ============================

FILE_NAMES=(
  "Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"
  "Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"
  "nsfw_wan_umt5-xxl_fp8_scaled.safetensors"
  "wan_2.1_vae.safetensors"
  "Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors"
  "Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors"
)

FILE_URLS=(
  "https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors?download=true"
  "https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors?download=true"
  "https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors?download=true"
  "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true"
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22-Lightning/old/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors?download=true"
  "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22-Lightning/old/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors?download=true"
)

FILE_DIRS=(
  "models/diffusion_models"
  "models/diffusion_models"
  "models/text_encoders"
  "models/vae"
  "models/loras"
  "models/loras"
)

# ============================
# Validate arrays
# ============================

if [ "${#FILE_NAMES[@]}" -ne "${#FILE_URLS[@]}" ] || \
   [ "${#FILE_NAMES[@]}" -ne "${#FILE_DIRS[@]}" ]; then
  echo "ERROR: model array length mismatch"
  exit 2
fi

mkdir -p "${COMFYUI_DIR}"

# ============================
# HF Auth (optional)
# ============================

AUTH_HEADER=()
if [ -n "${HF_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${HF_TOKEN}")
  echo "HF_TOKEN detected — authenticated downloads enabled"
fi

# ============================
# Download helper
# ============================

download_file() {
  local url="$1"
  local out_path="$2"
  local tmp="${out_path}.partial"

  mkdir -p "$(dirname "${out_path}")"

  if [ -f "${out_path}" ]; then
    local existing_bytes
    existing_bytes=$(stat -c%s "${out_path}" 2>/dev/null || echo 0)
    if [ "${existing_bytes}" -ge "${MIN_BYTES}" ]; then
      echo "✔ ${out_path} already exists (${existing_bytes} bytes)"
      return 0
    else
      rm -f "${out_path}"
    fi
  fi

  echo "⬇ Downloading ${url}"

  curl -fL \
    --retry 10 \
    --retry-delay 5 \
    --connect-timeout 60 \
    -H "User-Agent: Mozilla/5.0" \
    -H "Accept: application/octet-stream" \
    "${AUTH_HEADER[@]}" \
    -o "${tmp}" \
    "${url}"

  local bytes
  bytes=$(stat -c%s "${tmp}" 2>/dev/null || echo 0)

  if [ "${bytes}" -lt "${MIN_BYTES}" ]; then
    echo "ERROR: download too small (${bytes} bytes)"
    rm -f "${tmp}"
    return 1
  fi

  mv "${tmp}" "${out_path}"
  echo "✔ Saved ${out_path} (${bytes} bytes)"
}

# ============================
# Download all models
# ============================

for i in "${!FILE_NAMES[@]}"; do
  fname="${FILE_NAMES[$i]}"
  furl="${FILE_URLS[$i]}"
  fdir="${FILE_DIRS[$i]}"

  if ! download_file "${furl}" "${COMFYUI_DIR}/${fdir}/${fname}"; then
    echo "ERROR: failed to download ${fname}"
    exit 3
  fi
done

# ============================
# Start ComfyUI
# ============================

cd "${COMFYUI_DIR}"

exec python3 main.py \
  --listen 0.0.0.0 \
  --port "${PORT}" \
  --disable-auto-launch
