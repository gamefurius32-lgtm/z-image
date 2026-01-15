#!/bin/bash
set -e

# ─────────────────────────────────────────────
# 0. INITIAL SETUP
# ─────────────────────────────────────────────
source /venv/main/bin/activate
WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== VAST.AI PROVISIONING: SENIOR SETUP ==="

# ─────────────────────────────────────────────
# 1. INSTALL COMFYUI
# ─────────────────────────────────────────────
if [[ ! -d "${COMFYUI_DIR}" ]]; then
    echo "Creating ComfyUI directory..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
fi

cd "${COMFYUI_DIR}"

echo "Installing requirements..."
pip install --no-cache-dir -r requirements.txt

# ─────────────────────────────────────────────
# 2. INSTALL CUSTOM NODES
# ─────────────────────────────────────────────
mkdir -p custom_nodes

install_node() {
    local url=$1
    local name=$2
    if [[ ! -d "custom_nodes/$name" ]]; then
        echo "Installing Node: $name"
        git clone "$url" "custom_nodes/$name"
        if [[ -f "custom_nodes/$name/requirements.txt" ]]; then
            pip install --no-cache-dir -r "custom_nodes/$name/requirements.txt"
        fi
    else
        echo "Updating Node: $name"
        (cd "custom_nodes/$name" && git pull)
    fi
}

# --- Nodes List ---
install_node "https://github.com/ltdrdata/ComfyUI-Manager.git"   "ComfyUI-Manager"
install_node "https://github.com/cubiq/ComfyUI_Essentials.git"  "ComfyUI_Essentials"
install_node "https://github.com/Recursion47/ComfyUI-RES4LYF.git" "ComfyUI-RES4LYF"
install_node "https://github.com/kijai/ComfyUI-KJNodes.git"     "ComfyUI-KJNodes"

# ─────────────────────────────────────────────
# 3. DOWNLOAD MODELS (HARDCODED & ROBUST)
# ─────────────────────────────────────────────

# Функция скачивания с принудительным переименованием
# Аргументы: $1 = Папка, $2 = Имя файла, $3 = Ссылка
download_model() {
    local folder="${COMFYUI_DIR}/$1"
    local file="$2"
    local url="$3"
    
    mkdir -p "$folder"
    
    if [[ -f "$folder/$file" ]]; then
        echo "SKIP: $file already exists."
    else
        echo "DOWNLOADING: $file..."
        # -O: сохраняет под конкретным именем (важно для HF)
        # -L: переходит по редиректам (важно для HF)
        # --progress=bar:force: показывает прогресс
        wget -q --show-progress -L --user-agent="Mozilla/5.0" -O "$folder/$file" "$url"
    fi
}

echo "=== DOWNLOADING MODELS ==="

# --- VAE ---
download_model "models/vae" \
    "diffusion_pytorch_model.safetensors" \
    "https://huggingface.co/Owen777/UltraFlux-v1/resolve/main/vae/diffusion_pytorch_model.safetensors"

# --- CLIP (Qwen) ---
download_model "models/clip" \
    "qwen_3_4b.safetensors" \
    "https://huggingface.co/arhiteector/qwen_3_4b.safetensors/resolve/main/qwen_3_4b.safetensors"

# --- TEXT ENCODERS (T5) ---
download_model "models/text_encoders" \
    "umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors" \
    "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/refs%2Fpr%2F5/models/clip/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors"

# --- DIFFUSION MODELS (Z-Image) ---
download_model "models/diffusion_models" \
    "z_image_turbo_bf16.safetensors" \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"

echo "=== CHECKING FILES ==="
ls -lh models/vae/
ls -lh models/clip/
ls -lh models/text_encoders/
ls -lh models/diffusion_models/

# ─────────────────────────────────────────────
# 4. START
# ─────────────────────────────────────────────
echo "=== STARTING COMFYUI ==="
python main.py --listen 0.0.0.0 --port 8188
