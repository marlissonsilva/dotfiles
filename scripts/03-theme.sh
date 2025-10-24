#!/bin/bash
set -e
DOTFILES_DIR="$1"

echo "Configurando tema dark e ícones..."

# Definir tema GTK para Adwaita-dark
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
echo "Tema GTK definido como Adwaita-dark."

# Definir esquema de cores para preferir dark
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
echo "Esquema de cores definido como prefer-dark."

# Definir tema de ícones (Yaru-magenta como exemplo, similar ao Tokyo Night)
# Pode ser Yaru-blue, Yaru-purple, etc., conforme preferência.
gsettings set org.gnome.desktop.interface icon-theme 'Yaru-magenta'
echo "Tema de ícones definido como Yaru-magenta."

# Atualizar cache de ícones (importante para Nautilus)
if command -v gtk-update-icon-cache &> /dev/null; then
   echo "Atualizando cache de ícones Yaru..."
   sudo gtk-update-icon-cache /usr/share/icons/Yaru || echo "Falha ao atualizar cache Yaru (ignorado)"
   echo "Atualizando cache de ícones hicolor..."
   gtk-update-icon-cache ~/.local/share/icons/hicolor &>/dev/null || echo "Falha ao atualizar cache hicolor (ignorado)"
fi


echo "Configuração de tema concluída."