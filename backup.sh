#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${DOTFILES_DIR}/.backups/home_backup_${TIMESTAMP}"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

backup_file() {
    local src=$1
    local dest=$2
    
    if [ -e "$src" ]; then
        mkdir -p "$(dirname "$dest")"
        if [ -L "$src" ]; then
            cp -P "$src" "$dest"
            log "Backed up symlink: $src -> $dest"
        else
            cp -r "$src" "$dest"
            log "Backed up: $src -> $dest"
        fi
    else
        log "File not found: $src (skipping)"
    fi
}

backup_shell() {
    log "Backing up shell configurations..."
    for file in .bashrc .bash_aliases .bash_logout .profile; do
        backup_file "$HOME/$file" "${BACKUP_DIR}/shell/bash/$file"
    done
}

backup_desktop() {
    log "Backing up desktop configurations..."
    
    local configs=(
        ".config/i3:desktop/i3"
        ".config/i3blocks:desktop/i3blocks"
        ".config/kitty:desktop/kitty"
        ".config/rofi:desktop/rofi"
        ".config/gtk-3.0:desktop/gtk-3.0"
    )
    
    for config_map in "${configs[@]}"; do
        IFS=':' read -ra CONFIG <<< "$config_map"
        local src_dir="$HOME/${CONFIG[0]}"
        local dest_dir="${BACKUP_DIR}/${CONFIG[1]}"
        
        if [ -d "$src_dir" ]; then
            for item in "$src_dir"/*; do
                local item_name=$(basename "$item")
                backup_file "$item" "${dest_dir}/${item_name}"
            done
        fi
    done
    
    if [ -d "$HOME/.config/scripts" ]; then
        for item in "$HOME/.config/scripts"/*; do
            local item_name=$(basename "$item")
            backup_file "$item" "${BACKUP_DIR}/desktop/scripts/${item_name}"
        done
    fi
}

backup_apps() {
    log "Backing up application configurations..."
    
    backup_file "$HOME/.gitconfig" "${BACKUP_DIR}/apps/git/.gitconfig"
    
    local config_dirs="aichat fastfetch"
    for dir in $config_dirs; do
        if [ -d "$HOME/.config/$dir" ]; then
            for item in "$HOME/.config/$dir"/*; do
                local item_name=$(basename "$item")
                backup_file "$item" "${BACKUP_DIR}/apps/$dir/${item_name}"
            done
        fi
    done
    
    backup_file "$HOME/.config/gnome-shortcuts-export.json" "${BACKUP_DIR}/apps/gnome-shortcuts-export.json"
}

backup_bin() {
    log "Backing up user scripts..."
    
    if [ -d "$HOME/.local/bin" ]; then
        local user_scripts=(
            "gca"
            "transcribe"
            "transcribe-install.sh"
            "vconvert"
            "whisper"
        )
        
        for script in "${user_scripts[@]}"; do
            backup_file "$HOME/.local/bin/$script" "${BACKUP_DIR}/bin/$script"
        done
    fi
}

backup_all() {
    log "Starting full backup to $BACKUP_DIR..."
    backup_shell
    backup_desktop
    backup_apps
    backup_bin
    log "Backup completed! Files saved to: $BACKUP_DIR"
}

copy_to_repo() {
    local backup_source=$1
    local repo_target=$2
    
    if [ -d "$backup_source" ]; then
        mkdir -p "$repo_target"
        cp -r "$backup_source"/* "$repo_target"/
        log "Copied $backup_source to $repo_target"
    fi
}

restore_to_repo() {
    log "Restoring backup to repository..."
    
    copy_to_repo "${BACKUP_DIR}/shell" "${DOTFILES_DIR}/shell"
    copy_to_repo "${BACKUP_DIR}/desktop" "${DOTFILES_DIR}/desktop"
    copy_to_repo "${BACKUP_DIR}/apps" "${DOTFILES_DIR}/apps"
    copy_to_repo "${BACKUP_DIR}/bin" "${DOTFILES_DIR}/bin"
    
    log "Backup restored to repository structure!"
}

show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    all             Backup all configurations (default)
    shell           Backup shell configurations only
    desktop         Backup desktop configurations only
    apps            Backup application configurations only
    bin             Backup user scripts only
    restore         Restore the most recent backup to repository
    list            List all available backups
    help            Show this help message

Options:
    --no-timestamp  Use fixed backup directory name instead of timestamp

Examples:
    $0 all
    $0 shell
    $0 restore
    $0 list
EOF
}

NO_TIMESTAMP=false
COMPONENT=all

if [[ $# -eq 0 ]]; then
    COMPONENT=all
else
    while [[ $# -gt 0 ]]; do
        case $1 in
            all|shell|desktop|apps|bin|restore|list|help)
                COMPONENT=$1
                shift
                ;;
            --no-timestamp)
                NO_TIMESTAMP=true
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

if [[ $NO_TIMESTAMP == true ]]; then
    BACKUP_DIR="${DOTFILES_DIR}/.backups/home_backup"
fi

if [[ $COMPONENT == "help" ]]; then
    show_usage
    exit 0
fi

if [[ $COMPONENT == "list" ]]; then
    if [ -d "${DOTFILES_DIR}/.backups" ]; then
        log "Available backups:"
        ls -lht "${DOTFILES_DIR}/.backups/" | grep "^d" | awk '{print "  " $9, "("$6" "$7" "$8")"}'
    else
        log "No backups found in ${DOTFILES_DIR}/.backups/"
    fi
    exit 0
fi

if [[ $COMPONENT == "restore" ]]; then
    if [[ $NO_TIMESTAMP == true ]]; then
        restore_to_repo
    else
        LATEST_BACKUP=$(ls -1t "${DOTFILES_DIR}/.backups/" 2>/dev/null | head -1)
        if [ -z "$LATEST_BACKUP" ]; then
            log "No backups found!"
            exit 1
        fi
        BACKUP_DIR="${DOTFILES_DIR}/.backups/${LATEST_BACKUP}"
        restore_to_repo
    fi
    exit 0
fi

case $COMPONENT in
    all)    backup_all ;;
    shell)  backup_shell ;;
    desktop) backup_desktop ;;
    apps)   backup_apps ;;
    bin)    backup_bin ;;
esac
