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

  if [ ! -f "$tmp" ] || [ "$(stat -c%s "$tmp")" -lt "$MIN_BYTES" ]; then
    echo "❌ Download failed or too small: $url"
    rm -f "$tmp"
    exit 1
  fi

  mv "$tmp" "$output"
  echo "✔ Saved: $output"
}

# =========================
# (Optional) Add your model downloads here
# =========================

cd "$COMFYUI_DIR"

echo "Starting ComfyUI on port ${PORT}..."

exec python3 main.py \
  --listen 0.0.0.0 \
  --port "$PORT" \
  --disable-auto-launch \
  --force-fp16
