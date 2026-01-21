#!/usr/bin/env bash

set -e
# ==========================================================
# VARIABLES
# ==========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==========================================================

echo -e "${GREEN}=== Iniciando el proceso de actualización ===${NC}"

# GIT UPDATE ===============================================
if [ ! -d ".git" ]; then
    echo -e "${RED}No es un repositorio git. Ejecuta desde el directorio dotfiles.${NC}"
    exit 1
fi

# Verificar cambios locales
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}Hay cambios locales. Por favor, commitea o haz stash primero.${NC}"
    exit 1
fi

# Actualizar
echo -e "${GREEN}Pull desde remoto...${NC}"
if ! git pull --ff-only; then
    echo -e "${RED}Error al hacer pull. ¿Conflictos o divergencias?${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Repositorio actualizado exitosamente${NC}"

# STOW UPDATE ==============================================
# Verificar si stow está instalado
if ! command -v stow &> /dev/null; then
    echo -e "${RED}Error: stow no está instalado${NC}"
    exit 1
fi

echo -e "${GREEN}=== Aplicando GNU Stow para aplicar configuraciones ===${NC}"

# Aplicar stow
if ! stow -t ~ --restow */; then
    echo -e "${RED}Error: la ejecución de GNU Stow ha fallado.${NC}"
    exit 1
fi

# RELOAD SWAY IF RUNNING ===================================
# Solo si sway está en ejecución
if pgrep -x sway > /dev/null; then
    echo -e "${GREEN}🔄 Recargando Sway...${NC}"
    # Recargar la configuración de Sway
    if ! swaymsg reload; then
        echo -e "${RED}Error: fallo al recargar Sway. Revisa tu configuración de Sway.${NC}" >&2
    fi
fi

# FINAL MESSAGE ============================================
echo -e "${GREEN}=== Actualización completada ===${NC}"