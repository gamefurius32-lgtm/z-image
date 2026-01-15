#!/bin/bash
set -e

source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== Vast.ai ComfyUI provisioning (UltraFlux + Custom Nodes) ==="

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
# 3. Custom nodes (Manager + Requested Nodes)
# ─────────────────────────────────────────────
mkdir -p custom_nodes

# Функция для установки нод, чтобы не дублировать код
install_node() {
    local url="$1"
    local dir="$2"
    if [[ ! -d "custom_nodes/$dir" ]]; then
        git clone "$url" "custom_nodes/$dir"
    else
        (cd "custom_nodes/$dir" && git pull)
    fi
    if [[ -f "custom_nodes/$dir/requirements.txt" ]]; then
        pip install --no-cache-dir -r "custom_nodes/$dir/requirements.txt" || true
    fi
}

# Установка Manager
install_node "https://github.com/ltdrdata/ComfyUI-Manager" "ComfyUI-Manager"

# Установка твоих нод
install_node "https://github.com/cubiq/ComfyUI_Essentials" "ComfyUI_Essentials"
install_node "https://github.com/Recursion47/ComfyUI-RES4LYF" "ComfyUI-RES4LYF"
install_node "https://github.com/kijai/ComfyUI-KJNodes" "ComfyUI-KJNodes"

# ─────────────────────────────────────────────
# 4. Download helper (HF SAFE - FROM TEMPLATE)
# ─────────────────────────────────────────────
download() {
    local dir="$1"
    local url="$2"
    mkdir -p "$dir"
    echo "→ $url"
    wget -nc --content-disposition "$url" -P "$dir"
}

# ─────────────────────────────────────────────
# 5. MODELS (YOUR URLS)
# ─────────────────────────────────────────────

# VAE
download "models/vae" \
"https://huggingface.co/Owen777/UltraFlux-v1/resolve/main/vae/diffusion_pytorch_model.safetensors"

# CLIP (Исправил опечатку в safetensors в ссылке, чтобы точно скачалось)
download "models/clip" \
"https://huggingface.co/arhiteector/qwen_3_4b.safetensors/resolve/main/qwen_3_4b.safetensors"

# Text encoder
download "models/text_encoders" \
"https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/refs%2Fpr%2F5/models/clip/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors"

# Diffusion models
download "models/diffusion_models" \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"

# ─────────────────────────────────────────────
# 6. Launch
# ─────────────────────────────────────────────
echo "=== Starting ComfyUI ==="
python main.py --listen 0.0.0.0 --port 8188
