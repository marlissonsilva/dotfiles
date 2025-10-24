#!/bin/bash
set -e
DOTFILES_DIR="$1"
PACMAN_PKGS_FILE="$DOTFILES_DIR/packages_pacman.list"
AUR_PKGS_FILE="$DOTFILES_DIR/packages_aur.list"

echo "Atualizando sistema e configurando Pacman..."

# Garante que pacman.conf tenha opções úteis
sudo sed -i -e '/^#Color/s/^#//' \
           -e '/^#ParallelDownloads/s/^#Color/Color\nParallelDownloads = 5/' \
           -e '/^#VerbosePkgLists/s/^#//' /etc/pacman.conf
grep -q '^ILoveCandy' /etc/pacman.conf || sudo sed -i '/^\[options\]/a ILoveCandy' /etc/pacman.conf

# Sincroniza repositórios ANTES de qualquer instalação
echo "Sincronizando bancos de dados de pacotes..."
sudo pacman -Sy --noconfirm

# --- Instalação do Yay ---
echo "Verificando/Instalando yay (AUR Helper)..."
# Instala dependências básicas caso ainda não estejam
sudo pacman -S --needed --noconfirm git base-devel go # Go é necessário para compilar yay (não yay-bin)
if ! command -v yay &> /dev/null; then
    echo "yay não encontrado. Instalando yay do AUR..."
    TEMP_DIR=$(mktemp -d)
    # Tenta clonar yay-bin primeiro (mais rápido), senão yay (compilado)
    if git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-install"; then
        echo "Clonado yay-bin."
    elif git clone --depth=1 https://aur.archlinux.org/yay.git "$TEMP_DIR/yay-install"; then
        echo "Clonado yay (fonte)."
    else
        echo "Erro ao clonar o repositório do yay." >&2
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Entra no diretório e compila/instala
    (
      cd "$TEMP_DIR/yay-install"
      # Executa makepkg como o usuário que chamou sudo, se possível
      if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
          echo "Executando makepkg como usuário $SUDO_USER..."
          sudo -u "$SUDO_USER" makepkg -si --noconfirm
      elif [ "$EUID" -ne 0 ]; then
           echo "Executando makepkg como usuário atual..."
           makepkg -si --noconfirm
      else
           echo "AVISO: Script rodando como root sem SUDO_USER. Tentando makepkg como root (não recomendado)." >&2
           makepkg -si --noconfirm --asroot || (echo "Falha ao instalar yay como root. Abortando." >&2 && exit 1)
      fi
    ) # Fim do subshell

    # Limpeza
    rm -rf "$TEMP_DIR"
    # Verifica se yay foi instalado
    if ! command -v yay &> /dev/null; then
        echo "Erro: A instalação do yay falhou." >&2
        exit 1
    fi
    echo "yay instalado com sucesso."
else
    echo "yay já está instalado."
fi
# --- Fim da Instalação do Yay ---

# Combina as listas de pacotes (Pacman e AUR), remove comentários e linhas vazias/duplicadas
echo "Lendo listas de pacotes..."
mapfile -t all_packages < <(cat "$PACMAN_PKGS_FILE" "$AUR_PKGS_FILE" | awk '!/^($|#)/{sub(/#.*/,""); print $1}' | sort -u)

# Instala TODOS os pacotes usando Yay
if [ ${#all_packages[@]} -gt 0 ]; then
    echo "Instalando/Atualizando todos os pacotes listados com Yay..."
    echo "Pacotes a serem gerenciados: ${all_packages[@]}"
    # Garante que yay use o usuário normal, não root diretamente
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
         echo "Executando yay como usuário $SUDO_USER..."
         # Usa sudo -E para preservar algumas variáveis de ambiente que yay pode precisar
         sudo -E -u "$SUDO_USER" yay -S --needed --noconfirm "${all_packages[@]}"
    elif [ "$EUID" -ne 0 ]; then
         echo "Executando yay como usuário atual..."
         yay -S --needed --noconfirm "${all_packages[@]}"
    else
         echo "AVISO: Script rodando como root sem SUDO_USER definido. Não foi possível instalar pacotes via yay." >&2
         echo "Instale manualmente: yay -S ${all_packages[@]}"
    fi
else
    echo "Nenhum pacote listado para instalar."
fi

echo "Instalação de pacotes concluída."