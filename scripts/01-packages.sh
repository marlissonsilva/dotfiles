#!/bin/bash
set -e
DOTFILES_DIR="$1"

echo "Atualizando sistema e instalando pacotes..."

# Garante que pacman.conf tenha opções úteis (como em Omarchy)
if ! sudo grep -q '^Color' /etc/pacman.conf; then
  sudo sed -i '/^\[options\]/a Color' /etc/pacman.conf
fi
if ! sudo grep -q '^ParallelDownloads' /etc/pacman.conf; then
   sudo sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf
fi
 if ! sudo grep -q '^ILoveCandy' /etc/pacman.conf; then
   sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf
fi


# Ler pacotes da lista e instalar
mapfile -t packages < <(grep -v '^#' "$DOTFILES_DIR/packages.list" | grep -v '^$')

# Atualizar repositórios e instalar
sudo pacman -Syu --noconfirm --needed "${packages[@]}"

echo "Instalação de pacotes concluída."