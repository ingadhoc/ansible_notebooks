#!/usr/bin/env bash

# Salir inmediatamente si un comando falla.
set -euo pipefail

## --- CONFIGURACIÓN Y VARIABLES ---
readonly SCRIPT_REVISION="v2.2-adhoc-install-only"
EXTENSIONS_TO_INSTALL=()
OVERWRITE_EXISTING=false

## --- FUNCIONES ---
log() {
  echo "[GNOME EXTENSIONS] $1"
}

check_dependencies() {
  local missing_deps=0
  for cmd in wget curl jq gnome-shell; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "Error: El comando requerido '$cmd' no se encuentra." >&2
      missing_deps=1
    fi
  done
  if [[ $missing_deps -eq 1 ]]; then
    echo "Por favor, instala las dependencias e inténtalo de nuevo." >&2
    exit 1
  fi
}

install_extensions() {
  local gnome_shell_version
  gnome_shell_version="$(gnome-shell --version | cut --delimiter=' ' --fields=3 | cut --delimiter='.' --fields=1,2)"

  log "Detectada versión de GNOME Shell: $gnome_shell_version"
  log "Instalando ${#EXTENSIONS_TO_INSTALL[@]} extensiones: ${EXTENSIONS_TO_INSTALL[*]}"

  for ext_id in "${EXTENSIONS_TO_INSTALL[@]}"; do
    local ext_info url ext_uuid

    log "Procesando instalación para ID: $ext_id"

    ext_info=$(curl -fsSL "https://extensions.gnome.org/extension-info/?pk=${ext_id}&shell_version=${gnome_shell_version}")

    if [ -z "$ext_info" ] || [ "$(echo "$ext_info" | jq -r '.uuid')" == "null" ]; then
      log "Error: No se encontró la extensión con ID $ext_id para la versión $gnome_shell_version. Omitiendo."
      continue
    fi

    ext_uuid=$(echo "$ext_info" | jq -r '.uuid')
    local target_dir="/home/$(logname)/.local/share/gnome-shell/extensions/${ext_uuid}"

    if [ -d "$target_dir" ] && [ "$OVERWRITE_EXISTING" = "false" ]; then
      log "La extensión '$ext_uuid' ya existe y no se especificó --overwrite. Omitiendo instalación."
      continue
    fi

    url="https://extensions.gnome.org$(echo "$ext_info" | jq -r '.download_url')"

    log "Descargando e instalando '${ext_uuid}'..."

    local tmp_file
    tmp_file=$(mktemp --suffix ".zip")

    wget -qO "$tmp_file" "$url"
    gnome-extensions install "$tmp_file" --force >/dev/null
    rm -f "$tmp_file"
    log "Instalación de '${ext_uuid}' completada."
  done
}

## --- PROCESAMIENTO DE ARGUMENTOS ---
if [ $# -eq 0 ]; then
  echo "Uso: $0 [--overwrite] <ID_EXTENSION_1> <ID_EXTENSION_2> ..."
  exit 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -o | --overwrite) OVERWRITE_EXISTING=true; shift;;
    -*) echo "Error: Opción desconocida: $1" >&2; exit 1;;
    *) EXTENSIONS_TO_INSTALL+=("$1"); shift;;
  esac
done

## --- EJECUCIÓN PRINCIPAL ---
check_dependencies
if [ ${#EXTENSIONS_TO_INSTALL[@]} -gt 0 ]; then
  install_extensions
  log "Proceso completado."
else
  log "No se especificaron IDs de extensiones para instalar."
fi