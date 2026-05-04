# ~/.bashrc: executed by bash for interactive shells

case $- in
    *i*) ;;
    *) return ;;
esac

HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

shopt -s histappend
shopt -s checkwinsize

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot="$(cat /etc/debian_chroot)"
fi

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/gems/bin:$PATH"
export GEM_HOME="$HOME/gems"

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

if command -v fastfetch >/dev/null 2>&1; then
    ~/.config/fastfetch/run-random.sh 2>/dev/null || fastfetch
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes ;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null 2>&1; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
    xterm*|rxvt*|alacritty*|konsole*)
        PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
        ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias cls='clear'

if command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

_ai_core() {
    local role="$1"; shift
    local prompt="$*"
    local dir="$HOME/Documentos/Notes/+/_output"
    local file="$dir/$(date +%Y-%m-%d_%H-%M-%S)_${role}.md"

    mkdir -p "$dir"
    set +m

    (
        while true; do
            for c in '|' '/' '-' '\'; do
                printf "\r%s pensando..." "$c"
                sleep 0.1
            done
        done
    ) &

    local pid=$!
    local output
    output=$(aichat --role "$role" "$prompt" 2>/dev/null)

    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    set -m

    printf "\r\033[K"
    echo "$output" | tee "$file" | glow -
    echo -e "\n💾 salvo em: $file"
}

aif() {
    _ai_core "falido" "$@"
}


airead() {
    # 📂 Diretório dos logs
    local dir="$HOME/Documentos/Notes/+/_output"
    local selected file

    # 🔍 Seleção de arquivo com fzf (sem preview lateral)
    selected=$(
        find "$dir" -maxdepth 1 -type f -name "*.md" | sort -r | while read -r file; do
            
            # 🧩 Parse do nome do arquivo
            base=$(basename "$file")
            date_part=$(echo "$base" | cut -d_ -f1)
            time_part=$(echo "$base" | cut -d_ -f2 | tr '-' ':')
            name_part=$(echo "$base" | cut -d_ -f3- | sed 's/\.md$//')

            # 🧾 Formato exibido no fzf
            printf "%s | %s | %s\t%s\n" "$date_part" "$time_part" "$name_part" "$file"

        done | fzf \
            --delimiter='\t' \
            --with-nth=1 \
            --prompt='📖 read > ' \
            --height=80% \
            --layout=reverse \
            --border
    )

    # 📄 Extrai caminho real do arquivo
    file=$(printf '%s' "$selected" | cut -f2)

    # 📖 Leitura limpa (sem UI lateral)
    if [ -n "$file" ]; then
        clear
        glow "$file"
    fi
}
mestrepow() {
    _ai_core "mestrepo" "$@"
}


aihelp() {
    local dir="$HOME/Documentos/Notes/+/_output"
    _ai_core "help" "$@"

    tail -n +1 "$(ls -t "$dir"/*_help.md 2>/dev/null | head -1)" \
        | sed '/<think>/,/<\/think>/d; s/```[a-z]*//g; s/```//g; /^$/d' \
        | wl-copy

    echo "📋 copiado"
}

ailogs() {
    local dir="$HOME/Documentos/Notes/+/_output"
    local selected
    local file

    selected=$(
        find "$dir" -maxdepth 1 -type f -name "*.md" | sort -r | while read -r file; do
            base=$(basename "$file")
            date_part=$(echo "$base" | cut -d_ -f1)
            time_part=$(echo "$base" | cut -d_ -f2 | tr '-' ':')
            name_part=$(echo "$base" | cut -d_ -f3- | sed 's/\.md$//')
            printf "%s | %s | %s\t%s\n" "$date_part" "$time_part" "$name_part" "$file"
        done | fzf \
            --delimiter='\t' \
            --with-nth=1 \
            --preview 'glow {2}' \
            --preview-window=right:70% \
            --prompt='📂 logs > '
    )

    file=$(printf '%s' "$selected" | cut -f2)
    [ -n "$file" ] && glow "$file"
}

addlog() {
    local dir="$HOME/Documentos/Notes/+/_output"
    local label="$1"

    if [ -z "$label" ]; then
        read -rp "Nome do log (default: manual): " label
        label="${label:-manual}"
    fi

    local file="$dir/$(date +%Y-%m-%d_%H-%M-%S)_${label}.md"
    mkdir -p "$dir"
    nano "$file"
    echo -e "\n💾 salvo em: $file"
}