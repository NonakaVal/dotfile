#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[-]${NC} $*"; }

if [[ $EUID -ne 0 ]]; then
    err "Execute como root ou com sudo"
    exit 1
fi

GPU="${1:-auto}"

detect_gpu() {
    local gpu
    gpu=$(lspci | grep -iE 'vga|3d' | head -1)
    if echo "$gpu" | grep -qi nvidia; then
        echo "nvidia"
    elif echo "$gpu" | grep -qi amd; then
        echo "amd"
    elif echo "$gpu" | grep -qi intel; then
        echo "intel"
    else
        echo "unknown"
    fi
}

if [[ "$GPU" == "auto" ]]; then
    GPU=$(detect_gpu)
    log "GPU detectada: $GPU"
fi

case "$GPU" in
    nvidia)
        log "Instalando driver NVIDIA..."
        apt install -y \
            nvidia-driver \
            nvidia-detect \
            nvidia-settings \
            nvidia-persistenced \
            nvidia-kernel-dkms \
            firmware-misc-nonfree

        apt install -y \
            nvidia-driver-libs:i386 \
            nvidia-egl-icd:i386 \
            nvidia-vulkan-icd:i386 2>/dev/null || warn "Pacotes 32bit nao disponiveis"

        usermod -aG video,render "${SUDO_USER:-$USER}"

        log "NVIDIA instalado. Reboot necessario."
        ;;
    amd)
        log "Instalando driver AMD..."
        apt install -y firmware-amd-graphics libgl1-mesa-dri libglx-mesa0 mesa-vulkan-drivers
        ;;
    intel)
        log "Instalando driver Intel..."
        apt install -y firmware-linux-nonfree intel-media-va-driver mesa-vulkan-drivers
        ;;
    *)
        err "GPU nao detectada ou nao suportada: $GPU"
        err "Use: $0 [nvidia|amd|intel]"
        exit 1
        ;;
esac
