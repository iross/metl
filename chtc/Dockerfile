# METL training image for CHTC. Build from the repo root; see chtc/README.md.
# The PyPI CUDA 13.0 torch wheels in uv.lock bundle the CUDA libraries they need; the host
# supplies only the NVIDIA driver (apptainer --nv), so no CUDA base image is required.
ARG BASE=ghcr.io/astral-sh/uv:0.13.5-python3.12-trixie-slim@sha256:9b8477a5f2e2f96fa99eaecb7680c1c4c9f527926430f3b630bfb2c3641f8f20

# The full PDB set lives in metl-pub, not this repo.
FROM ${BASE} AS pdbs
ARG METL_PUB_REF=c4770057a594271ecd6f3e906ecf7945b1d80eb4
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*
RUN git init -q /metl-pub \
    && git -C /metl-pub remote add origin https://github.com/gitter-lab/metl-pub \
    && git -C /metl-pub sparse-checkout set data/pdb_files \
    && git -C /metl-pub fetch -q --depth 1 --filter=blob:none origin "${METL_PUB_REF}" \
    && git -C /metl-pub checkout -q FETCH_HEAD

FROM ${BASE}
ARG GIT_SHA=unknown

LABEL org.opencontainers.image.source="https://github.com/iross/metl" \
      org.opencontainers.image.revision="${GIT_SHA}"

ENV UV_COMPILE_BYTECODE=1 \
    UV_NO_CACHE=1 \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    UV_PYTHON_DOWNLOADS=never \
    PATH=/opt/venv/bin:$PATH

WORKDIR /workspace/metl

# Dependencies first so this layer is reused across code changes.
RUN --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen --no-install-project

COPY . .
COPY --from=pdbs /metl-pub/data/pdb_files/*.pdb data/pdb_files/

ENV METL_GIT_SHA="${GIT_SHA}"

CMD ["/bin/bash"]
