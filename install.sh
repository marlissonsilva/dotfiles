#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Iniciando a instalação dos dotfiles..."

# Executar scripts auxiliares em ordem
for script in "$DOTFILES_DIR"/scripts/*.sh; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "Executando $(basename "$script")..."
        bash "$script" "$DOTFILES_DIR"
    else
         echo "Aviso: Script $script não encontrado ou não executável."
    fi
done

echo "Instalação dos dotfiles concluída! Reinicie a sessão para aplicar todas as mudanças."
exit 0