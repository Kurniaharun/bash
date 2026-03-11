#!/bin/bash

# ╔══════════════════════════════════════════════════╗
# ║        TERMUX AUTO SETUP & UPDATER               ║
# ║   Update + Install: Node.js, FFmpeg, Git         ║
# ╚══════════════════════════════════════════════════╝

# Colors
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
B='\033[0;34m'
M='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Banner ───────────────────────────────────────────
banner() {
  clear
  echo ""
  echo -e "${C}${BOLD}"
  echo "  ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗"
  echo "  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝"
  echo "     ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝ "
  echo "     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗ "
  echo "     ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗"
  echo "     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
  echo -e "${RESET}"
  echo -e "  ${DIM}Auto Setup & Updater for Termux${RESET}"
  echo -e "  ${DIM}─────────────────────────────────────────────────${RESET}"
  echo ""
}

# ─── Logger ───────────────────────────────────────────
log_info()    { echo -e "  ${C}[*]${RESET} $1"; }
log_ok()      { echo -e "  ${G}[✓]${RESET} $1"; }
log_warn()    { echo -e "  ${Y}[!]${RESET} $1"; }
log_error()   { echo -e "  ${R}[✗]${RESET} $1"; }
log_step()    { echo -e "\n  ${M}${BOLD}━━ $1 ━━${RESET}\n"; }
log_done()    { echo -e "  ${G}${BOLD}[DONE]${RESET} $1"; }

# ─── Progress Bar ─────────────────────────────────────
progress() {
  local msg="$1"
  echo -ne "  ${C}[~]${RESET} ${msg}..."
}
progress_done() {
  echo -e " ${G}OK${RESET}"
}
progress_fail() {
  echo -e " ${R}FAIL${RESET}"
}

# ─── Check Termux ─────────────────────────────────────
check_termux() {
  log_step "Checking Environment"
  if [ -z "$PREFIX" ] || [[ "$PREFIX" != *"com.termux"* ]]; then
    log_warn "Tidak terdeteksi sebagai Termux."
    log_warn "Script ini dirancang untuk Termux di Android."
    read -p "  Lanjutkan tetap? (y/N): " ans
    [[ "$ans" != "y" && "$ans" != "Y" ]] && { log_error "Dibatalkan."; exit 1; }
  else
    log_ok "Termux terdeteksi: $PREFIX"
  fi
}

# ─── Storage Setup ────────────────────────────────────
setup_storage() {
  log_step "Storage Permission"
  if [ ! -d "$HOME/storage" ]; then
    log_info "Meminta izin akses storage..."
    termux-setup-storage
    sleep 2
    log_ok "Storage setup selesai"
  else
    log_ok "Storage sudah dikonfigurasi"
  fi
}

# ─── Update & Upgrade ─────────────────────────────────
update_packages() {
  log_step "Update & Upgrade Packages"

  progress "Mengupdate repository"
  if pkg update -y > /dev/null 2>&1; then
    progress_done
    log_ok "Repository berhasil diupdate"
  else
    progress_fail
    log_warn "Update sebagian gagal, mencoba lanjut..."
  fi

  progress "Upgrade semua package"
  if pkg upgrade -y > /dev/null 2>&1; then
    progress_done
    log_ok "Semua package berhasil diupgrade"
  else
    progress_fail
    log_warn "Upgrade sebagian gagal, mencoba lanjut..."
  fi
}

# ─── Install Package Helper ───────────────────────────
install_pkg() {
  local name="$1"
  local pkg_name="$2"
  local check_cmd="$3"

  progress "Menginstall $name"

  if command -v $check_cmd &> /dev/null; then
    progress_done
    local ver=$(command $check_cmd --version 2>/dev/null | head -1)
    log_ok "$name sudah terinstall → ${DIM}$ver${RESET}"
    return 0
  fi

  if pkg install -y "$pkg_name" > /dev/null 2>&1; then
    progress_done
    local ver=$(command $check_cmd --version 2>/dev/null | head -1)
    log_ok "$name berhasil diinstall → ${DIM}$ver${RESET}"
  else
    progress_fail
    log_error "Gagal install $name"
    FAILED_PKGS+=("$name")
  fi
}

# ─── Install Node.js ──────────────────────────────────
install_nodejs() {
  log_step "Installing Node.js (Latest)"

  install_pkg "Node.js" "nodejs" "node"

  # Install npm tools
  if command -v npm &> /dev/null; then
    progress "Update npm ke versi terbaru"
    if npm install -g npm@latest > /dev/null 2>&1; then
      progress_done
      log_ok "npm diupdate → $(npm --version)"
    else
      progress_fail
      log_warn "npm update gagal, versi lama tetap digunakan"
    fi
  fi
}

# ─── Install FFmpeg ───────────────────────────────────
install_ffmpeg() {
  log_step "Installing FFmpeg"
  install_pkg "FFmpeg" "ffmpeg" "ffmpeg"
}

# ─── Install Git ──────────────────────────────────────
install_git() {
  log_step "Installing Git"
  install_pkg "Git" "git" "git"

  if command -v git &> /dev/null; then
    # Set default git config jika belum ada
    if [ -z "$(git config --global user.name)" ]; then
      log_info "Mengatur konfigurasi Git default..."
      git config --global user.name "Termux User"
      git config --global user.email "user@termux.local"
      git config --global init.defaultBranch main
      log_ok "Git config default diterapkan"
    else
      log_ok "Git config sudah ada: $(git config --global user.name)"
    fi
  fi
}

# ─── Install Tools Tambahan ───────────────────────────
install_extras() {
  log_step "Installing Tools Pendukung"
  install_pkg "curl"   "curl"   "curl"
  install_pkg "wget"   "wget"   "wget"
  install_pkg "unzip"  "unzip"  "unzip"
  install_pkg "zip"    "zip"    "zip"
  install_pkg "python" "python" "python"
}

# ─── Verifikasi Instalasi ─────────────────────────────
verify_install() {
  log_step "Verifikasi Instalasi"

  declare -A tools=(
    ["node"]="Node.js"
    ["npm"]="NPM"
    ["ffmpeg"]="FFmpeg"
    ["git"]="Git"
    ["curl"]="cURL"
    ["python"]="Python"
  )

  local all_ok=true

  for cmd in "${!tools[@]}"; do
    local name="${tools[$cmd]}"
    if command -v "$cmd" &> /dev/null; then
      local ver=$($cmd --version 2>/dev/null | head -1 | sed 's/^[^0-9]*//' | cut -d' ' -f1)
      log_ok "${BOLD}$name${RESET} ${DIM}v$ver${RESET}"
    else
      log_error "${BOLD}$name${RESET} ${R}tidak ditemukan!${RESET}"
      all_ok=false
    fi
  done

  echo ""
  if $all_ok; then
    echo -e "  ${G}${BOLD}✔  Semua tools berhasil diinstall!${RESET}"
  else
    echo -e "  ${Y}${BOLD}⚠  Beberapa tools gagal. Coba jalankan ulang script.${RESET}"
  fi
}

# ─── Summary ──────────────────────────────────────────
show_summary() {
  echo ""
  echo -e "  ${C}${BOLD}─────────────────────────────────────────────────${RESET}"
  echo -e "  ${BOLD}  🎉  Setup Termux Selesai!${RESET}"
  echo -e "  ${C}${BOLD}─────────────────────────────────────────────────${RESET}"
  echo ""
  echo -e "  ${DIM}Versi yang terinstall:${RESET}"
  command -v node    &>/dev/null && echo -e "    ${G}▸${RESET} Node.js  $(node --version)"
  command -v npm     &>/dev/null && echo -e "    ${G}▸${RESET} NPM      v$(npm --version)"
  command -v ffmpeg  &>/dev/null && echo -e "    ${G}▸${RESET} FFmpeg   $(ffmpeg -version 2>&1 | head -1 | grep -oP 'ffmpeg version \K[^ ]+')"
  command -v git     &>/dev/null && echo -e "    ${G}▸${RESET} Git      $(git --version | grep -oP 'git version \K.*')"
  command -v python  &>/dev/null && echo -e "    ${G}▸${RESET} Python   $(python --version 2>&1 | grep -oP 'Python \K.*')"
  echo ""

  if [ ${#FAILED_PKGS[@]} -gt 0 ]; then
    echo -e "  ${R}${BOLD}Gagal diinstall:${RESET}"
    for pkg in "${FAILED_PKGS[@]}"; do
      echo -e "    ${R}▸${RESET} $pkg"
    done
    echo ""
    echo -e "  ${Y}Coba manual: ${C}pkg install <nama-package>${RESET}"
    echo ""
  fi

  echo -e "  ${DIM}Script by: Auto Setup Termux${RESET}"
  echo ""
}

# ─── MAIN ─────────────────────────────────────────────
FAILED_PKGS=()

banner
check_termux
setup_storage
update_packages
install_extras
install_nodejs
install_ffmpeg
install_git
verify_install
show_summary
