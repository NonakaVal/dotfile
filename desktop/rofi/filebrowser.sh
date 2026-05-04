#!/bin/bash

DIR="${HOME}"
SHOW_HIDDEN=0
SORT_MODE="alpha"   # alpha | recent

list_entries() {
    local dir="$1"
    local show_hidden="$2"
    local sort_mode="$3"

    list_group() {
        local find_expr="$1"

        if [ "$sort_mode" = "recent" ]; then
            eval "find \"$dir\" -maxdepth 1 -mindepth 1 $find_expr -printf '%T@|%y|%f\n' 2>/dev/null" \
                | sort -t'|' -k1,1nr \
                | cut -d'|' -f2-
        else
            eval "find \"$dir\" -maxdepth 1 -mindepth 1 $find_expr -printf '%y|%f\n' 2>/dev/null" \
                | sort -t'|' -k2,2f
        fi
    }

    if [ "$show_hidden" -eq 1 ]; then
        list_group "-type d -name '.*'"
        list_group "-type d ! -name '.*'"
        list_group "-type f -name '.*'"
        list_group "-type f ! -name '.*'"
    else
        list_group "-type d ! -name '.*'"
        list_group "-type f ! -name '.*'"
    fi
}


format_entries() {
    while IFS='|' read -r type name; do
        if [ "$type" = "d" ]; then
            printf '📁 %s/\n' "$name"
        else
            printf '%s\n' "$name"
        fi
    done
}

while true; do
    prompt="$DIR"
    message="Alt+h ocultos: $( [ "$SHOW_HIDDEN" -eq 1 ] && echo on || echo off )   |   Alt+s ordem: $SORT_MODE   |   Alt+a alfabética   |   Alt+r recentes"

    entries=$(
        {
            echo "📁 ../"
            list_entries "$DIR" "$SHOW_HIDDEN" "$SORT_MODE" | format_entries
        }
    )

    CHOICE=$(printf '%s\n' "$entries" | rofi -dmenu -i \
        -p "$prompt" \
        -mesg "$message" \
        -kb-custom-1 "Alt+h" \
        -kb-custom-2 "Alt+s" \
        -kb-custom-3 "Alt+a" \
        -kb-custom-4 "Alt+r")

    RET=$?

    case "$RET" in
        1)
            exit
            ;;
        10)
            if [ "$SHOW_HIDDEN" -eq 1 ]; then
                SHOW_HIDDEN=0
            else
                SHOW_HIDDEN=1
            fi
            continue
            ;;
        11)
            if [ "$SORT_MODE" = "alpha" ]; then
                SORT_MODE="recent"
            else
                SORT_MODE="alpha"
            fi
            continue
            ;;
        12)
            SORT_MODE="alpha"
            continue
            ;;
        13)
            SORT_MODE="recent"
            continue
            ;;
    esac

    [ -z "$CHOICE" ] && exit

    if [ "$CHOICE" = "📁 ../" ]; then
        DIR="$(dirname "$DIR")"
        continue
    fi

    CLEAN_NAME="${CHOICE#📁 }"
    CLEAN_NAME="${CLEAN_NAME%/}"
    TARGET="$DIR/$CLEAN_NAME"

    if [ -d "$TARGET" ]; then
        DIR="$TARGET"
    elif [ -e "$TARGET" ]; then
        xdg-open "$TARGET" >/dev/null 2>&1 &
        exit
    fi
done
