#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-1.0.0}"
IMAGE_NAME="${IMAGE_NAME:-fastapi-app}"
ACR_NAME="${ACR_NAME:?Define ACR_NAME con el nombre del registro}"
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-fastapi-deploy}"
LOCATION="${LOCATION:-westeurope}"
PLAN_NAME="${PLAN_NAME:-plan-fastapi-deploy}"
WEBAPP_NAME="${WEBAPP_NAME:?Define WEBAPP_NAME con un nombre globalmente único}"

echo "Preparando el grupo de recursos y el plan Linux..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
if ! az appservice plan show --name "$PLAN_NAME" --resource-group "$RESOURCE_GROUP" --output none 2>/dev/null; then
    az appservice plan create --name "$PLAN_NAME" --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" --is-linux --sku B1 --output none
fi

echo "Configurando el acceso al registro..."
az acr update --name "$ACR_NAME" --admin-enabled true --output none
ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)
ACR_USER=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query 'passwords[0].value' --output tsv)

echo "Desplegando ${IMAGE_NAME}:${VERSION}..."
az webapp create --resource-group "$RESOURCE_GROUP" --plan "$PLAN_NAME" \
    --name "$WEBAPP_NAME" --sitecontainers-app false \
    --container-image-name "${IMAGE_NAME}:${VERSION}" \
    --container-registry-url "https://${ACR_SERVER}" \
    --container-registry-user "$ACR_USER" \
    --container-registry-password "$ACR_PASSWORD" --output none

az webapp config appsettings set --resource-group "$RESOURCE_GROUP" \
    --name "$WEBAPP_NAME" --settings WEBSITES_PORT=8000 --output none
az webapp cors add --resource-group "$RESOURCE_GROUP" \
    --name "$WEBAPP_NAME" --allowed-origins '*' --output none

HOSTNAME=$(az webapp show --resource-group "$RESOURCE_GROUP" \
    --name "$WEBAPP_NAME" --query defaultHostName --output tsv)
echo "Aplicación desplegada: https://${HOSTNAME}"
echo "Comprobar estado: https://${HOSTNAME}/health (el inicio puede tardar unos minutos)"
