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


# Ler pacotes da lista, removendo comentários e espaços extras
mapfile -t packages < <(awk '!/^($|#)/{sub(/#.*/,""); print $1}' "$DOTFILES_DIR/packages.list")

# Sincronizar repositórios e instalar
# A flag -y é crucial para garantir que a lista de pacotes esteja atualizada
echo "Sincronizando bancos de dados de pacotes..."
sudo pacman -Sy --noconfirm

echo "Instalando pacotes..."
sudo pacman -S --noconfirm --needed "${packages[@]}"

echo "Instalação de pacotes concluída."