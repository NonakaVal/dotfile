#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }
info() { echo -e "${BLUE}[*]${NC} $*"; }
header() { echo -e "\n${BOLD}${CYAN}==== $* ====${NC}\n"; }

check_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Execute como root ou com sudo"
        exit 1
    fi
}

is_installed() {
    dpkg -l "$1" &>/dev/null
}

read_list() {
    local file="$1"
    grep -vE '^\s*#|^\s*$' "$file" 2>/dev/null || true
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local choices="[y/N]"
    [[ "$default" == "y" ]] && choices="[Y/n]"
    read -rp "$(echo -e "${YELLOW}${prompt} ${choices}? ${NC}")" answer
    answer="${answer:-$default}"
    [[ "${answer,,}" == "y" || "${answer,,}" == "yes" ]]
}

step_system_update() {
    header "Atualizando sistema"
    apt update && apt upgrade -y
    apt dist-upgrade -y
    apt autoremove -y
    log "Sistema atualizado"
}

step_nvidia() {
    header "Driver NVIDIA (GTX 1660 SUPER)"
    if is_installed nvidia-driver; then
        info "NVIDIA driver ja instalado"
        nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || true
        return
    fi

    log "Instalando driver NVIDIA + firmware..."
    apt install -y \
        nvidia-driver \
        nvidia-detect \
        nvidia-settings \
        nvidia-persistenced \
        nvidia-kernel-dkms \
        firmware-misc-nonfree

    log "Adicionando usuario ao grupo video/render..."
    usermod -aG video,render "${SUDO_USER:-$USER}"
    warn "Reboot necessario para ativar o driver NVIDIA"
}

step_apt_core() {
    header "Pacotes APT essenciais"

    local core_pkgs=(
        build-essential git curl wget flatpak
        software-properties-common apt-transport-https
        ca-certificates gnupg lsb-release dirmngr
        bash-completion fzf bat ripgrep fd-find
        less tree htop
        pkg-config libssl-dev libffi-dev zlib1g-dev
        libbz2-dev libreadline-dev libsqlite3-dev liblzma-dev
        cmake make
        dconf-cli fastfetch ffmpeg
    )

    local to_install=()
    for pkg in "${core_pkgs[@]}"; do
        is_installed "$pkg" || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        info "Todos os pacotes core ja estao instalados"
        return
    fi

    log "Instalando ${#to_install[@]} pacotes: ${to_install[*]}"
    apt install -y "${to_install[@]}"

    ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
    ln -sf /usr/bin/fdfind /usr/local/bin/fd 2>/dev/null || true
}

step_flathub() {
    header "Configurando Flathub"
    if flatpak remote-list | grep -q flathub; then
        info "Flathub ja configurado"
        return
    fi
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    log "Flathub adicionado"
}

step_flatpaks() {
    header "Flatpaks"
    local list_file="$SCRIPT_DIR/packages-flatpak.list"
    [[ ! -f "$list_file" ]] && { warn "Arquivo $list_file nao encontrado"; return; }

    local apps=()
    while IFS='|' read -r app_id desc; do
        [[ -z "$app_id" ]] && continue
        if flatpak list --app | grep -q "$app_id"; then
            info "  [OK] $desc ($app_id)"
        else
            apps+=("$app_id|$desc")
        fi
    done < <(read_list "$list_file")

    if [[ ${#apps[@]} -eq 0 ]]; then
        info "Todos os flatpaks ja estao instalados"
        return
    fi

    echo ""
    log "Flatpaks disponiveis para instalar:"
    for entry in "${apps[@]}"; do
        IFS='|' read -r aid adesc <<< "$entry"
        echo -e "  ${CYAN}$aid${NC} - $adesc"
    done
    echo ""

    if confirm "Instalar todos os flatpaks listados" "y"; then
        for entry in "${apps[@]}"; do
            IFS='|' read -r aid adesc <<< "$entry"
            log "Instalando $adesc ($aid)..."
            flatpak install -y flathub "$aid" 2>/dev/null || warn "Falha ao instalar $aid"
        done
    else
        for entry in "${apps[@]}"; do
            IFS='|' read -r aid adesc <<< "$entry"
            if confirm "  Instalar $adesc ($aid)"; then
                flatpak install -y flathub "$aid" 2>/dev/null || warn "Falha ao instalar $aid"
            fi
        done
    fi
}

step_gnome() {
    header "GNOME Desktop"
    local pkgs=(
        gnome-tweaks
        gnome-shell-extensions
        gnome-shell-extension-manager
    )
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        is_installed "$pkg" || to_install+=("$pkg")
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        apt install -y "${to_install[@]}"
    fi
    log "GNOME tools instalados"
}

step_i3() {
    header "i3 Window Manager (alternativa)"
    if confirm "Instalar i3 + i3blocks + rofi + kitty"; then
        apt install -y i3-wm i3blocks rofi kitty
        log "i3 instalado"
    fi
}

step_node() {
    header "Node.js via nvm"
    local user_home="${SUDO_USER_HOME:-$HOME}"
    local nvm_dir="$user_home/.nvm"

    if [[ -d "$nvm_dir" ]]; then
        info "nvm ja instalado"
        return
    fi

    log "Instalando nvm..."
    local nvm_script
    nvm_script=$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh)
    if [[ -n "$nvm_script" ]]; then
        su - "${SUDO_USER:-$USER}" -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash"
        log "nvm instalado. Execute 'nvm install --lts' como usuario"
    fi
}

step_cargo() {
    header "Rust / Cargo"
    local user_home="${SUDO_USER_HOME:-$HOME}"

    if command -v cargo &>/dev/null; then
        info "Cargo ja instalado: $(cargo --version)"
    else
        if confirm "Instalar Rust via rustup"; then
            su - "${SUDO_USER:-$USER}" -c "curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y"
            source "$user_home/.cargo/env"
        else
            return
        fi
    fi

    local list_file="$SCRIPT_DIR/packages-cargo.list"
    [[ ! -f "$list_file" ]] && return

    log "Instalando ferramentas cargo..."
    while read -r pkg; do
        [[ -z "$pkg" ]] && continue
        if command -v "$pkg" &>/dev/null; then
            info "  [OK] $pkg"
        else
            log "  Instalando $pkg..."
            su - "${SUDO_USER:-$USER}" -c "source '$user_home/.cargo/env' && cargo install $pkg"
        fi
    done < <(read_list "$list_file")
}

step_docker() {
    header "Docker"
    if command -v docker &>/dev/null; then
        info "Docker ja instalado: $(docker --version)"
    else
        apt install -y docker.io containerd docker-buildx
        systemctl enable docker
        systemctl start docker
        usermod -aG docker "${SUDO_USER:-$USER}"
        log "Docker instalado e adicionado ao grupo"
    fi
}

step_pip() {
    header "Python pip (essencial)"
    local user_home="${SUDO_USER_HOME:-$HOME}"
    local list_file="$SCRIPT_DIR/packages-pip.list"
    [[ ! -f "$list_file" ]] && return

    apt install -y python3-pip python3-venv

    log "Instalando pacotes pip..."
    while read -r pkg; do
        [[ -z "$pkg" ]] && continue
        su - "${SUDO_USER:-$USER}" -c "pip install --user $pkg" || warn "Falha ao instalar $pkg via pip"
    done < <(read_list "$list_file")
}

step_npm_global() {
    header "npm global"
    local user_home="${SUDO_USER_HOME:-$HOME}"
    local list_file="$SCRIPT_DIR/packages-npm.list"
    [[ ! -f "$list_file" ]] && return

    local nvm_sh="$user_home/.nvm/nvm.sh"
    if [[ -f "$nvm_sh" ]]; then
        su - "${SUDO_USER:-$USER}" -c "source '$nvm_sh' && npm install -g $(paste -sd ' ' '$list_file' | grep -v '#') " 2>/dev/null || true
        while read -r pkg; do
            [[ -z "$pkg" ]] && continue
            if command -v "$pkg" &>/dev/null; then
                info "  [OK] $pkg"
            else
                log "  Instalando $pkg via npm..."
                su - "${SUDO_USER:-$USER}" -c "source '$nvm_sh' && npm install -g $pkg"
            fi
        done < <(read_list "$list_file")
    else
        warn "nvm nao encontrado. Instale Node.js primeiro"
    fi
}

step_dotfiles() {
    header "Dotfiles (symlinks)"
    if [[ -f "$DOTFILES_DIR/install.sh" ]]; then
        su - "${SUDO_USER:-$USER}" -c "cd '$DOTFILES_DIR' && bash install.sh all"
        log "Dotfiles instalados via install.sh"
    else
        warn "install.sh nao encontrado em $DOTFILES_DIR"
    fi
}

show_menu() {
    echo -e "${BOLD}${CYAN}"
    cat << 'BANNER'
  ╔═══════════════════════════════════════════╗
  ║   Debian Post-Install Provisioning       ║
  ║   dotfile/scripts/provision.sh           ║
  ╚═══════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
    echo -e "Selecione as etapas para executar:"
    echo ""
    echo -e "  ${GREEN}1${NC}) system-update    Atualizar sistema (apt update+upgrade)"
    echo -e "  ${GREEN}2${NC}) nvidia           Driver NVIDIA (GTX 1660 SUPER)"
    echo -e "  ${GREEN}3${NC}) apt-core         Pacotes APT essenciais"
    echo -e "  ${GREEN}4${NC}) flathub          Configurar Flathub"
    echo -e "  ${GREEN}5${NC}) flatpaks         Instalar Flatpaks (selecionavel)"
    echo -e "  ${GREEN}6${NC}) gnome            GNOME tweaks + extensões"
    echo -e "  ${GREEN}7${NC}) i3               i3 wm (alternativa)"
    echo -e "  ${GREEN}8${NC}) node             Node.js via nvm"
    echo -e "  ${GREEN}9${NC}) cargo            Rust + ferramentas (aichat, basalt)"
    echo -e "  ${GREEN}A${NC}) docker           Docker"
    echo -e "  ${GREEN}B${NC}) pip              Python pip essencial (whisper)"
    echo -e "  ${GREEN}C${NC}) npm-global       npm pacotes globais (opencode)"
    echo -e "  ${GREEN}D${NC}) dotfiles         Symlinks dos dotfiles"
    echo ""
    echo -e "  ${YELLOW}all${NC})  Executar tudo"
    echo -e "  ${YELLOW}essential${NC})  Executar: update + nvidia + apt-core + flathub + gnome + dotfiles"
    echo -e "  ${RED}q${NC})   Sair"
    echo ""
}

run_interactive() {
    show_menu
    read -rp "$(echo -e "${BOLD}Opcoes (ex: 1 2 3 5 8 D): ${NC}")" choices

    local steps=()
    for choice in $choices; do
        case "${choice,,}" in
            1) steps+=(system_update) ;;
            2) steps+=(nvidia) ;;
            3) steps+=(apt_core) ;;
            4) steps+=(flathub) ;;
            5) steps+=(flatpaks) ;;
            6) steps+=(gnome) ;;
            7) steps+=(i3) ;;
            8) steps+=(node) ;;
            9) steps+=(cargo) ;;
            a) steps+=(docker) ;;
            b) steps+=(pip) ;;
            c) steps+=(npm_global) ;;
            d) steps+=(dotfiles) ;;
            all)
                steps=(system_update nvidia apt_core flathub flatpaks gnome i3 node cargo docker pip npm_global dotfiles)
                break
                ;;
            essential)
                steps=(system_update nvidia apt_core flathub gnome dotfiles)
                break
                ;;
            q) exit 0 ;;
            *) warn "Opcao desconhecida: $choice" ;;
        esac
    done

    if [[ ${#steps[@]} -eq 0 ]]; then
        err "Nenhuma opcao selecionada"
        exit 1
    fi

    echo ""
    log "Etapas selecionadas: ${steps[*]}"
    echo ""

    for step in "${steps[@]}"; do
        case "$step" in
            system_update) step_system_update ;;
            nvidia)        step_nvidia ;;
            apt_core)      step_apt_core ;;
            flathub)       step_flathub ;;
            flatpaks)      step_flatpaks ;;
            gnome)         step_gnome ;;
            i3)            step_i3 ;;
            node)          step_node ;;
            cargo)         step_cargo ;;
            docker)        step_docker ;;
            pip)           step_pip ;;
            npm_global)    step_npm_global ;;
            dotfiles)      step_dotfiles ;;
        esac
    done

    header "Provisioning concluido"
    echo -e "  ${GREEN}Proximos passos:${NC}"
    echo -e "  1. Reboot se instalou driver NVIDIA"
    echo -e "  2. Logar e rodar: source ~/.bashrc"
    echo -e "  3. Instalar Node LTS: nvm install --lts"
    echo ""
}

run_noninteractive() {
    local target="${1:-essential}"
    local steps=()

    case "$target" in
        all)
            steps=(system_update nvidia apt_core flathub flatpaks gnome i3 node cargo docker pip npm_global dotfiles)
            ;;
        essential)
            steps=(system_update nvidia apt_core flathub gnome dotfiles)
            ;;
        *)
            warn "Modo desconhecido: $target"
            echo "Uso: $0 [all|essential]"
            echo "     $0 (modo interativo)"
            exit 1
            ;;
    esac

    for step in "${steps[@]}"; do
        case "$step" in
            system_update) step_system_update ;;
            nvidia)        step_nvidia ;;
            apt_core)      step_apt_core ;;
            flathub)       step_flathub ;;
            flatpaks)      step_flatpaks ;;
            gnome)         step_gnome ;;
            i3)            step_i3 ;;
            node)          step_node ;;
            cargo)         step_cargo ;;
            docker)        step_docker ;;
            pip)           step_pip ;;
            npm_global)    step_npm_global ;;
            dotfiles)      step_dotfiles ;;
        esac
    done
}

if [[ $# -eq 0 ]]; then
    check_root
    run_interactive
else
    check_root
    run_noninteractive "$1"
fi
