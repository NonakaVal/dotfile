#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${DOTFILES_DIR}/.backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${DOTFILES_DIR}/install.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

create_backup() {
    local file=$1
    if [ -e "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="${BACKUP_DIR}/${file}.${TIMESTAMP}"
        mkdir -p "$(dirname "$backup_path")"
        cp -r "$HOME/$file" "$backup_path"
        log "Backed up $file to $backup_path"
    fi
}

create_symlink() {
    local src=$1
    local dest=$2
    local dest_dir=$(dirname "$dest")
    
    mkdir -p "$dest_dir"
    
    if [ -L "$dest" ]; then
        rm "$dest"
    fi
    
    ln -sf "$src" "$dest"
    log "Created symlink: $dest -> $src"
}

install_shell() {
    log "Installing shell configurations..."
    for file in .bashrc .bash_aliases .bash_logout .profile; do
        create_backup "$file"
        create_symlink "${DOTFILES_DIR}/shell/bash/$file" "$HOME/$file"
    done
}

install_desktop() {
    log "Installing desktop configurations..."
    
    local dirs=(
        ".config/i3:.config/i3"
        ".config/i3blocks:.config/i3blocks"
        ".config/kitty:.config/kitty"
        ".config/rofi:.config/rofi"
        ".config/gtk-3.0:.config/gtk-3.0"
    )
    
    for dir_map in "${dirs[@]}"; do
        IFS=':' read -ra DIRS <<< "$dir_map"
        local src_dir="${DOTFILES_DIR}/${DIRS[0]}"
        local dest_dir="$HOME/${DIRS[1]}"
        
        for item in "$src_dir"/*; do
            local item_name=$(basename "$item")
            local dest_path="${dest_dir}/${item_name}"
            create_backup ".config/${item_name}"
            create_symlink "$item" "$dest_path"
        done
    done
}

install_apps() {
    log "Installing application configurations..."
    
    create_backup ".gitconfig"
    create_symlink "${DOTFILES_DIR}/apps/git/.gitconfig" "$HOME/.gitconfig"
    
    local config_dirs="aichat fastfetch"
    for dir in $config_dirs; do
        if [ -d "${DOTFILES_DIR}/apps/$dir" ]; then
            create_backup ".config/$dir"
            for item in "${DOTFILES_DIR}/apps/$dir"/*; do
                local item_name=$(basename "$item")
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
    log "Installing user scripts..."
    
    mkdir -p "$HOME/.local/bin"
    
    for script in "${DOTFILES_DIR}/bin"/*; do
        local script_name=$(basename "$script")
        create_backup ".local/bin/$script_name"
        create_symlink "$script" "$HOME/.local/bin/$script_name"
        chmod +x "$HOME/.local/bin/$script_name"
    done
    
    if ! grep -q "$HOME/.local/bin" "$HOME/.bashrc" 2>/dev/null; then
        echo "" >> "$HOME/.bashrc"
        echo "# Add .local/bin to PATH if not already present" >> "$HOME/.bashrc"
        echo "if [[ -d \"$HOME/.local/bin\" ]]; then" >> "$HOME/.bashrc"
        echo "    export PATH=\"$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo "fi" >> "$HOME/.bashrc"
        log "Added .local/bin to PATH"
    fi
}

install_all() {
    log "Starting full installation..."
    install_shell
    install_desktop
    install_apps
    install_bin
    log "Installation completed!"
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    all             Install all configurations (default)
    shell           Install shell configurations only
    desktop         Install desktop configurations only
    apps            Install application configurations only
    bin             Install user scripts only
    help            Show this help message

Options:
    --no-backup     Skip backing up existing files
    --dry-run       Show what would be installed without making changes

Examples:
    $0 all
    $0 shell --no-backup
    $0 desktop --dry-run
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
            all|shell|desktop|apps|bin|help)
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
    log "DRY RUN MODE - No changes will be made"
    DRY_RUN_PREFIX="echo "
else
    DRY_RUN_PREFIX=""
fi

if [[ $NO_BACKUP == true ]]; then
    log "Skipping backups (--no-backup specified)"
    create_backup() { :; }
fi

case $COMPONENT in
    all)    install_all ;;
    shell)  install_shell ;;
    desktop) install_desktop ;;
    apps)   install_apps ;;
    bin)    install_bin ;;
esac
