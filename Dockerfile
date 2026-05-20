# ============================================================
# Custom Wan2.2 worker — CUDA 12.1 for RTX 4090
# Global install, no venv, manual ComfyUI setup
# ============================================================
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_PREFER_BINARY=1
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python + system deps
RUN apt-get update && apt-get install -y \
    python3.10 python3.10-venv python3-pip \
    git wget curl libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    libgomp1 ffmpeg openssh-server \
    && ln -sf /usr/bin/python3.10 /usr/bin/python \
    && ln -sf /usr/bin/python3.10 /usr/bin/python3 \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install pip packages globally
RUN pip install --upgrade pip setuptools wheel
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui
WORKDIR /comfyui
RUN pip install -r requirements.txt

# RunPod deps + handler
RUN pip install runpod requests websocket-client

WORKDIR /

# Download official handler files (v5.1.0)
RUN wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/5.1.0/handler.py -O /handler.py && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/5.1.0/src/start.sh -O /start.sh && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/5.1.0/src/network_volume.py -O /network_volume.py && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/5.1.0/src/extra_model_paths.yaml -O /extra_model_paths.yaml && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/5.1.0/test_input.json -O /test_input.json && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/5.1.0/scripts/comfy-node-install.sh -O /usr/local/bin/comfy-node-install && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/5.1.0/scripts/comfy-manager-set-mode.sh -O /usr/local/bin/comfy-manager-set-mode && \
    chmod +x /start.sh /usr/local/bin/comfy-node-install /usr/local/bin/comfy-manager-set-mode

ENV PIP_NO_INPUT=1

# ========== Custom nodes ==========
RUN git clone https://github.com/Kijai/ComfyUI-WanVideoWrapper.git /comfyui/custom_nodes/ComfyUI-WanVideoWrapper && \
    pip install -r /comfyui/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt && \
    pip install --upgrade pillow

RUN git clone https://github.com/Flow-two/ComfyUI-WanStartEndFramesNative.git /comfyui/custom_nodes/ComfyUI-WanStartEndFramesNative

RUN git clone https://github.com/city96/ComfyUI-GGUF.git /comfyui/custom_nodes/ComfyUI-GGUF

RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git /comfyui/custom_nodes/ComfyUI-KJNodes && \
    pip install -r /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt

# ========== Pre-download models (build time!) ==========
RUN mkdir -p /comfyui/models/diffusion_models && \
    wget -c https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q8_0.gguf \
    -O /comfyui/models/diffusion_models/wan2.1-i2v-14b-720p-Q8_0.gguf

RUN mkdir -p /comfyui/models/clip && \
    wget -c https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
    -O /comfyui/models/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors

RUN mkdir -p /comfyui/models/clip_vision && \
    wget -c https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors \
    -O /comfyui/models/clip_vision/clip_vision_h.safetensors

RUN mkdir -p /comfyui/models/vae && \
    wget -c https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors \
    -O /comfyui/models/vae/wan_2.1_vae.safetensors

CMD ["/start.sh"]
