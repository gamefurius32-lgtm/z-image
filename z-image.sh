#!/bin/bash
set -e

source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== Vast.ai ComfyUI provisioning (STRICT PATHS FIXED) ==="

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
# 3. Custom nodes
# ─────────────────────────────────────────────
mkdir -p custom_nodes

clone_or_update () {
    local repo="$1"
    local dir="$2"
    if [[ ! -d "$dir" ]]; then
        git clone "$repo" "$dir"
    else
        (cd "$dir" && git pull)
    fi
}

clone_or_update https://github.com/ltdrdata/ComfyUI-Manager custom_nodes/ComfyUI-Manager
clone_or_update https://github.com/MattEODev/ComfyUI_essentials custom_nodes/ComfyUI_essentials
clone_or_update https://github.com/ClownsharkBatwing/RES4LYF custom_nodes/RES4LYF
clone_or_update https://github.com/Kijai/ComfyUI-KJNodes custom_nodes/ComfyUI-KJNodes

pip install --no-cache-dir \
    einops accelerate transformers kornia || true

# ─────────────────────────────────────────────
# 4. Model folders
# ─────────────────────────────────────────────
mkdir -p models/diffusion_models
mkdir -p models/clip
mkdir -p models/vae
mkdir -p models/text_encoders

# ─────────────────────────────────────────────
# 5. MODELS — ЖЁСТКО В НУЖНЫЕ МЕСТА
# ─────────────────────────────────────────────

echo "→ z_image_turbo_bf16.safetensors"
wget -nc \
https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors \
-O models/diffusion_models/z_image_turbo_bf16.safetensors

echo "→ qwen_3_4b.safetensors (CLIP)"
wget -nc \
https://huggingface.co/arhiteector/qwen_3_4b.safetnsors/resolve/main/qwen_3_4b.safetensors \
-O models/clip/qwen_3_4b.safetensors

echo "→ UltraFlux VAE"
wget -nc \
https://huggingface.co/Owen777/UltraFlux-v1/resolve/main/vae/diffusion_pytorch_model.safetensors \
-O models/vae/UltraFlux-v1_model.safetensors

echo "→ umt5 XXL text encoder"
wget -nc \
https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/refs%2Fpr%2F5/models/clip/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors \
-O models/text_encoders/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors

# ─────────────────────────────────────────────
# 6. Launch
# ─────────────────────────────────────────────
echo "=== Starting ComfyUI ==="
python main.py --listen 0.0.0.0 --port 8188
