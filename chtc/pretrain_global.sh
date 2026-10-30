#!/bin/bash
# Pretrain a METL-Global model on the global Rosetta dataset transferred into the job sandbox
# as processed-global.tar.gz. Extra arguments are passed to train_source_model.py.
set -euo pipefail

usage() {
    echo "usage: $0 <epochs> <run_uuid> <random_seed> [train_source_model.py args...]" >&2
    exit 1
}

[ $# -ge 3 ] || usage
epochs=$1
run_uuid=$2
random_seed=$3
shift 3

metl_dir=/workspace/metl
split_name=standard_tr0.9_tu0.05_te0.05_w2a93d88bac32_r2098
echo "METL image revision: ${METL_GIT_SHA:-unknown}"
if command -v nvidia-smi >/dev/null; then nvidia-smi; fi

tar -xzf processed-global.tar.gz
rm processed-global.tar.gz

ln -sfn "${metl_dir}/data" data

python "${metl_dir}/code/train_source_model.py" "@${metl_dir}/args/pretrain_global.txt" \
    --ds_fn "${PWD}/global/global.db" \
    --split_dir "${PWD}/global/splits/${split_name}" \
    --max_epochs "${epochs}" \
    --uuid "${run_uuid}" \
    --random_seed "${random_seed}" \
    "$@"
