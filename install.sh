#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${DOTFILES_DIR}/.backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${DOTFILES_DIR}/install.log"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

create_backup() {
    local file=$1
    if [ -e "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="${BACKUP_DIR}/${file}.${TIMESTAMP}"
        mkdir -p "$(dirname "$backup_path")"
        cp -r "$HOME/$file" "$backup_path"
        log "Backup: $file -> $backup_path"
    fi
}

create_symlink() {
    local src=$1
    local dest=$2
    local dest_dir=$(dirname "$dest")

    mkdir -p "$dest_dir"

    if [ -L "$dest" ]; then
        local current_target
        current_target=$(readlink -f "$dest")
        local src_resolved
        src_resolved=$(readlink -f "$src" 2>/dev/null || echo "$src")
        if [[ "$current_target" == "$src_resolved" ]]; then
            return
        fi
        rm "$dest"
    fi

    ln -sf "$src" "$dest"
    log "Symlink: $dest -> $src"
}

install_shell() {
    log "Shell configurations..."
    for file in .bashrc .bash_aliases .bash_logout .profile; do
        local src="${DOTFILES_DIR}/shell/bash/$file"
        if [[ -f "$src" ]]; then
            create_backup "$file"
            create_symlink "$src" "$HOME/$file"
        fi
    done
}

install_desktop_gnome() {
    log "GNOME desktop configurations..."

    if command -v dconf &>/dev/null; then
        local gnome_dir="${DOTFILES_DIR}/desktop/gnome"
        mkdir -p "$gnome_dir"

        if [[ -f "$gnome_dir/dconf-settings.ini" ]]; then
            dconf load / < "$gnome_dir/dconf-settings.ini" 2>/dev/null && log "dconf settings restauradas"
        fi

        if [[ -f "$gnome_dir/extensions.list" ]]; then
            while read -r ext; do
                [[ -z "$ext" || "$ext" == \#* ]] && continue
                gnome-extensions enable "$ext" 2>/dev/null || true
            done < "$gnome_dir/extensions.list"
            log "GNOME extensions ativadas"
        fi
    fi
}

install_desktop_i3() {
    log "i3 / desktop configurations..."

    local dirs=(
        "desktop/i3:.config/i3"
        "desktop/i3blocks:.config/i3blocks"
        "desktop/kitty:.config/kitty"
        "desktop/rofi:.config/rofi"
        "desktop/gtk-3.0:.config/gtk-3.0"
    )

    for dir_map in "${dirs[@]}"; do
        IFS=':' read -ra DIRS <<< "$dir_map"
        local src_dir="${DOTFILES_DIR}/${DIRS[0]}"
        local dest_dir="$HOME/${DIRS[1]}"

        [[ ! -d "$src_dir" ]] && continue

        for item in "$src_dir"/*; do
            [[ ! -e "$item" ]] && continue
            local item_name
            item_name=$(basename "$item")
            local dest_path="${dest_dir}/${item_name}"
            create_backup ".config/${DIRS[1]#*/}/${item_name}"
            create_symlink "$item" "$dest_path"
        done
    done
}

install_desktop() {
    install_desktop_gnome
    install_desktop_i3
}

install_apps() {
    log "Application configurations..."

    create_backup ".gitconfig"
    create_symlink "${DOTFILES_DIR}/apps/git/.gitconfig" "$HOME/.gitconfig"

    local config_dirs="aichat fastfetch"
    for dir in $config_dirs; do
        if [ -d "${DOTFILES_DIR}/apps/$dir" ]; then
            for item in "${DOTFILES_DIR}/apps/$dir"/*; do
                [[ ! -e "$item" ]] && continue
                local item_name
                item_name=$(basename "$item")
                create_backup ".config/$dir/$item_name"
                create_symlink "$item" "$HOME/.config/$dir/$item_name"
            done
        fi
    done

    if [ -f "${DOTFILES_DIR}/apps/gnome-shortcuts-export.json" ]; then
        create_backup ".config/gnome-shortcuts-export.json"
        create_symlink "${DOTFILES_DIR}/apps/gnome-shortcuts-export.json" "$HOME/.config/gnome-shortcuts-export.json"
    fi
}

install_bin() {
    log "User scripts..."

    mkdir -p "$HOME/.local/bin"

    for script in "${DOTFILES_DIR}/bin"/*; do
        [[ ! -e "$script" ]] && continue
        local script_name
        script_name=$(basename "$script")
        create_backup ".local/bin/$script_name"
        create_symlink "$script" "$HOME/.local/bin/$script_name"
    done
}

install_opencode_config() {
    log "opencode config (~/.config/opencode/)..."
    local src="${DOTFILES_DIR}/apps/opencode-config"
    local dest="$HOME/.config/opencode"

    if [ -d "$src" ]; then
        create_backup ".config/opencode"
        if [ -L "$dest" ]; then
            rm "$dest"
        elif [ -d "$dest" ]; then
            rm -rf "$dest"
        fi
        create_symlink "$src" "$dest"
    fi
}

install_opencode() {
    log "opencode data (~/.opencode/)..."
    local src="${DOTFILES_DIR}/apps/opencode"
    local dest="$HOME/.opencode"

    if [ -d "$src" ]; then
        create_backup ".opencode"
        if [ -L "$dest" ]; then
            rm "$dest"
        elif [ -d "$dest" ]; then
            rm -rf "$dest"
        fi
        create_symlink "$src" "$dest"
    fi
}

install_agents() {
    log "agents (~/.agents/)..."
    local src="${DOTFILES_DIR}/apps/agents"
    local dest="$HOME/.agents"

    if [ -d "$src" ]; then
        create_backup ".agents"
        if [ -L "$dest" ]; then
            rm "$dest"
        elif [ -d "$dest" ]; then
            rm -rf "$dest"
        fi
        create_symlink "$src" "$dest"
    fi
}

save_gnome_state() {
    log "Salvando estado atual do GNOME..."
    local gnome_dir="${DOTFILES_DIR}/desktop/gnome"
    mkdir -p "$gnome_dir"

    if command -v dconf &>/dev/null; then
        dconf dump / > "$gnome_dir/dconf-settings.ini"
        log "dconf settings salvas em $gnome_dir/dconf-settings.ini"
    fi

    if command -v gnome-extensions &>/dev/null; then
        gnome-extensions list --enabled 2>/dev/null > "$gnome_dir/extensions.list"
        log "Extensions salvas em $gnome_dir/extensions.list"
    fi
}

install_all() {
    log "Instalacao completa..."
    install_shell
    install_desktop
    install_apps
    install_opencode_config
    install_opencode
    install_agents
    install_bin
    log "Concluido! Use 'source ~/.bashrc' para recarregar."
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    all             Instalar tudo (default)
    shell           Shell configs (.bashrc, .bash_aliases, .profile)
    desktop         Desktop configs (GNOME + i3/kitty/rofi)
    gnome           GNOME configs apenas (dconf + extensions)
    apps            Application configs (git, aichat, fastfetch)
    opencode-config opencode config (~/.config/opencode)
    opencode        opencode data (~/.opencode)
    agents          agents (~/.agents)
    bin             User scripts (~/.local/bin)
    save-gnome      Salvar estado atual do GNOME no repo
    help            Show this help

Options:
    --no-backup     Skip backup of existing files
    --dry-run       Preview sem fazer mudancas

Examples:
    $0 all
    $0 shell --no-backup
    $0 desktop --dry-run
    $0 save-gnome
EOF
}

DRY_RUN=false
NO_BACKUP=false
COMPONENT=all

if [[ $# -eq 0 ]]; then
    COMPONENT=all
else
    while [[ $# -gt 0 ]]; do
        case $1 in
            all|shell|desktop|gnome|apps|opencode-config|opencode|agents|bin|save-gnome|help)
                COMPONENT=$1
                shift
                ;;
            --no-backup)
                NO_BACKUP=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
fi

if [[ $COMPONENT == "help" ]]; then
    show_usage
    exit 0
fi

if [[ $DRY_RUN == true ]]; then
    log "DRY RUN - nenhuma mudanca sera feita"
    create_symlink() { log "[dry] symlink: $2 -> $1"; }
    create_backup() { log "[dry] backup: $1"; }
fi

if [[ $NO_BACKUP == true ]]; then
    log "Skipping backups (--no-backup)"
    create_backup() { :; }
fi

case $COMPONENT in
    all)            install_all ;;
    shell)          install_shell ;;
    desktop)        install_desktop ;;
    gnome)          install_desktop_gnome ;;
    apps)           install_apps ;;
    opencode-config) install_opencode_config ;;
    opencode)       install_opencode ;;
    agents)         install_agents ;;
    bin)            install_bin ;;
    save-gnome)     save_gnome_state ;;
esac
