#!/bin/bash
# Finetune the bundled pretrained avGFP model on the avGFP DMS data that ships with the image.
# Extra arguments are passed to train_target_model.py.
set -euo pipefail

usage() {
    echo "usage: $0 <epochs> [train_target_model.py args...]" >&2
    exit 1
}

[ $# -ge 1 ] || usage
epochs=$1
shift 1

metl_dir=/workspace/metl
echo "METL image revision: ${METL_GIT_SHA:-unknown}"
if command -v nvidia-smi >/dev/null; then nvidia-smi; fi

ln -sfn "${metl_dir}/data" data
ln -sfn "${metl_dir}/pretrained_models" pretrained_models

python "${metl_dir}/code/train_target_model.py" "@${metl_dir}/args/finetune_avgfp_local.txt" \
    --enable_progress_bar false \
    --enable_simple_progress_messages \
    --max_epochs "${epochs}" \
    --unfreeze_backbone_at_epoch 25 \
    "$@"
