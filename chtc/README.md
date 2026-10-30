# Running METL on CHTC

This directory holds the container image and job scripts for training METL on
[CHTC](https://chtc.cs.wisc.edu/) and the OSPool. The image is built from this repository's
checkout, so each image corresponds to one git commit.

| file | purpose |
|---|---|
| `Dockerfile` | image with the `uv.lock` environment, METL's code, data and the full PDB set from metl-pub |
| `Dockerfile.dockerignore` | build context exclusions for that Dockerfile |
| `pretrain_local.sh` | pretrain METL-Local on `processed-<dataset>.tar.gz` |
| `pretrain_global.sh` | pretrain METL-Global on `processed-global.tar.gz` |
| `finetune.sh` | finetune the bundled avGFP model on the bundled avGFP DMS data |
| `pretrain_local.sub` | example HTCondor submit file for `pretrain_local.sh` |

The image ships the repository at `/workspace/metl`. The scripts run in the job sandbox, link
`data/` from the image, and write logs and checkpoints to `./output`, which HTCondor transfers
back. Arguments after the required ones are passed through to the training script.

## Dependencies

The image runs `uv sync --frozen`, so it has the same packages as local development and CI.
On Linux, torch comes from the PyTorch CUDA 13.0 wheel index for both amd64 and arm64
(e.g. DGX Spark). Those wheels bundle the CUDA libraries, so the image has no CUDA base;
execute nodes need an NVIDIA driver that supports CUDA 13.0.

## Building the image

Build from the repository root, tagged with the commit SHA. Commit first so the tag and the
image contents match.

```bash
sha=$(git rev-parse --short HEAD)
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -f chtc/Dockerfile \
    --build-arg GIT_SHA="$(git rev-parse HEAD)" \
    -t <registry>/metl:"${sha}" \
    --push .
```

Inside a container, `$METL_GIT_SHA` holds the commit, and the job scripts print it at startup.

To update the PDB files, change `METL_PUB_REF` in the Dockerfile to a metl-pub commit.

## Producing the .sif

On an access point, convert the pushed image and copy it to OSDF:

```bash
apptainer build metl-"${sha}".sif docker://<registry>/metl:"${sha}"
```

Set `container_image` in the submit file to the uploaded `.sif`.

## Submitting

```bash
condor_submit chtc/pretrain_local.sub dataset=gb1 epochs=30 run_uuid=myrun01 data_dir=/path/to/tarballs
```

## Linting

```bash
shellcheck chtc/*.sh
shfmt -i 4 -d chtc/*.sh
```
