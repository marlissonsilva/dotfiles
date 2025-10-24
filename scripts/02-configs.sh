#!/bin/bash
set -e
DOTFILES_DIR="$1"

echo "Copiando arquivos de configuração..."

# Criar diretórios de configuração base
mkdir -p ~/.config

# Copiar configurações das aplicações (sobrescrevendo existentes)
# Use -T para tratar o destino como arquivo se a origem for arquivo, diretório se for diretório
cp -RT "$DOTFILES_DIR/config/" "$HOME/.config/"

echo "Cópia de configurações concluída."