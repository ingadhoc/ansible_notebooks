#!/usr/bin/env bash

# Salir inmediatamente si algo falla.
set -e

# Directorio final para el binario
DEST_DIR="/usr/local/bin"
DEST_BIN="${DEST_DIR}/rancher"

# 1. Obtener la última versión desde la API de GitHub
LATEST_VERSION_TAG=$(curl -s https://api.github.com/repos/rancher/cli/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION_TAG" ]; then
    echo "Error: No se pudo obtener la última versión de Rancher CLI."
    exit 1
fi

# 2. Comprobar si ya está instalado y es la última versión
if [ -f "$DEST_BIN" ]; then
    CURRENT_VERSION=$($DEST_BIN --version | awk '{print $3}')
    if [ "$CURRENT_VERSION" == "$LATEST_VERSION_TAG" ]; then
        echo "Rancher CLI ya está en la última versión ($CURRENT_VERSION). No se necesita hacer nada."
        exit 0
    fi
    echo "Se encontró la versión $CURRENT_VERSION. Actualizando a $LATEST_VERSION_TAG..."
fi

# 3. Descargar y extraer
DOWNLOAD_URL="https://github.com/rancher/cli/releases/download/${LATEST_VERSION_TAG}/rancher-linux-amd64-${LATEST_VERSION_TAG}.tar.gz"

echo "Descargando Rancher CLI ${LATEST_VERSION_TAG}..."
cd /tmp
wget -q -O rancher.tar.gz "$DOWNLOAD_URL"
tar -xzf rancher.tar.gz

# 4. Mover al destino y limpiar
mv "rancher-${LATEST_VERSION_TAG}/rancher" "$DEST_BIN"
rm -rf rancher.tar.gz "rancher-${LATEST_VERSION_TAG}"

echo "Rancher CLI instalado/actualizado a la versión $LATEST_VERSION_TAG."
