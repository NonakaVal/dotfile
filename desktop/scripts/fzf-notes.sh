#!/bin/bash

BASE="/home/i3t/Documentos/Notes"
SORT="${SORT:-alpha}"   # alpha | recent

list_files() {
    if [ "$SORT" = "recent" ]; then
        find "$BASE" \
            \( -path "*/.git" -o -path "*/node_modules" -o -path "*/__pycache__" -o -path "*/venv" -o -path "*/.venv" -o -path "*/.obsidian/cache" -o -path "*/.cache" -o -path "*/cache" -o -path "*/dist" -o -path "*/build" \) -prune -o \
            -type f \
            \( -iname "*.md" -o -iname "*.txt" -o -iname "*.html" -o -iname "*.htm" -o -iname "*.py" -o -iname "*.js" -o -iname "*.ts" -o -iname "*.json" -o -iname "*.css" -o -iname "*.scss" -o -iname "*.sh" -o -iname "*.yaml" -o -iname "*.yml" -o -iname "*.toml" -o -iname "*.ini" -o -iname "*.conf" -o -iname "*.csv" -o -iname "*.xml" \) \
            -printf "%T@|%f|%p\n" 2>/dev/null \
        | sort -t'|' -k1,1nr \
        | cut -d'|' -f2,3 \
        | awk -F'|' '{print $1 "\t" $2}'
    else
        find "$BASE" \
            \( -path "*/.git" -o -path "*/node_modules" -o -path "*/__pycache__" -o -path "*/venv" -o -path "*/.venv" -o -path "*/.obsidian/cache" -o -path "*/.cache" -o -path "*/cache" -o -path "*/dist" -o -path "*/build" \) -prune -o \
            -type f \
            \( -iname "*.md" -o -iname "*.txt" -o -iname "*.html" -o -iname "*.htm" -o -iname "*.py" -o -iname "*.js" -o -iname "*.ts" -o -iname "*.json" -o -iname "*.css" -o -iname "*.scss" -o -iname "*.sh" -o -iname "*.yaml" -o -iname "*.yml" -o -iname "*.toml" -o -iname "*.ini" -o -iname "*.conf" -o -iname "*.csv" -o -iname "*.xml" \) \
            -printf "%f\t%p\n" 2>/dev/null \
        | sort -f
    fi
}

preview_file() {
    local file="$1"

    [ -z "$file" ] && exit 0
    [ ! -e "$file" ] && { echo "Arquivo não encontrado"; exit 0; }

    echo "Arquivo: $file"
    echo "------------------------------------------------------------"
    file "$file" 2>/dev/null
    echo "------------------------------------------------------------"
    echo

    case "$file" in
        *.md)
            if command -v glow >/dev/null 2>&1; then
                glow -s dark "$file" 2>/dev/null || bat --style=numbers --color=always --line-range=:300 "$file" 2>/dev/null || sed -n '1,300p' "$file"
            elif command -v bat >/dev/null 2>&1; then
                bat --style=numbers --color=always --line-range=:300 "$file" 2>/dev/null || sed -n '1,300p' "$file"
            else
                sed -n '1,300p' "$file"
            fi
            ;;
        *)
            if command -v bat >/dev/null 2>&1; then
                bat --style=numbers --color=always --line-range=:300 "$file" 2>/dev/null || sed -n '1,300p' "$file"
            else
                sed -n '1,300p' "$file"
            fi
            ;;
    esac
}

if [ "${1:-}" = "__preview__" ]; then
    shift
    preview_file "$1"
    exit 0
fi

if [ "${1:-}" = "__list__" ]; then
    list_files
    exit 0
fi

while true; do
    HEADER="notes | ordem: $SORT | Alt+s alterna ordem"

    SELECTED=$(
        list_files | fzf \
            --prompt="notes > " \
            --header="$HEADER" \
            --delimiter=$'\t' \
            --with-nth=1 \
            --preview="$0 __preview__ {2}" \
            --preview-window=right:65%:wrap \
            --bind "alt-s:reload(SORT=$( [ "$SORT" = "alpha" ] && echo recent || echo alpha ) $0 __list__)"
    )

    [ -z "$SELECTED" ] && exit

    FILE=$(printf '%s\n' "$SELECTED" | cut -f2)

    [ -z "$FILE" ] && exit

    xdg-open "$FILE" >/dev/null 2>&1 &
    exit
done
