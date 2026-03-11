#!/bin/bash

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
M='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

banner() {
  clear
  echo ""
  echo -e "${C}${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║       TERMUX AUTO SETUP SCRIPT           ║"
  echo "  ║  Node.js • FFmpeg • Git • Python         ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo ""
}

ok()   { echo -e "  ${G}[✓]${RESET} $1"; }
info() { echo -e "  ${C}[*]${RESET} $1"; }
warn() { echo -e "  ${Y}[!]${RESET} $1"; }
err()  { echo -e "  ${R}[✗]${RESET} $1"; }
step() { echo -e "\n  ${M}${BOLD}── $1 ──${RESET}\n"; }

# ── Update & Upgrade ──────────────────────────────────
step "Update & Upgrade"

info "pkg update..."
pkg update -y
ok "Update selesai"

info "pkg upgrade..."
pkg upgrade -y
ok "Upgrade selesai"

# ── Install Packages ──────────────────────────────────
step "Install Packages"

PACKAGES=(nodejs ffmpeg git python curl wget unzip)

for pkg in "${PACKAGES[@]}"; do
  info "Install $pkg..."
  if pkg install -y "$pkg" > /dev/null 2>&1; then
    ok "$pkg terinstall"
  else
    warn "$pkg gagal, coba lagi nanti"
  fi
done

# ── Git Config ────────────────────────────────────────
if command -v git &>/dev/null; then
  if [ -z "$(git config --global user.name)" ]; then
    git config --global user.name "Termux User"
    git config --global user.email "user@termux.local"
    git config --global init.defaultBranch main
    ok "Git config diterapkan"
  fi
fi

# ── Selesai ───────────────────────────────────────────
step "Selesai"

command -v node    &>/dev/null && ok "Node.js  $(node --version)"
command -v npm     &>/dev/null && ok "NPM      v$(npm --version)"
command -v ffmpeg  &>/dev/null && ok "FFmpeg   $(ffmpeg -version 2>&1 | grep -oP 'ffmpeg version \K[^ ]+')"
command -v git     &>/dev/null && ok "Git      $(git --version | grep -oP 'git version \K.*')"
command -v python  &>/dev/null && ok "Python   $(python --version 2>&1)"

echo ""
echo -e "  ${G}${BOLD}✔  Setup Termux selesai!${RESET}"
echo ""
