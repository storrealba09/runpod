FROM runpod/worker-comfyui:5.1.0-base

# ============================================================
# Install custom nodes
# ============================================================

# WanVideo base — required for all Wan2.2 video workflows
RUN git clone https://github.com/Kijai/ComfyUI-WanVideoWrapper.git /comfyui/custom_nodes/ComfyUI-WanVideoWrapper && \
    pip install -r /comfyui/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt

# Start + End Frame I2V — generates video BETWEEN two images
RUN git clone https://github.com/Flow-two/ComfyUI-WanStartEndFramesNative.git /comfyui/custom_nodes/ComfyUI-WanStartEndFramesNative

# GGUF model loader — for loading quantized Wan2.2 models
RUN git clone https://github.com/city96/ComfyUI-GGUF.git /comfyui/custom_nodes/ComfyUI-GGUF

# KJNodes — provides WanVideoEnhanceAVideo, SkipLayerGuidance and more
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git /comfyui/custom_nodes/ComfyUI-KJNodes

# ============================================================
# Pre-download models (into Docker image, not at runtime)
# ============================================================

# Wan2.2 I2V GGUF model (Q4_K_M = ~7GB, fits 24GB VRAM)
RUN comfy model download \
  --url https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q8_0.gguf \
  --relative-path models/unet_gguf \
  --filename wan2.1-i2v-14b-720p-Q8_0.gguf

# UMT5 text encoder for Wan2.1
RUN comfy model download \
  --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  --relative-path models/clip \
  --filename umt5_xxl_fp8_e4m3fn_scaled.safetensors

# CLIP vision encoder
RUN comfy model download \
  --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors \
  --relative-path models/clip_vision \
  --filename clip_vision_h.safetensors

# Wan2.1 VAE
RUN comfy model download \
  --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors \
  --relative-path models/vae \
  --filename wan_2.1_vae.safetensors
