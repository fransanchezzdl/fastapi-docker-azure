# FastAPI con Docker y Azure

API REST desplegada en Azure Web App desde Azure Container Registry (ACR).

- `Dockerfile`: Python 3.12 slim, dependencias en una capa reutilizable y Uvicorn en el puerto 8000.
- `build-image.sh`: construye la imagen con las etiquetas de versión y `latest`.
- `push-to-acr.sh`: crea el registro si falta y sube ambas etiquetas.
- `deploy-webapp.sh`: crea el plan Linux B1 y la Web App, configura acceso a ACR, puerto y CORS.

## Preparación

Se necesitan Docker en ejecución, Azure CLI y una suscripción de Azure activa.

```bash
docker --version
az --version
az login
az account show
chmod +x build-image.sh push-to-acr.sh deploy-webapp.sh
```

## Prueba local

Desde la carpeta del proyecto:

```bash
./build-image.sh
docker run --rm --name fastapi-local --platform linux/amd64 -p 8000:8000 fastapi-app:1.0.0
```

La imagen se construye para `linux/amd64`, también en Mac con Apple Silicon, para utilizarla en Azure App Service.

En otra terminal:

```bash
curl http://localhost:8000/
curl http://localhost:8000/health
curl -i -X OPTIONS http://localhost:8000/health \
  -H 'Origin: https://example.com' \
  -H 'Access-Control-Request-Method: GET'
```

Las dos primeras peticiones deben devolver:

```json
{"message":"Hello World from Azure!","status":"running"}
{"status":"healthy","service":"FastAPI on Azure"}
```

La tercera debe devolver HTTP 200 y `access-control-allow-origin: *`.
La documentación interactiva está en http://localhost:8000/docs. Para detener el contenedor, pulsa Ctrl+C.

## Despliegue

Elige nombres globalmente únicos. El nombre de ACR debe tener entre 5 y 50 caracteres, usando letras minúsculas y números.

```bash
export ACR_NAME="registrofastapinut001"
export WEBAPP_NAME="web-fastapi-nut001"
export RESOURCE_GROUP="rg-fastapi-deploy"
export LOCATION="westeurope"
export VERSION="1.0.0"
export IMAGE_NAME="fastapi-app"

./push-to-acr.sh
./deploy-webapp.sh
```

Sustituye los dos nombres de ejemplo antes de ejecutar los scripts. `PLAN_NAME` se puede exportar también; su valor predeterminado es `plan-fastapi-deploy`.
Las credenciales se obtienen de ACR durante el despliegue y no se guardan en archivos.

El último script muestra la URL real de la aplicación. Comprueba `/`, `/health` y `/docs` en esa URL cuando termine el arranque.

Para publicar una nueva versión, cambia `VERSION` y ejecuta los tres scripts en orden:

```bash
export VERSION="1.0.1"
./build-image.sh
./push-to-acr.sh
./deploy-webapp.sh
```