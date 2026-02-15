#!/usr/bin/env bash
set -e

COMFYUI_DIR="${COMFYUI_DIR:-/opt/ComfyUI}"
PORT="${PORT:-8000}"
MIN_BYTES=50000000

cd "${COMFYUI_DIR}"

echo "🚀 Starting ComfyUI on port ${PORT}..."

# Start ComfyUI immediately so Koyeb health check passes
python3 main.py \
  --listen 0.0.0.0 \
  --port "${PORT}" \
  --disable-auto-launch \
  --force-fp16 &

COMFY_PID=$!

# ---------------------------------------------------
# Model List
# ---------------------------------------------------

FILES=(

# ---------------------------
# WAN 2.2 Animate
# ---------------------------
"models/diffusion_models/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors|https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors?download=true"

"models/vae/Wan2_1_VAE_bf16.safetensors|https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors?download=true"

"models/clip_vision/clip_vision_h.safetensors|https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true"

"models/text_encoders/umt5-xxl-enc-bf16.safetensors|https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors?download=true"

"models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors|https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors?download=true"

"models/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors|https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors?download=true"

"models/detection/yolov10m.onnx|https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx?download=true"

"models/detection/vitpose-l-wholebody.onnx|https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx?download=true"

# ---------------------------
# WAN 2.2 Remix NSFW
# ---------------------------
"models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors|https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors?download=true"

"models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors|https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors?download=true"

"models/text_encoders/nsfw_wan_umt5-xxl_fp8_scaled.safetensors|https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors?download=true"

"models/vae/wan_2.1_vae.safetensors|https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true"

"models/loras/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors|https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22-Lightning/old/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors?download=true"

"models/loras/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors|https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22-Lightning/old/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors?download=true"

)

# ---------------------------------------------------
# HuggingFace Auth
# ---------------------------------------------------

AUTH_HEADER=()
if [ -n "${HF_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${HF_TOKEN}")
fi

download_file() {
  local target="$1"
  local url="$2"
  local out="${COMFYUI_DIR}/${target}"
  local tmp="${out}.partial"

  mkdir -p "$(dirname "${out}")"

  if [ -f "${out}" ] && [ "$(stat -c%s "${out}")" -ge "${MIN_BYTES}" ]; then
    echo "✔ Already exists: ${target}"
    return
  fi

  echo "⬇ Downloading: ${target}"

  curl -fL --retry 10 --retry-delay 5 \
       -H "User-Agent: Mozilla/5.0" \
       -H "Accept: application/octet-stream" \
       "${AUTH_HEADER[@]}" \
       -o "${tmp}" "$url"

  if [ "$(stat -c%s "${tmp}")" -lt "${MIN_BYTES}" ]; then
    echo "❌ Download failed: ${target}"
    rm -f "${tmp}"
    exit 1
  fi

  mv "${tmp}" "${out}"
  echo "✔ Saved: ${target}"
}

# ---------------------------------------------------
# Background Downloads
# ---------------------------------------------------

(
for entry in "${FILES[@]}"; do
  IFS="|" read -r path url <<< "$entry"
  download_file "$path" "$url"
done

echo "✅ All models downloaded."
) &

wait $COMFY_PID
