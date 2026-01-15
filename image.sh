#!/bin/bash
set -e

source /venv/main/bin/activate

WORKSPACE=${WORKSPACE:-/workspace}
COMFYUI_DIR=${WORKSPACE}/ComfyUI

echo "=== Vast.ai ComfyUI provisioning ==="

# ─────────────────────────────────────────────
# 1. Clone ComfyUI
# ─────────────────────────────────────────────
if [[ ! -d "${COMFYUI_DIR}" ]]; then
    echo "Cloning ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"
fi

cd "${COMFYUI_DIR}"

# ─────────────────────────────────────────────
# 2. Install base requirements
# ─────────────────────────────────────────────
if [[ -f requirements.txt ]]; then
    pip install --no-cache-dir -r requirements.txt
fi

# ─────────────────────────────────────────────
# 3. CONFIG
# ─────────────────────────────────────────────
NODES=(
    "https://github.com/ltdrdata/ComfyUI-Manager"
    "https://github.com/kijai/ComfyUI-WanVideoWrapper"
)

CLIP_JSON_MODELS=(
    "https://huggingface.co/arhiteector/qwen_3_4b.safetnsors/resolve/main/qwen_3_4b.safetensors"
)

TEXT_MODELS=(
    "https://huggingface.co/UmeAiRT/ComfyUI-Auto_installer/resolve/refs%2Fpr%2F5/models/clip/umt5-xxl-encoder-fp8-e4m3fn-scaled.safetensors"
)

UNET_MODELS=(
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors"
)

VAE_MODELS=(
    "https://huggingface.co/Owen777/UltraFlux-v1/resolve/main/vae/diffusion_pytorch_model.safetensors"
)

# ─────────────────────────────────────────────
# 4. FUNCTIONS
# ─────────────────────────────────────────────
download_files() {
    local dir="$1"
    shift
    mkdir -p "$dir"

    for url in "$@"; do
        echo "Downloading: $url"
        if [[ -n "$HF_TOKEN" && "$url" =~ huggingface.co ]]; then
            wget --header="Authorization: Bearer $HF_TOKEN" \
                 -nc --content-disposition -P "$dir" "$url"
        else
            wget -nc --content-disposition -P "$dir" "$url"
        fi
    done
}

# ─────────────────────────────────────────────
# 5. Custom nodes
# ─────────────────────────────────────────────
mkdir -p custom_nodes

for repo in "${NODES[@]}"; do
    dir="${repo##*/}"
    path="custom_nodes/${dir}"
    requirements="${path}/requirements.txt"

    if [[ -d "$path" ]]; then
        echo "Updating node: $dir"
        (cd "$path" && git pull)
    else
        echo "Cloning node: $dir"
        git clone "$repo" "$path" --recursive
    fi

    [[ -f "$requirements" ]] && pip install --no-cache-dir -r "$requirements"
done

# ─────────────────────────────────────────────
# 6. Download models (ПРАВИЛЬНЫЕ ПУТИ)
# ─────────────────────────────────────────────
download_files "models\clip" "${CLIP_JSON_MODELS[@]}"
download_files "models/text_encoders" "${TEXT_FP8_MODELS[@]}"
download_files "models/unet" "${UNET_MODELS[@]}"
download_files "models/vae" "${VAE_MODELS[@]}"

# ─────────────────────────────────────────────
# 7. Launch
# ─────────────────────────────────────────────
echo "=== Starting ComfyUI ==="
python main.py --listen 0.0.0.0 --port 8188
