#!/bin/bash

# Script de instalación de Themix GUI en Debian
# Repositorio: https://github.com/themix-project/themix-gui

set -e  # Detener el script si hay algún error

echo "==================================="
echo "Instalador de Themix GUI para Debian"
echo "==================================="
echo ""

# Colores para mensajes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # Sin color

# Verificar si se ejecuta como root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}No ejecutes este script como root/sudo${NC}"
   echo "El script solicitará permisos sudo cuando sea necesario"
   exit 1
fi

echo -e "${YELLOW}[1/4] Actualizando repositorios...${NC}"
sudo apt update

echo -e "${YELLOW}[2/4] Instalando dependencias necesarias...${NC}"
sudo apt install -y \
    git \
    python3 \
    python3-pip \
    python3-gi \
    python3-gi-cairo \
    python3-pil \
    python3-pystache \
    python3-yaml \
    gir1.2-gtk-3.0 \
    gir1.2-gdkpixbuf-2.0 \
    libgdk-pixbuf-2.0-0 \
    libgdk-pixbuf-2.0-dev \
    libgdk-pixbuf2.0-bin \
    libglib2.0-dev \
    libglib2.0-bin \
    librsvg2-bin \
    sassc \
    inkscape \
    optipng \
    imagemagick \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    libxml2-utils \
    parallel \
    meson \
    breeze-icon-theme \
    bc \
    sed \
    findutils \
    grep \
    zip \
    make

# Dependencias opcionales para importar colores de imágenes
echo -e "${YELLOW}Instalando dependencias opcionales de Python...${NC}"
pip3 install --user --break-system-packages colorz colorthief haishoku 2>/dev/null || \
pip3 install --user colorz colorthief haishoku 2>/dev/null || \
echo "Algunas dependencias opcionales no se pudieron instalar (no crítico)"

echo -e "${YELLOW}[3/4] Descargando Themix GUI con plugins...${NC}"
INSTALL_DIR="$HOME/.local/share/themix-gui"

# Si existe instalación previa, hacer backup
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Detectada instalación previa.  Creando backup...${NC}"
    mv "$INSTALL_DIR" "$INSTALL_DIR.backup.$(date +%Y%m%d-%H%M%S)"
fi

# Clonar repositorio con submódulos (plugins)
echo "Clonando repositorio con plugins..."
git clone https://github.com/themix-project/oomox.git --recursive "$INSTALL_DIR"

echo -e "${YELLOW}[4/4] Configurando accesos y permisos...${NC}"

# Generar locales
cd "$INSTALL_DIR"
if [ -f "po.mk" ]; then
    echo "Generando locales..."
    make -f po.mk install 2>/dev/null || echo "No se pudieron generar locales (no crítico)"
fi

# Dar permisos de ejecución
chmod +x "$INSTALL_DIR/gui.sh"

# Crear script wrapper
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/themix-gui" << 'EOF'
#!/bin/bash
cd "$HOME/.local/share/themix-gui"
./gui.sh "$@"
EOF

chmod +x "$HOME/.local/bin/themix-gui"

# Agregar ~/.local/bin al PATH si no está
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "" >> "$HOME/.bashrc"
    echo "# Agregar ~/.local/bin al PATH" >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo -e "${GREEN}Se agregó ~/.local/bin al PATH en ~/.bashrc${NC}"
    echo -e "${YELLOW}Ejecuta: source ~/.bashrc o reinicia la terminal${NC}"
fi

# Crear entrada de escritorio
echo -e "${YELLOW}Creando acceso directo en el menú de aplicaciones...${NC}"
mkdir -p "$HOME/.local/share/applications"

cat > "$HOME/.local/share/applications/themix-gui.desktop" << EOF
[Desktop Entry]
Name=Themix GUI
Comment=Graphical application for generating different color variations of themes
Exec=$HOME/.local/bin/themix-gui
Icon=$INSTALL_DIR/packaging/com.github.themix_project.Oomox.svg
Terminal=false
Type=Application
Categories=GTK;Settings;DesktopSettings;
Keywords=theme;colors;gtk;icon;
EOF

chmod +x "$HOME/.local/share/applications/themix-gui.desktop"

echo ""
echo -e "${GREEN}==================================="
echo -e "✓ Instalación completada con éxito"
echo -e "===================================${NC}"
echo ""
echo "Puedes iniciar Themix GUI de estas formas:"
echo "  1. Desde el menú de aplicaciones (busca 'Themix GUI')"
echo "  2. Desde la terminal: themix-gui"
echo ""
echo -e "${YELLOW}Nota: ${NC} Si ejecutas desde terminal por primera vez, haz:"
echo "  source ~/.bashrc"
echo ""
echo "Instalación ubicada en:"
echo "  $INSTALL_DIR"
echo ""
echo "Para actualizar Themix GUI:"
echo "  cd $INSTALL_DIR && git pull && git submodule update --recursive"
echo ""
echo "Para desinstalar, ejecuta:"
echo "  rm -rf $INSTALL_DIR"
echo "  rm $HOME/.local/bin/themix-gui"
echo "  rm $HOME/.local/share/applications/themix-gui.desktop"
