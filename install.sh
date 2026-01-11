#!/usr/bin/env bash

set -e

# ==========================================================
# VARIABLES
# ==========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Assets names
FONT_NAME=JetBrainsMono
CURSORS_NAME=oreo-teal-cursors
ICONS_NAME=Gruved_Green_Icons
THEMES_NAME=Gruved_Green

# Assets paths
assets=(
    # Fonts
    "fonts/.local/share/fonts/$FONT_NAME.tar.xz"

    # Cursors
    "icons/.icons/$CURSORS_NAME.tar.gz"

    # Icons
    "icons/.icons/$ICONS_NAME.tar.xz"

    # Themes
    "gtk-themes/.themes/$THEMES_NAME.tar.xz"
)

# ==========================================================
# FUNCTIONS
# ==========================================================

setup_sway_autostart() {
    echo -e "${GREEN}=== Configurando inicio automático de Sway ===${NC}"
    
    # Archivo de configuración (preferencia en orden)
    local config_files=(
        "$HOME/.bash_profile"
        "$HOME/.profile"
        "$HOME/.bash_login"
        "$HOME/.bashrc"
    )
    
    local selected_config=""
    
    # Buscar archivo existente
    for config in "${config_files[@]}"; do
        if [ -f "$config" ]; then
            selected_config="$config"
            break
        fi
    done
    
    # Si no existe ninguno, crear .bash_profile
    if [ -z "$selected_config" ]; then
        selected_config="$HOME/.bash_profile"
        touch "$selected_config"
        echo "# Created by Sway setup script" > "$selected_config"
    fi
    
    # Verificar si ya tiene la configuración
    local sway_config='# Start Sway automatically on login
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
    exec sway
fi'
    
    if grep -qF "exec sway" "$selected_config" 2>/dev/null; then
        echo -e "${YELLOW}Sway ya está configurado para iniciar automáticamente en $selected_config${NC}"
        return
    fi
    
    # Preguntar al usuario
    echo -e "${YELLOW}¿Deseas configurar Sway para iniciar automáticamente al iniciar sesión?${NC}"
    echo "Esto agregará:"
    echo "  if [ -z \"\${WAYLAND_DISPLAY}\" ] && [ \"\${XDG_VTNR}\" -eq 1 ]; then"
    echo "      exec sway"
    echo "  fi"
    echo -e "a ${selected_config}"
    
    if [ -t 0 ]; then
        read -p "¿Continuar? (s/N): " -n 1 -r
        echo
    else
        echo -e "${YELLOW}No hay TTY disponible, saltando confirmación interactiva${NC}"
        return
    fi
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        # Agregar línea en blanco si el archivo no termina con nueva línea
        if [ -s "$selected_config" ] && [ "$(tail -c1 "$selected_config")" != "" ]; then
            echo "" >> "$selected_config"
        fi
        
        # Agregar configuración
        echo "" >> "$selected_config"
        echo "$sway_config" >> "$selected_config"
        
        echo -e "${GREEN}✓ Configurado exitosamente${NC}"
        echo -e "${YELLOW}Nota: Necesitarás cerrar sesión y volver a iniciar para que tome efecto${NC}"
    else
        echo -e "${YELLOW}✓ Saltado. Puedes agregarlo manualmente después${NC}"
    fi
}

# ==========================================================
# [1/5] UPDATING
# ==========================================================

echo -e "${YELLOW}[1/5] ${GREEN}=== Actualizando sistema ===${NC}"
sudo apt update && sudo apt upgrade -y

# ==========================================================
# [2/5] INSTALLING PACKAGES
# ==========================================================

echo -e "${YELLOW}[2/5] ${GREEN}=== Instalando paquetes necesarios ===${NC}"
packages=(
    # Sistema y utilidades
    stow
    git
    
    # Core Sway
    sway swaybg swaylock swayidle xwayland
    
    # Barra y notificaciones
    waybar sway-notification-center
    
    # Terminal y launcher
    foot fuzzel
    
    # Utilidades
    grim slurp wl-clipboard thunar brightnessctl playerctl
    network-manager-gnome
    
    # Audio
    pipewire pipewire-pulse wireplumber
    
    # Navegador
    firefox-esr
    
    # Fuentes
    fonts-dejavu fonts-font-awesome
)

sudo apt install -y "${packages[@]}"

echo -e "${GREEN}✓ Paquetes instalados${NC}"

# ==========================================================
# [3/5] EXTRACTING FONTS, ICONS, CURSORS AND THEMES
# ==========================================================

echo -e "${YELLOW}[3/5] ${GREEN}=== Extrayendo fuentes, iconos, cursores y temas ===${NC}"

# Bucle para extraer
for asset_path in "${assets[@]}"; do
    # Verificamos que el archivo realmente exista antes de intentar nada
    if [ ! -f "$asset_path" ]; then
        echo -e "${RED}Advertencia: No se encontró $asset_path, ${YELLOW}saltando...${NC}"
        continue
    fi

    ASSET_TARGET="$HOME/$(dirname "$asset_path" | sed 's|^[^/]*/||')"
    mkdir -p "$ASSET_TARGET"
    echo -e "${YELLOW}Extrayendo $(basename "$asset_path")...${NC}"

    # COMANDO:
    # -x: extract
    # -f: file
    # -C: Change directory (Descomprime DIRECTAMENTE en el destino)
    tar -xf "$asset_path" -C "$ASSET_TARGET"
done

echo -e "${GREEN}✓ Assets extraídos (fuentes, iconos, cursores y temas) ${NC}"

# ==========================================================
# [4/5] INSTALLING RICE
# ==========================================================

echo -e "${YELLOW}[4/5] ${GREEN}=== Configuración con Stow ===${NC}"

# Verificar si estamos en un repositorio git
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Este directorio no es un repositorio git${NC}"
    echo -e "${YELLOW}Considera inicializarlo: git init${NC}"
fi

# Verificar si stow está disponible
if ! command -v stow &> /dev/null; then
    echo -e "${RED}Error: stow no está instalado${NC}"
    exit 1
fi

stow -t ~ -- */
echo -e "${GREEN}✓ Configuraciones enlazadas con Stow${NC}"

# Terminando configuración
echo -e "${YELLOW}Actualizando caché de fuentes...${NC}"
fc-cache -fv

# ==========================================================
# [5/5] FINISHING RICE
# ==========================================================

# Configuración de servicios
echo -e "${YELLOW}[5/5] ${GREEN}=== Habilitando servicios ===${NC}"
if ! systemctl --user enable --now pipewire pipewire-pulse wireplumber; then
    echo -e "${YELLOW}Aviso: No se pudieron habilitar algunos servicios. Verifica tu configuración.${NC}"
fi

# Configuring sway autostart
setup_sway_autostart

echo -e "${GREEN}✓ Autostart de sway configurado y servicios habilitados${NC}"

# ==========================================================
# DONE!
# ==========================================================

echo -e "${GREEN}✅ Listo!${NC}"
echo ""
echo "Siguientes pasos:"
echo "1. Cierra sesión"
echo "2. Inicia Sway desde TTY: ${YELLOW}sway${NC}"
echo "3. (Opcional) Agrega 'exec sway' a ~/.bash_profile"