#!/usr/bin/env bash
# Start the Wan2.2 T2V media server (image 0.10.0-555f240, p150x4) with the
# early-denoising-readout patch mounted over the image's files.
#
# Usage:
#   API_KEY=<key> WAN_STOP_AFTER_STEP=10 ./run_patched.sh
#   API_KEY=<key> ./run_patched.sh          # no early stop: identical to stock
#
# Per generation, add "stop_after_step": N to the POST /v1/videos/generations
# body (1 <= N <= num_inference_steps). It overrides WAN_STOP_AFTER_STEP, which
# is only the default for requests that leave the field out.
#
# The originals copied from the image are in ./orig (read-only).
# Mirrors the docker run that run.py logged on 2026-11-08, plus the -v mounts.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
IMG=ghcr.io/tenstorrent/tt-media-inference-server:0.10.0-555f240
APP=/home/container_app_user/tt-metal

: "${API_KEY:?set API_KEY (same value as the -e API_KEY in your run.py log)}"
STOP="${WAN_STOP_AFTER_STEP:-}"

docker run \
  --rm \
  --name tt-inference-server-wan-readout \
  --env-file "$REPO/.env" \
  --ipc host \
  --device /dev/tenstorrent:/dev/tenstorrent \
  --mount type=bind,src=/dev/hugepages-1G,dst=/dev/hugepages-1G \
  --publish 0.0.0.0:8000:8000 \
  --volume volume_id_tt_transformers-Wan2.2-T2V-A14B-Diffusers:/home/container_app_user/cache_root \
  -v "$HERE/pipeline_wan.py:$APP/models/tt_dit/pipelines/wan/pipeline_wan.py:ro" \
  -v "$HERE/dit_runners.py:$APP/server/tt_model_runners/dit_runners.py:ro" \
  -v "$HERE/video_generate_request.py:$APP/server/domain/video_generate_request.py:ro" \
  -e MESH_DEVICE=P150x4 \
  -e ARCH_NAME=blackhole \
  -e CACHE_ROOT=/home/container_app_user/cache_root \
  -e HF_HOME=/home/container_app_user/cache_root/huggingface \
  -e MODEL=Wan2.2-T2V-A14B-Diffusers \
  -e DEVICE=p150x4 \
  -e API_KEY="$API_KEY" \
  -e WAN_STOP_AFTER_STEP="$STOP" \
  "$IMG"
