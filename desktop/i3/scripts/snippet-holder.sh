#!/bin/bash

# Configurações de Caminho
NOTES_DIR="/home/val/Documents/Notes/01 Snippets"
EDITOR_APP="${EDITOR_APP:-mousepad}"
DATE_FORMAT=$(date +%Y-%m-%d)

# Garante que o diretório base existe
mkdir -p "$NOTES_DIR"

copy_to_clipboard() {
    # Prioriza wl-copy para Wayland, xclip para X11 (EndeavourOS i3 usa X11 por padrão)
    if command -v xclip >/dev/null 2>&1; then
        xclip -selection clipboard
    elif command -v wl-copy >/dev/null 2>&1; then
        wl-copy
    fi
}

# Lista notas: "Pasta/Arquivo"
list_snippets() {
    local subdir="$1"
    find "$NOTES_DIR/$subdir" -maxdepth 2 -type f -name "*.md" | sed "s|$NOTES_DIR/||" | sed 's|^/||'
}

# Lista apenas diretórios (Grupos)
list_groups() {
    find "$NOTES_DIR" -maxdepth 1 -type d | sed "s|$NOTES_DIR||" | sed '/^$/d' | sed 's|^/||'
}

# Extrai apenas o conteúdo dentro do bloco de código ```
get_snippet_code() {
    local file="$NOTES_DIR/$1"
    # Captura o conteúdo entre o primeiro par de crases
    sed -n '/^```/,/^```/{ /^```/d; p }' "$file"
}

# Menu de Ações/Preview
show_actions() {
    local selection="$1"
    local code=$(get_snippet_code "$selection")
    
    local action=$(echo -e "Copiar\nEditar\nApagar" | rofi -dmenu -i \
        -p "Snippet: $(basename "$selection")" \
        -mesg "Conteúdo:\n$code")

    case "$action" in
        "Copiar") 
            echo -n "$code" | copy_to_clipboard
            notify-send "Snippet Holder" "Código copiado para o clipboard!" 
            ;;
        "Editar") 
            "$EDITOR_APP" "$NOTES_DIR/$selection" 
            ;;
        "Apagar") 
            confirm_delete "$selection" 
            ;;
    esac
}

new_snippet() {
    local name=$(rofi -dmenu -p "Nome da nota")
    [ -z "$name" ] && exit 0

    local groups=$(list_groups)
    local group_choice=$(echo -e "Raiz\nCriar Novo Grupo\n$groups" | rofi -dmenu -p "Grupo/Subpasta")
    
    local target_dir="$NOTES_DIR"
    if [ "$group_choice" == "Criar Novo Grupo" ]; then
        local new_group=$(rofi -dmenu -p "Nome da nova pasta")
        target_dir="$NOTES_DIR/$new_group"
    elif [ "$group_choice" != "Raiz" ]; then
        target_dir="$NOTES_DIR/$group_choice"
    fi

    mkdir -p "$target_dir"
    local file_path="$target_dir/${name}.md"

    # Template Obsidian
    cat > "$file_path" <<EOF
---
title: $name
tags:
  - clipped
dateCreated: "[[$DATE_FORMAT]]"
---

\`\`\`
$(xclip -o -selection clipboard 2>/dev/null || wl-paste 2>/dev/null)
\`\`\`
EOF
    "$EDITOR_APP" "$file_path"
}

confirm_delete() {
    local check=$(echo -e "Não\nSim" | rofi -dmenu -p "Apagar definitivamente '$1'?")
    if [ "$check" == "Sim" ]; then
        rm "$NOTES_DIR/$1"
        notify-send "Snippet Holder" "Arquivo removido."
    fi
}

filter_by_group() {
    local group=$(list_groups | rofi -dmenu -i -p "Filtrar Grupo")
    [ -z "$group" ] && exit 0
    
    local selection=$(list_snippets "$group" | rofi -dmenu -i -p "Snippets em $group")
    [ -n "$selection" ] && show_actions "$selection"
}

# Interface Principal
CHOICE=$(list_snippets "" | rofi -dmenu -i -p "Snippets" \
    -mesg "Alt+n: Novo | Alt+g: Grupos | Enter: Preview/Ações" \
    -kb-custom-1 "Alt+n" \
    -kb-custom-2 "Alt+g")

RET=$?

case "$RET" in
    10) new_snippet ;;
    11) filter_by_group ;;
    0) [ -n "$CHOICE" ] && show_actions "$CHOICE" ;;
esac