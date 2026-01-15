#!/bin/bash
set -e

# ─────────────────────────────────────────────
# ENV
# ─────────────────────────────────────────────
source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== Vast.ai ComfyUI provisioning (FULL STACK) ==="

# ─────────────────────────────────────────────
# 1. Clone ComfyUI
# ─────────────────────────────────────────────
if [[ ! -d "${COMFYUI_DIR}" ]]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
fi

cd "${COMFYUI_DIR}"

# ─────────────────────────────────────────────
# 2. Install requirements
# ─────────────────────────────────────────────
pip install --no-cache-dir -r requirements.txt

# ─────────────────────────────────────────────
# 3. Custom nodes
# ─────────────────────────────────────────────
mkdir -p custom_nodes

# --- ComfyUI-Manager ---
if [[ ! -d "custom_nodes/ComfyUI-Manager" ]]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager custom_nodes/ComfyUI-Manager
else
    (cd custom_nodes/ComfyUI-Manager && git pull)
fi
pip install --no-cache-dir -r custom_nodes/ComfyUI-Manager/requirements.txt || true

# --- ComfyUI_essentials ---
if [[ ! -d "custom_nodes/ComfyUI_essentials" ]]; then
    git clone https://github.com/MattEODev/ComfyUI_essentials custom_nodes/ComfyUI_essentials
else
    (cd custom_nodes/ComfyUI_essentials && git pull)
fi
pip install --no-cache-dir -r custom_nodes/ComfyUI_essentials/requirements.txt || true

# --- RES4LYF ---
if [[ ! -d "custom_nodes/RES4LYF" ]]; then
    git clone https://github.com/ClownsharkBatwing/RES4LYF custom_nodes/RES4LYF
else
    (cd custom_nodes/RES4LYF && git pull)
fi
pip install --no-cache-dir -r custom_nodes/RES4LYF/requirements.txt || true

# --- ComfyUI-KJNodes (Kijai) ---
if [[ ! -d "custom_nodes/ComfyUI-KJNodes" ]]; then
    git clone https://github.com/Kijai/ComfyUI-KJNodes custom_nodes/ComfyUI-KJNodes
else
    (cd custom_nodes/ComfyUI-KJNodes && git pull)
fi
pip install --no-cache-dir -r custom_nodes/ComfyUI-KJNodes/requirements.txt || true

# ─────────────────────────────────────────────
# 4. Download helpers
# ─────────────────────────────────────────────
download() {
    local dir="$1"
    local url="$2"
    mkdir -p "$dir"
    echo "→ $url"
    wget -nc --content-disposition "$url" -P "$dir"
}

download_rename() {
    local dir="$1"
    local url="$2"
    local name="$3"
    mkdir -p "$dir"
    echo "→ $url → $name"
    wget -nc "$url" -O "$dir/$name"
}

# ─────────────────────────────────────────────
# 5. MODELS
# ─────────────────────────────────────────────

# Diffusion
download "models/diffusion_models" \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"

# VAE (UltraFlux — fixed)
download_rename "models/vae" \
"https://huggingface.co/Owen777/UltraFlux-v1/resolve/main/vae/diffusion_pytorch_model.safetensors" \
"ultraflux_vae.safetensors"

# Text Encoder (umt5 XXL fp8)
download "models/text_encoders" \
"https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/refs%2Fpr%2F5/models/clip/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors"

# Qwen 3 4B (CLIP)
download "models/clip" \
"https://huggingface.co/arhiteector/qwen_3_4b.safetnsors/resolve/main/qwen_3_4b.safetensors"

# ─────────────────────────────────────────────
# 6. Launch
# ─────────────────────────────────────────────
echo "=== Starting ComfyUI ==="
python main.py --listen 0.0.0.0 --port 8188
