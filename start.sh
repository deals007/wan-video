#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/opt/ComfyUI}"
PORT="${PORT:-8000}"
MIN_BYTES=50000000

AUTH_HEADER=()
if [ -n "${HF_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${HF_TOKEN}")
fi

download() {
  local url="$1"
  local output="$2"
  local tmp="${output}.partial"

  mkdir -p "$(dirname "$output")"

  if [ -f "$output" ] && [ "$(stat -c%s "$output")" -ge "$MIN_BYTES" ]; then
    echo "✔ Exists: $output"
    return 0
  fi

  echo "⬇ Downloading: $url"

  curl -fL --retry 10 --retry-delay 5 \
    -H "User-Agent: Mozilla/5.0" \
    -H "Accept: application/octet-stream" \
    "${AUTH_HEADER[@]}" \
    -o "$tmp" "$url"

  if [ "$(stat -c%s "$tmp")" -lt "$MIN_BYTES" ]; then
    echo "❌ Download failed (too small)"
    rm -f "$tmp"
    exit 1
  fi

  mv "$tmp" "$output"
  echo "✔ Saved: $output"
}

# =========================
# WAN 2.2 ANIMATE MODELS
# =========================

download \
"https://huggingface.co/Kijai/WanVideo_comfy_fp8_scaled/resolve/main/Wan22Animate/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors?download=true" \
"$COMFYUI_DIR/models/diffusion_models/Wan2_2-Animate-14B_fp8_e4m3fn_scaled_KJ.safetensors"

download \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1_VAE_bf16.safetensors?download=true" \
"$COMFYUI_DIR/models/vae/Wan2_1_VAE_bf16.safetensors"

download \
"https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors?download=true" \
"$COMFYUI_DIR/models/clip_vision/clip_vision_h.safetensors"

download \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors?download=true" \
"$COMFYUI_DIR/models/text_encoders/umt5-xxl-enc-bf16.safetensors"

download \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors?download=true" \
"$COMFYUI_DIR/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"

download \
"https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors?download=true" \
"$COMFYUI_DIR/models/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors"

download \
"https://huggingface.co/Wan-AI/Wan2.2-Animate-14B/resolve/main/process_checkpoint/det/yolov10m.onnx?download=true" \
"$COMFYUI_DIR/models/detection/yolov10m.onnx"

download \
"https://huggingface.co/JunkyByte/easy_ViTPose/resolve/main/onnx/wholebody/vitpose-l-wholebody.onnx?download=true" \
"$COMFYUI_DIR/models/detection/vitpose-l-wholebody.onnx"

# =========================
# WAN 2.2 REMIX (NSFW I2V)
# =========================

download \
"https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors?download=true" \
"$COMFYUI_DIR/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_high_lighting_v2.0.safetensors"

download \
"https://huggingface.co/FX-FeiHou/wan2.2-Remix/resolve/main/NSFW/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors?download=true" \
"$COMFYUI_DIR/models/diffusion_models/Wan2.2_Remix_NSFW_i2v_14b_low_lighting_v2.0.safetensors"

download \
"https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/nsfw_wan_umt5-xxl_fp8_scaled.safetensors?download=true" \
"$COMFYUI_DIR/models/text_encoders/nsfw_wan_umt5-xxl_fp8_scaled.safetensors"

download \
"https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors?download=true" \
"$COMFYUI_DIR/models/vae/wan_2.1_vae.safetensors"

download \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22-Lightning/old/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors?download=true" \
"$COMFYUI_DIR/models/loras/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors"

download \
"https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/LoRAs/Wan22-Lightning/old/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors?download=true" \
"$COMFYUI_DIR/models/loras/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors"

# =========================
# START COMFYUI
# =========================

cd "$COMFYUI_DIR"

exec python3 main.py \
  --listen 0.0.0.0 \
  --port "$PORT" \
  --disable-auto-launch \
  --force-fp16
