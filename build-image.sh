#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-1.0.0}"
IMAGE_NAME="${IMAGE_NAME:-fastapi-app}"

cd "$(dirname "$0")"
echo "Construyendo ${IMAGE_NAME}:${VERSION}..."
docker build --platform linux/amd64 \
    -t "${IMAGE_NAME}:${VERSION}" -t "${IMAGE_NAME}:latest" .
echo "Imagen creada: ${IMAGE_NAME}:${VERSION} y ${IMAGE_NAME}:latest"
