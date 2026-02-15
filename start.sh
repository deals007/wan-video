#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/opt/ComfyUI}"
PORT="${PORT:-8000}"
MIN_BYTES=50000000

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

  echo "⬇ Downloading: ${out}"
  curl -fL --retry 10 --retry-delay 5 \
       -H "User-Agent: Mozilla/5.0" \
       "${AUTH_HEADER[@]}" \
       -o "${tmp}" "$url"

  if [ "$(stat -c%s "${tmp}")" -lt "${MIN_BYTES}" ]; then
    echo "❌ Download failed (too small)"
    rm -f "${tmp}"
    exit 1
  fi

  mv "${tmp}" "${out}"
  echo "✔ Saved: ${out}"
}

# =========================
# WAN 2.2 ANIMATE
# =========================

download_file \
"https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors?download=true" \
"${COMFYUI_DIR}/models/diffusion_models/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"

download_file \
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true" \
"${COMFYUI_DIR}/models/clip_vision/clip_vision_h.safetensors"

download_file \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors?download=true" \
"${COMFYUI_DIR}/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"

download_file \
"https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true" \
"${COMFYUI_DIR}/models/vae/wan_2.1_vae.safetensors"

download_file \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors?download=true" \
"${COMFYUI_DIR}/models/text_encoders/umt5-xxl-enc-bf16.safetensors"

download_file \
"https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/relighting_lora/adapter_model.safetensors?download=true" \
"${COMFYUI_DIR}/models/loras/WanAnimate_relight_lora_fp16.safetensors"

# =========================
# NEW REMIX MODELS (ADDED)
# =========================

download_file \
"https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors?download=true" \
"${COMFYUI_DIR}/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"

download_file \
"https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors?download=true" \
"${COMFYUI_DIR}/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"

cd "${COMFYUI_DIR}"

exec python3 main.py \
  --listen 0.0.0.0 \
  --port "${PORT}" \
  --disable-auto-launch \
  --force-fp16
