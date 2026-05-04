#!/bin/bash

MODE="${1:-current}"
THEME="$HOME/.config/rofi/rofiwindow.rasi"

while true; do
    TREE=$(i3-msg -t get_tree)

    if [ "$MODE" = "current" ]; then
        CURRENT_WS=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')
        mapfile -t ROWS < <(echo "$TREE" | jq -r --arg ws "$CURRENT_WS" '
            recurse(.nodes[]?, .floating_nodes[]?)
            | select(.type == "workspace" and .name == $ws)
            | recurse(.nodes[]?, .floating_nodes[]?)
            | select(.window != null)
            | [ (.id | tostring), (.window_properties.class // "app" | ascii_downcase), (.name // "window") ]
            | @tsv
        ')
        NUM_COLS=1
        TOTAL_ROWS=${#ROWS[@]}
        [ "$TOTAL_ROWS" -eq 0 ] && ROWS=("-1\tempty\tNenhuma janela") && TOTAL_ROWS=1
        MSG="<b>Workspace Atual</b>"
    else
        WORKSPACES=$(echo "$TREE" | jq -c '
            [recurse(.nodes[]?, .floating_nodes[]?) | select(.type == "workspace" and .name != "__i3_scratch")]
            | map({
                name: .name,
                windows: [recurse(.nodes[]?, .floating_nodes[]?) | select(.window != null) | {id: .id, cls: (.window_properties.class // "app" | ascii_downcase), title: (.name // "window")}]
            })
            | map(select(.windows | length >= 0))
        ')

        NUM_COLS=$(echo "$WORKSPACES" | jq 'length')
        MAX_WINS=$(echo "$WORKSPACES" | jq '[.[].windows | length] | max // 0')
        TOTAL_ROWS=$((MAX_WINS + 1))

        mapfile -t ROWS < <(echo "$WORKSPACES" | jq -r --argjson max_wins "$MAX_WINS" '
            .[] | 
            ("-2\theader\t" + .name), 
            (.windows[] | (.id | tostring) + "\t" + .cls + "\t" + .title),
            (if (.windows | length) < $max_wins then range($max_wins - (.windows | length)) | "-1\tempty\t " else empty end)
        ')
        MSG=""
    fi

    INDEX=$(
        for row in "${ROWS[@]}"; do
            id=$(echo "$row" | cut -f1)
            cls=$(echo "$row" | cut -f2)
            title=$(echo "$row" | cut -f3-)

            if [ "$id" = "-2" ]; then
                label_clean=$(echo "$title" | sed 's/^[0-9]\+://')
                printf '<b>%s</b>\0nonselectable\x1ftrue\n' "$label_clean"
            elif [ "$id" = "-1" ]; then
                printf ' \0nonselectable\x1ftrue\n'
            else
                short_title="${title:0:40}"
                [ "${#title}" -gt 20 ] && short_title="${short_title}..."
                printf '%s\0icon\x1f%s\n' "$short_title" "$cls"
            fi
        done | rofi -dmenu -i -p "" -mesg "$MSG" -theme "$THEME" \
            -theme-str "listview { columns: ${NUM_COLS:-1}; lines: ${TOTAL_ROWS:-1}; fixed-height: true; }" \
            -show-icons -kb-custom-1 "Alt+g" -markup-rows -format i
    )

    RET=$?
    case "$RET" in
        1) exit 0 ;;
        10) [ "$MODE" = "all" ] && MODE="current" || MODE="all" ;;
        0)
            [ -z "$INDEX" ] && exit 0
            # VALIDAÇÃO CRÍTICA:
            CHOSEN="${ROWS[$INDEX]}"
            ID=$(echo "$CHOSEN" | cut -f1)
            
            # Se o ID for -1 ou -2, o usuário clicou em um header/espaço vazio
            # Ignoramos e continuamos o loop para não fechar o Rofi erroneamente
            if [[ "$ID" =~ ^[0-9]+$ ]] && [ "$ID" -gt 0 ]; then
                i3-msg "[con_id=$ID] focus" >/dev/null
                exit 0
            fi
            ;;
    esac
done
