#!/bin/bash

TASK_ID="c9ea392b-1438-42cb-85ed-f8f89136f084"
MODEL="stablediffusionapi/omnium-sdxl"
DATASET_ZIP="https://s3.eu-central-003.backblazeb2.com/gradients-validator/24d0195e2cbd6634_train_data.zip?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=00362e8d6b742200000000002%2F20260522%2Feu-central-003%2Fs3%2Faws4_request&X-Amz-Date=20260522T023833Z&X-Amz-Expires=604800&X-Amz-SignedHeaders=host&X-Amz-Signature=2fe11dbb65aae4c31ebac5595dc50b2143908dd75405d1d2e85648afa6c6756c"
MODEL_TYPE="sdxl"
EXPECTED_REPO_NAME="sdxlboss-6"

HUGGINGFACE_TOKEN=""
HUGGINGFACE_USERNAME="Jordansky"
LOCAL_FOLDER="/app/checkpoints/$TASK_ID/$EXPECTED_REPO_NAME"

CONTAINER_NAME_DOWNLOADER="downloader-6"
CONTAINER_NAME_TRAINER="image-trainer-6"
CONTAINER_NAME_UPLOADER="hf-uploader-6"

CHECKPOINTS_DIR="$(pwd)/secure_checkpoints"
OUTPUTS_DIR="$(pwd)/outputs"
mkdir -p "$CHECKPOINTS_DIR"
chmod 700 "$CHECKPOINTS_DIR"
mkdir -p "$OUTPUTS_DIR"
chmod 700 "$OUTPUTS_DIR"

echo "[$EXPECTED_REPO_NAME] Downloading model and dataset..."
docker run --rm \
  --volume "$CHECKPOINTS_DIR:/cache:rw" \
  --name "$CONTAINER_NAME_DOWNLOADER" \
  trainer-downloader \
  --task-id "$TASK_ID" \
  --model "$MODEL" \
  --dataset "$DATASET_ZIP" \
  --task-type "ImageTask"

echo "[$EXPECTED_REPO_NAME] Starting image training..."
docker run --rm --gpus all \
  --security-opt=no-new-privileges \
  --cap-drop=ALL \
  --memory=32g \
  --cpus=8 \
  --network none \
  --env TRANSFORMERS_CACHE=/cache/hf_cache \
  --env D_COEF_SCALE="${D_COEF_SCALE:-}" \
  --env D_COEF_OVERRIDE="${D_COEF_OVERRIDE:-}" \
  --env TEXT_ENCODER_LR_SCALE="${TEXT_ENCODER_LR_SCALE:-}" \
  --env UNET_LR_SCALE="${UNET_LR_SCALE:-}" \
  --env CAPTION_VARIANTS="${CAPTION_VARIANTS:-1}" \
  --env CAPTION_VLM="${CAPTION_VLM:-}" \
  --env CLIP_FILTER_ENABLED="${CLIP_FILTER_ENABLED:-true}" \
  --env CLIP_FILTER_THRESHOLD="${CLIP_FILTER_THRESHOLD:-0.20}" \
  --env SWA_ENABLED="${SWA_ENABLED:-true}" \
  --env SWA_SKIP_FIRST_N="${SWA_SKIP_FIRST_N:-2}" \
  --env USE_DORA="${USE_DORA:-false}" \
  --volume "$CHECKPOINTS_DIR:/cache:rw" \
  --volume "$OUTPUTS_DIR:/app/checkpoints/:rw" \
  --name "$CONTAINER_NAME_TRAINER" \
  standalone-image-trainer \
  --task-id "$TASK_ID" \
  --model "$MODEL" \
  --dataset-zip "$DATASET_ZIP" \
  --model-type "$MODEL_TYPE" \
  --expected-repo-name "$EXPECTED_REPO_NAME" \
  --hours-to-complete 1.0

echo "[$EXPECTED_REPO_NAME] Uploading model to HuggingFace..."
docker run --rm --gpus all \
  --volume "$OUTPUTS_DIR:/app/checkpoints/:rw" \
  --env HUGGINGFACE_TOKEN="$HUGGINGFACE_TOKEN" \
  --env HUGGINGFACE_USERNAME="$HUGGINGFACE_USERNAME" \
  --env TASK_ID="$TASK_ID" \
  --env EXPECTED_REPO_NAME="$EXPECTED_REPO_NAME" \
  --env LOCAL_FOLDER="$LOCAL_FOLDER" \
  --env HF_REPO_SUBFOLDER="checkpoints" \
  --name "$CONTAINER_NAME_UPLOADER" \
  hf-uploader
