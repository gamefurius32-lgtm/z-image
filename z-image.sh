#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
export GIT_TERMINAL_PROMPT=0

# ─────────────────────────────────────────────
# 0. SYSTEM FIX (CRITICAL)
# ─────────────────────────────────────────────
echo "=== SYSTEM FIX: git + certs ==="
apt-get update
apt-get install -y git ca-certificates

git config --global http.sslVerify true

# ─────────────────────────────────────────────
# ENV
# ─────────────────────────────────────────────
source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== Vast.ai ComfyUI provisioning (HARD FIX) ==="

# ─────────────────────────────────────────────
# 1. Clone ComfyUI
# ─────────────────────────────────────────────
if [[ ! -d "$COMFYUI_DIR" ]]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
fi

cd "$COMFYUI_DIR"

# ─────────────────────────────────────────────
# 2. Requirements
# ─────────────────────────────────────────────
pip install --no-cache-dir -r requirements.txt

# ─────────────────────────────────────────────
# 3. Custom nodes (GUARANTEED)
# ─────────────────────────────────────────────
mkdir -p custom_nodes

clone() {
    local repo="$1"
    local dir="$2"
    echo "→ installing $dir"
    if [[ ! -d "$dir" ]]; then
        git clone --depth=1 "$repo" "$dir"
    fi
}

clone https://github.com/ltdrdata/ComfyUI-Manager custom_nodes/ComfyUI-Manager
clone https://github.com/MattEODev/ComfyUI_essentials custom_nodes/ComfyUI_essentials
clone https://github.com/ClownsharkBatwing/RES4LYF custom_nodes/RES4LYF
clone https://github.com/Kijai/ComfyUI-KJNodes custom_nodes/ComfyUI-KJNodes

# deps that these nodes реально требуют
pip install --no-cache-dir \
    einops accelerate transformers kornia safetensors || true

# ─────────────────────────────────────────────
# 4. Model folders
# ─────────────────────────────────────────────
mkdir -p models/diffusion_models models/clip models/vae models/text_encoders

# ─────────────────────────────────────────────
# 5. MODELS — ЖЁСТКО
# ─────────────────────────────────────────────

wget -nc \
https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors \
-O models/diffusion_models/z_image_turbo_bf16.safetensors

wget -nc \
https://huggingface.co/arhiteector/qwen_3_4b.safetnsors/resolve/main/qwen_3_4b.safetensors \
-O models/clip/qwen_3_4b.safetensors

wget -nc \
https://huggingface.co/Owen777/UltraFlux-v1/resolve/main/vae/diffusion_pytorch_model.safetensors \
-O models/vae/UltraFlux-v1_model.safetensors

wget -nc \
https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/refs%2Fpr%2F5/models/clip/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors \
-O models/text_encoders/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors

# ─────────────────────────────────────────────
# 6. Launch
# ─────────────────────────────────────────────
echo "=== Starting ComfyUI ==="
python main.py --listen 0.0.0.0 --port 8188
