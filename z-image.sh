#!/bin/bash
set -e

# ─────────────────────────────────────────────
# ENVIRONMENT SETUP
# ─────────────────────────────────────────────
source /venv/main/bin/activate
WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== Vast.ai ComfyUI Provisioning (UltraFlux + Custom Nodes) ==="

# ─────────────────────────────────────────────
# 1. CLONE COMFYUI
# ─────────────────────────────────────────────
if [[ ! -d "${COMFYUI_DIR}" ]]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
fi

cd "${COMFYUI_DIR}"

# ─────────────────────────────────────────────
# 2. INSTALL BASE REQUIREMENTS
# ─────────────────────────────────────────────
pip install --no-cache-dir -r requirements.txt

# ─────────────────────────────────────────────
# 3. CUSTOM NODES SETUP
# ─────────────────────────────────────────────
mkdir -p custom_nodes

# Функция для установки ноды и её зависимостей
install_node() {
    local repo_url="$1"
    local dir_name="$2"
    local target="custom_nodes/$dir_name"

    if [[ ! -d "$target" ]]; then
        echo "→ Cloning $dir_name..."
        git clone "$repo_url" "$target"
    else
        echo "→ Updating $dir_name..."
        (cd "$target" && git pull)
    fi

    if [[ -f "$target/requirements.txt" ]]; then
        echo "→ Installing requirements for $dir_name..."
        pip install --no-cache-dir -r "$target/requirements.txt" || echo "Warning: Failed to install reqs for $dir_name"
    fi
}

# --- Manager ---
install_node "https://github.com/ltdrdata/ComfyUI-Manager.git" "ComfyUI-Manager"

# --- Requested Custom Nodes ---
# Essentials (cubiq)
install_node "https://github.com/cubiq/ComfyUI_Essentials.git" "ComfyUI_Essentials"

# RES4LYF (Recursion47)
install_node "https://github.com/Recursion47/ComfyUI-RES4LYF.git" "ComfyUI-RES4LYF"

# KJNodes (kijai)
install_node "https://github.com/kijai/ComfyUI-KJNodes.git" "ComfyUI-KJNodes"

# ─────────────────────────────────────────────
# 4. DOWNLOAD HELPER
# ─────────────────────────────────────────────
download() {
    local dir="$1"
    local url="$2"
    
    mkdir -p "$dir"
    echo "→ Downloading to $dir: $url"
    wget -nc --content-disposition "$url" -P "$dir"
}

# ─────────────────────────────────────────────
# 5. MODEL DOWNLOADS
# ─────────────────────────────────────────────

# VAE
download "models/vae" \
    "https://huggingface.co/Owen777/UltraFlux-v1/resolve/main/vae/diffusion_pytorch_model.safetensors"

# CLIP (URL исправлен)
download "models/clip" \
    "https://huggingface.co/arhiteector/qwen_3_4b.safetensors/resolve/main/qwen_3_4b.safetensors"

# TEXT ENCODERS (T5 XXL)
download "models/text_encoders" \
    "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/refs%2Fpr%2F5/models/clip/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors"

# DIFFUSION MODELS (Z Image Turbo)
download "models/diffusion_models" \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"

# ─────────────────────────────────────────────
# 6. LAUNCH
# ─────────────────────────────────────────────
echo "=== All downloads & installs finished. Starting ComfyUI... ==="
python main.py --listen 0.0.0.0 --port 8188
