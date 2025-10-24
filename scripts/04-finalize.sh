#!/bin/bash
set -e
DOTFILES_DIR="$1"

echo "Finalizando configuração..."

# Atualizar database de aplicações .desktop
if command -v update-desktop-database &> /dev/null; then
    echo "Atualizando database de aplicações..."
    update-desktop-database ~/.local/share/applications &>/dev/null || true
fi

# Definir Nautilus como gerenciador padrão (se necessário, geralmente já é)
# xdg-mime default org.gnome.Nautilus.desktop inode/directory

# Definir Alacritty como terminal padrão (exemplo, ajuste se usar outro)
# gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty'

echo "Configuração finalizada."