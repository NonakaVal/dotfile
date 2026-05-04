#!/usr/bin/env bash
# =============================================================================
# transcribe-install.sh — Instalação de dependências do comando `transcribe`
# Requer: Debian/Ubuntu | Python 3 | pip
# USO: bash transcribe-install.sh
# =============================================================================

set -euo pipefail

# --- Cores ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✔]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[→]${NC} $1"; }
err()  { echo -e "${RED}[✘]${NC} $1"; }
sep()  { echo -e "\n${BOLD}════════════════════════════════════════${NC}"; echo -e "${BOLD} $1${NC}"; echo -e "${BOLD}════════════════════════════════════════${NC}\n"; }

# =============================================================================
# 0. DETECÇÃO DE AMBIENTE
# =============================================================================
sep "0. Verificando ambiente"

# Usuário real (mesmo rodando com sudo)
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

info "Usuário: $REAL_USER"
info "Home:    $REAL_HOME"

# Verifica Python 3.8+
if ! command -v python3 &>/dev/null; then
  err "Python 3 não encontrado. Instale com: sudo apt install python3"
  exit 1
fi

PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)

if [[ "$PY_MAJOR" -lt 3 || ( "$PY_MAJOR" -eq 3 && "$PY_MINOR" -lt 8 ) ]]; then
  err "Python $PY_VERSION detectado. É necessário Python 3.8 ou superior."
  exit 1
fi

log "Python $PY_VERSION detectado"

# =============================================================================
# 1. DEPENDÊNCIAS APT
# =============================================================================
sep "1. Dependências do sistema (apt)"

APT_DEPS=(
  ffmpeg          # conversão de áudio (obrigatório)
  python3-pip     # instalador de pacotes Python
  python3-venv    # ambientes virtuais
  python3-dev     # headers para compilar extensões C
  curl
  git
)

if [[ $EUID -eq 0 ]]; then
  info "Atualizando lista de pacotes..."
  apt-get update -qq

  for pkg in "${APT_DEPS[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
      log "Já instalado: $pkg"
    else
      info "Instalando: $pkg"
      apt-get install -y "$pkg" && log "Instalado: $pkg" || warn "Falhou: $pkg"
    fi
  done
else
  warn "Não está rodando como root — pulando instalação apt."
  warn "Se ffmpeg não estiver instalado, rode: sudo apt install ffmpeg"

  # Verifica ffmpeg manualmente
  if ! command -v ffmpeg &>/dev/null; then
    err "ffmpeg não encontrado. É obrigatório."
    err "Rode: sudo apt install ffmpeg   e execute este script novamente."
    exit 1
  else
    log "ffmpeg encontrado: $(ffmpeg -version 2>&1 | head -1)"
  fi
fi

# =============================================================================
# 2. NVIDIA CUDA (opcional — acelera Whisper)
# =============================================================================
sep "2. Verificando suporte a GPU (CUDA)"

HAS_GPU=false
HAS_CUDA=false

if command -v nvidia-smi &>/dev/null; then
  GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "desconhecida")
  log "GPU NVIDIA detectada: $GPU_NAME"
  HAS_GPU=true

  if python3 -c "import torch; print(torch.cuda.is_available())" 2>/dev/null | grep -q "True"; then
    log "CUDA disponível via PyTorch — transcrição acelerada por GPU!"
    HAS_CUDA=true
  else
    warn "GPU detectada mas CUDA não disponível via PyTorch."
    warn "O Whisper rodará na CPU (mais lento, mas funcional)."
    warn "Para ativar CUDA: https://pytorch.org/get-started/locally/"
  fi
else
  info "Nenhuma GPU NVIDIA detectada — Whisper rodará na CPU."
fi

# =============================================================================
# 3. PACOTES PYTHON
# =============================================================================
sep "3. Pacotes Python (pip)"

# Verifica se pip está disponível
if ! python3 -m pip --version &>/dev/null; then
  err "pip não encontrado. Instale com: sudo apt install python3-pip"
  exit 1
fi

log "pip: $(python3 -m pip --version)"

PIP_CMD="python3 -m pip install --break-system-packages --upgrade"

# ── numpy ────────────────────────────────────────────────────────────────────
info "Instalando numpy..."
$PIP_CMD "numpy" && log "numpy instalado" || {
  warn "numpy falhou com --break-system-packages, tentando sem flag..."
  python3 -m pip install --upgrade numpy && log "numpy instalado"
}

# ── openai-whisper ────────────────────────────────────────────────────────────
info "Instalando openai-whisper..."
$PIP_CMD "openai-whisper" && log "openai-whisper instalado" || {
  warn "Tentando sem --break-system-packages..."
  python3 -m pip install --upgrade openai-whisper && log "openai-whisper instalado"
}

# ── torch (PyTorch) ───────────────────────────────────────────────────────────
info "Instalando PyTorch..."
if $HAS_GPU && ! $HAS_CUDA; then
  warn "GPU detectada mas sem CUDA configurado — instalando PyTorch CPU."
fi

$PIP_CMD "torch" "torchvision" "torchaudio" \
  && log "PyTorch instalado" \
  || warn "PyTorch falhou — o Whisper pode funcionar sem ele em alguns casos."

# =============================================================================
# 4. INSTALAR O COMANDO `transcribe`
# =============================================================================
sep "4. Instalando o comando transcribe"

SCRIPT_ORIGEM="$(dirname "$(realpath "$0")")/transcribe"
DESTINO="/usr/local/bin/transcribe"

if [[ ! -f "$SCRIPT_ORIGEM" ]]; then
  warn "Arquivo 'transcribe' não encontrado em $(dirname "$0")"
  warn "Certifique-se de que o script 'transcribe' está na mesma pasta deste instalador."
else
  if [[ $EUID -eq 0 ]]; then
    cp "$SCRIPT_ORIGEM" "$DESTINO"
    chmod +x "$DESTINO"
    log "transcribe instalado em $DESTINO"
  else
    warn "Sem permissão root — tentando instalar em ~/.local/bin ..."
    mkdir -p "$REAL_HOME/.local/bin"
    cp "$SCRIPT_ORIGEM" "$REAL_HOME/.local/bin/transcribe"
    chmod +x "$REAL_HOME/.local/bin/transcribe"
    log "transcribe instalado em ~/.local/bin/transcribe"

    # Verifica se ~/.local/bin está no PATH
    if ! echo "$PATH" | grep -q "$REAL_HOME/.local/bin"; then
      warn "~/.local/bin não está no PATH."
      warn "Adicione ao seu ~/.bashrc:"
      echo -e "    ${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
      warn "Depois rode: source ~/.bashrc"
    fi
  fi
fi

# =============================================================================
# 5. PRÉ-DOWNLOAD DO MODELO (opcional)
# =============================================================================
sep "5. Pré-download de modelo Whisper (opcional)"

echo "O Whisper baixa o modelo automaticamente na primeira transcrição."
echo "Você pode baixar agora para evitar espera depois."
echo ""
echo "  [1] tiny    (~39 MB)  — mais rápido, menos preciso"
echo "  [2] base    (~74 MB)  — bom custo-benefício"
echo "  [3] small   (~244 MB) — recomendado para uso geral"
echo "  [4] medium  (~769 MB) — mais preciso (padrão dos seus scripts)"
echo "  [5] large   (~1.5 GB) — máxima precisão"
echo "  [6] Pular — baixar depois automaticamente"
echo ""
read -rp "  → Escolha [1-6]: " CHOICE

MODEL_MAP=( "" "tiny" "base" "small" "medium" "large" )

if [[ "$CHOICE" =~ ^[1-5]$ ]]; then
  MODELO="${MODEL_MAP[$CHOICE]}"
  info "Baixando modelo '$MODELO'... (pode demorar)"
  python3 -c "import whisper; whisper.load_model('$MODELO')" \
    && log "Modelo '$MODELO' pronto para uso" \
    || warn "Falha no download — será baixado automaticamente na primeira execução"
else
  info "Download pulado — o modelo será baixado na primeira vez que você usar transcribe."
fi

# =============================================================================
# RESUMO FINAL
# =============================================================================
sep "✅ Instalação concluída"

echo -e "${BOLD}Resumo:${NC}"
echo "  • ffmpeg:          $(ffmpeg -version 2>&1 | head -1 | cut -d' ' -f1-3)"
echo "  • Python:          $PY_VERSION"
echo "  • openai-whisper:  $(python3 -c 'import whisper; print(whisper.__version__ if hasattr(whisper,"__version__") else "instalado")' 2>/dev/null || echo 'verificar')"
echo "  • GPU/CUDA:        $( $HAS_CUDA && echo 'disponível ✔' || ( $HAS_GPU && echo 'GPU sem CUDA' || echo 'CPU only' ) )"
echo ""
echo -e "${BOLD}Como usar:${NC}"
echo "  transcribe                  # transcreve a pasta atual"
echo "  transcribe ~/Downloads      # transcreve outra pasta"
echo ""
if [[ $EUID -ne 0 ]]; then
  warn "Rode com sudo para instalar o comando globalmente: sudo bash transcribe-install.sh"
fi
