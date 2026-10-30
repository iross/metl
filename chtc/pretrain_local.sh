#!/bin/bash
# Pretrain a METL-Local model on a Rosetta dataset transferred into the job sandbox
# as processed-<dataset>.tar.gz. Extra arguments are passed to train_source_model.py.
set -euo pipefail

usage() {
    echo "usage: $0 <epochs> <run_uuid> <random_seed> <dataset> [train_source_model.py args...]" >&2
    exit 1
}

[ $# -ge 4 ] || usage
epochs=$1
run_uuid=$2
random_seed=$3
dataset=$4
shift 4

metl_dir=/workspace/metl
echo "METL image revision: ${METL_GIT_SHA:-unknown}"
if command -v nvidia-smi >/dev/null; then nvidia-smi; fi

mkdir -p "${dataset}"
tar -xzf "processed-${dataset}.tar.gz" -C "${dataset}" --strip-components=1

shopt -s nullglob
split_dirs=("${dataset}"/splits/*/)
if [ ${#split_dirs[@]} -ne 1 ]; then
    echo "expected exactly one split dir in ${dataset}/splits, found ${#split_dirs[@]}" >&2
    exit 1
fi

ln -sfn "${metl_dir}/data" data

python "${metl_dir}/code/train_source_model.py" "@${metl_dir}/args/pretrain_local.txt" \
    --ds_fn "${PWD}/${dataset}/${dataset}.db" \
    --split_dir "${PWD}/${split_dirs[0]%/}" \
    --max_epochs "${epochs}" \
    --uuid "${run_uuid}" \
    --random_seed "${random_seed}" \
    "$@"
