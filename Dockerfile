# ============================================================
# Custom Wan2.2 worker — CUDA 12.1 for RTX 4090 compatibility
# ============================================================
ARG BASE_IMAGE=nvidia/cuda:12.1.0-runtime-ubuntu22.04

FROM ${BASE_IMAGE} AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1
ENV CMAKE_BUILD_PARALLEL_LEVEL=8

# Install Python 3.10 + system deps
RUN apt-get update && apt-get install -y \
    python3.10 python3.10-venv python3-pip \
    git wget libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    ffmpeg openssh-server curl && \
    ln -sf /usr/bin/python3.10 /usr/bin/python && \
    ln -sf /usr/bin/pip3 /usr/bin/pip && \
    apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install uv
RUN wget -qO- https://astral.sh/uv/install.sh | sh && \
    ln -s /root/.local/bin/uv /usr/local/bin/uv && \
    ln -s /root/.local/bin/uvx /usr/local/bin/uvx && \
    uv venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# Install comfy-cli + ComfyUI
RUN uv pip install comfy-cli pip setuptools wheel
RUN /usr/bin/yes | comfy --workspace /comfyui install --version latest --cuda-version 12.1 --nvidia

WORKDIR /comfyui

# RunPod handler deps
RUN uv pip install runpod requests websocket-client

# ========== Download handler files from official repo ==========
WORKDIR /
RUN wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/main/handler.py -O /handler.py && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/main/src/start.sh -O /start.sh && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/main/src/network_volume.py -O /network_volume.py && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/main/src/extra_model_paths.yaml -O /extra_model_paths.yaml && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/main/test_input.json -O /test_input.json && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/main/scripts/comfy-node-install.sh -O /usr/local/bin/comfy-node-install && \
    wget -q https://raw.githubusercontent.com/runpod-workers/worker-comfyui/main/scripts/comfy-manager-set-mode.sh -O /usr/local/bin/comfy-manager-set-mode && \
    chmod +x /start.sh /usr/local/bin/comfy-node-install /usr/local/bin/comfy-manager-set-mode

ENV PIP_NO_INPUT=1

# ========== Custom nodes ==========
RUN git clone https://github.com/Kijai/ComfyUI-WanVideoWrapper.git /comfyui/custom_nodes/ComfyUI-WanVideoWrapper && \
    uv pip install -r /comfyui/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt

RUN git clone https://github.com/Flow-two/ComfyUI-WanStartEndFramesNative.git /comfyui/custom_nodes/ComfyUI-WanStartEndFramesNative

RUN git clone https://github.com/city96/ComfyUI-GGUF.git /comfyui/custom_nodes/ComfyUI-GGUF

RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git /comfyui/custom_nodes/ComfyUI-KJNodes && \
    uv pip install -r /comfyui/custom_nodes/ComfyUI-KJNodes/requirements.txt

# ========== Pre-download models (build time!) ==========
RUN mkdir -p /comfyui/models/unet_gguf && \
    wget -c https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q8_0.gguf \
    -O /comfyui/models/unet_gguf/wan2.1-i2v-14b-720p-Q8_0.gguf

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
