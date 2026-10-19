#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-1.0.0}"
IMAGE_NAME="${IMAGE_NAME:-fastapi-app}"
ACR_NAME="${ACR_NAME:?Define ACR_NAME con un nombre globalmente único}"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-fastapi-deploy}"
LOCATION="${LOCATION:-westeurope}"

echo "Preparando el grupo de recursos y el registro..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
if ! az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --output none 2>/dev/null; then
    az acr create --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" --sku Basic --admin-enabled true --output none
fi

az acr login --name "$ACR_NAME"
ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)

for TAG in "$VERSION" latest; do
    echo "Subiendo ${ACR_SERVER}/${IMAGE_NAME}:${TAG}..."
    docker tag "${IMAGE_NAME}:${VERSION}" "${ACR_SERVER}/${IMAGE_NAME}:${TAG}"
    docker push "${ACR_SERVER}/${IMAGE_NAME}:${TAG}"
done

echo "Etiquetas disponibles en ACR:"
az acr repository show-tags --name "$ACR_NAME" --repository "$IMAGE_NAME" --output table
