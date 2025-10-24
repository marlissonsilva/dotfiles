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
sudo pacman -S --needed --noconfirm git base-devel go
if ! command -v yay &> /dev/null; then
    echo "yay não encontrado. Instalando yay do AUR..."
    TEMP_DIR=$(mktemp -d)
    INSTALL_DIR="" # Para guardar o diretório de instalação

    # --- CORREÇÃO: Define o usuário alvo ---
    TARGET_USER="$SUDO_USER"
    TARGET_GROUP=$(id -gn "$TARGET_USER")
    if [ -z "$TARGET_USER" ]; then
        echo "AVISO: SUDO_USER não definido. Tentando usar usuário atual não-root." >&2
        if [ "$EUID" -ne 0 ]; then
            TARGET_USER=$(whoami)
            TARGET_GROUP=$(id -gn "$TARGET_USER")
        else
            echo "ERRO: Incapaz de determinar usuário não-root para compilar yay. Abortando." >&2
             rm -rf "$TEMP_DIR" # Limpeza
            exit 1
        fi
    fi
    echo "Usuário alvo para compilação: $TARGET_USER"

    # --- CORREÇÃO: Ajusta permissão do diretório temporário principal ---
    echo "Ajustando permissões de $TEMP_DIR para $TARGET_USER:$TARGET_GROUP..."
    sudo chown "$TARGET_USER":"$TARGET_GROUP" "$TEMP_DIR"

    # Tenta clonar yay-bin primeiro (mais rápido), senão yay (compilado)
    # Executa o git clone como o usuário alvo para evitar problemas de permissão nos arquivos clonados
    if sudo -u "$TARGET_USER" git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$TEMP_DIR/yay-install"; then
        echo "Clonado yay-bin."
        INSTALL_DIR="$TEMP_DIR/yay-install"
    elif sudo -u "$TARGET_USER" git clone --depth=1 https://aur.archlinux.org/yay.git "$TEMP_DIR/yay-install"; then
        echo "Clonado yay (fonte)."
        INSTALL_DIR="$TEMP_DIR/yay-install"
    else
        echo "Erro ao clonar o repositório do yay." >&2
        # Limpeza é importante em caso de falha
        sudo rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Entra no diretório e compila/instala como o usuário alvo
    ( # Abre um subshell para o cd
      cd "$INSTALL_DIR"
      echo "Executando makepkg como usuário $TARGET_USER em $INSTALL_DIR..."
      # Executa makepkg como o usuário alvo. Já estamos no diretório correto.
      sudo -u "$TARGET_USER" makepkg -si --noconfirm
    ) # Fecha o subshell

    # Limpeza do diretório temporário após a instalação
    sudo rm -rf "$TEMP_DIR"

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
mapfile -t all_packages < <(cat "$PACMAN_PKGS_FILE" "$AUR_PKGS_FILE" 2>/dev/null | awk '!/^($|#)/{sub(/#.*/,""); print $1}' | sort -u)

# Instala TODOS os pacotes usando Yay
if [ ${#all_packages[@]} -gt 0 ]; then
    echo "Instalando/Atualizando todos os pacotes listados com Yay..."
    echo "Pacotes a serem gerenciados: ${all_packages[@]}"
    # Garante que yay use o usuário normal, não root diretamente
    if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
         echo "Executando yay como usuário $SUDO_USER..."
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