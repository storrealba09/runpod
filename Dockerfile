FROM runpod/worker-comfyui:5.1.0-base

# ============================================================
# Install custom nodes
# ============================================================

# WanVideo base — required for all Wan2.2 video workflows
RUN comfy-node-install Kijai/ComfyUI-WanVideoWrapper

# Start + End Frame I2V — generates video BETWEEN two images
RUN comfy-node-install Flow-two/ComfyUI-WanStartEndFramesNative

# ============================================================
# Download Wan2.2 models (pre-cached for faster cold starts)
# ============================================================

# Wan2.2 I2V model — GGUF Q4_K_M quantized (fits 24GB VRAM)
RUN comfy model download \
  --url https://huggingface.co/Kijai/Wan2.2_VAE/resolve/main/Wan2.2_VAE_14B.safetensors \
  --relative-path models/vae \
  --filename Wan2.2_VAE_14B.safetensors

# Text encoder required for Wan2.2 conditioning
RUN comfy model download \
  --url https://huggingface.co/Kijai/Wan2.2_text_encoder/resolve/main/umt5_xxl_q8.safetensors \
  --relative-path models/text_encoders \
  --filename umt5_xxl_q8.safetensors

# ============================================================
# NOTE: The Wan2.2 model is ~7GB and will auto-download on
# first use if not present. For production, you can also
# pre-download it by uncommenting the line below.
# Or place it on a Network Volume for faster cold starts.
#
# Download options:
# A) GGUF (24GB VRAM) — auto-downloads with WanVideoWrapper
# B) Full model (needs 48GB+ VRAM)
# C) Network Volume (persistent storage, no re-download)
# ============================================================