FROM runpod/worker-comfyui:5.1.0-base

# ============================================================
# Install custom nodes
# ============================================================

# WanVideo base — required for all Wan2.2 video workflows
RUN git clone https://github.com/Kijai/ComfyUI-WanVideoWrapper.git /comfyui/custom_nodes/ComfyUI-WanVideoWrapper && \
    pip install -r /comfyui/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt

# Start + End Frame I2V — generates video BETWEEN two images
RUN git clone https://github.com/Flow-two/ComfyUI-WanStartEndFramesNative.git /comfyui/custom_nodes/ComfyUI-WanStartEndFramesNative

# ============================================================
# Pre-download Wan2.2 I2V GGUF model (fits 24GB VRAM)
# Auto-downloads on first use if not present, but pre-downloading
# speeds up cold starts by ~2 min
# ============================================================

# Wan2.2 I2V GGUF quantized — works on RTX 4090 (24GB)
# Model auto-downloads via WanVideoWrapper on first use
