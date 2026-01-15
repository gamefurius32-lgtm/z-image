#!/bin/bash
set -e

# ─────────────────────────────────────────────
# ENVIRONMENT SETUP
# ─────────────────────────────────────────────
source /venv/main/bin/activate
WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== Vast.ai ComfyUI Provisioning (UltraFlux/Qwen/Z-Image) ==="

# ─────────────────────────────────────────────
# 1. CLONE COMFIYUI
# ─────────────────────────────────────────────
if [[ ! -d "${COMFYUI_DIR}" ]]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
fi

cd "${COMFYUI_DIR}"

# ─────────────────────────────────────────────
# 2. INSTALL REQUIREMENTS
# ─────────────────────────────────────────────
pip install --no-cache-dir -r requirements.txt

# ─────────────────────────────────────────────
# 3. CUSTOM NODES (Manager)
# ─────────────────────────────────────────────
mkdir -p custom_nodes

if [[ ! -d "custom_nodes/ComfyUI-Manager" ]]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager custom_nodes/ComfyUI-Manager
else
    (cd custom_nodes/ComfyUI-Manager && git pull)
fi

pip install --no-cache-dir -r custom_nodes/ComfyUI-Manager/requirements.txt || true

# ─────────────────────────────────────────────
# 4. DOWNLOAD HELPER
# ─────────────────────────────────────────────
download() {
    local dir="$1"
    local url="$2"
    
    mkdir -p "$dir"
    echo "→ Downloading to $dir: $url"
    # -nc: skip if exists
    # --content-disposition: respect server filename
    wget -nc --content-disposition "$url" -P "$dir"
}

# ─────────────────────────────────────────────
# 5. MODEL DOWNLOADS
# ─────────────────────────────────────────────

# VAE
# Скачиваем в models/vae
download "models/vae" \
    "https://huggingface.co/Owen777/UltraFlux-v1/resolve/main/vae/diffusion_pytorch_model.safetensors"

# CLIP
# Скачиваем в models/clip (исправлена опечатка в URL репозитория: safetnsors -> safetensors)
download "models/clip" \
    "https://huggingface.co/arhiteector/qwen_3_4b.safetensors/resolve/main/qwen_3_4b.safetensors"

# TEXT ENCODERS
# Скачиваем в models/text_encoders (T5 XXL)
download "models/text_encoders" \
    "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/refs%2Fpr%2F5/models/clip/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors"

# DIFFUSION MODELS
# Скачиваем в models/diffusion_models (Z Image Turbo)
download "models/diffusion_models" \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"


# ─────────────────────────────────────────────
# 6. LAUNCH
# ─────────────────────────────────────────────
echo "=== All downloads finished. Starting ComfyUI... ==="
python main.py --listen 0.0.0.0 --port 8188
