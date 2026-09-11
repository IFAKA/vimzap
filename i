#!/usr/bin/env bash
# VimZap installer — https://github.com/IFAKA/vimzap
# Verify: curl -fsSL ifaka.github.io/vimzap/i | bash

set -euo pipefail

BASE_URL="https://github.com/IFAKA/vimzap/raw/refs/heads/main"
VIMZAP_NPM_PREFIX="${HOME}/.local/share/vimzap/npm"
VIMZAP_MARKER="${HOME}/.config/nvim/.vimzap-managed"
CACHE_BUST="$(date +%s)"
SKIP_PROMPTS=false
DRY_RUN=false
ACTION="install"
VIMZAP_STAGE=""

# Single source of truth for files owned by VimZap.
CONFIG_FILES=(
  "init.lua"
  "nvim-pack-lock.json"
  "lua/options.lua"
  "lua/plugins.lua"
  "lua/lsp.lua"
  "lsp/ts_ls.lua"
  "lsp/html.lua"
  "lsp/cssls.lua"
  "lsp/jsonls.lua"
  "lsp/tailwindcss.lua"
  "lsp/eslint.lua"
  "lsp/lua_ls.lua"
  "lsp/pyright.lua"
  "lsp/gopls.lua"
  "lsp/clangd.lua"
  "lsp/rust_analyzer.lua"
  "lua/keymaps.lua"
  "lua/vimzap/tasks.lua"
  "lua/vimzap/projects.lua"
  "lua/vimzap/debug.lua"
  "lua/vimzap/dashboard.lua"
)

usage() {
  cat <<'EOF'
VimZap — lean Neovim setup

Usage:
  bash <(curl -fsSL ifaka.github.io/vimzap/i) [action] [options]

Actions:
  install       Install or repair VimZap (default)
  update        Refresh VimZap files and plugins
  uninstall     Remove VimZap-owned files, keeping a backup

Options:
  -y, --yes     Skip confirmation prompts
  --dry-run     Show actions without changing files or installing packages
  -h, --help    Show this help

Supported platforms: macOS and Linux
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

confirm() {
  [[ "$SKIP_PROMPTS" == "true" ]] && return 0
  read -r -p "  $1 (y/N) " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

install_packages() {
  local os="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [1/5] Would install Neovim, Git, Node.js, ripgrep, and curl"
    return 0
  fi

  if [[ "$os" == "Darwin" ]]; then
    echo "  [1/5] Installing tools via Homebrew..."
    if ! command -v brew &>/dev/null; then
      echo "        Homebrew is required: https://brew.sh"
      return 1
    fi
    brew install neovim git node ripgrep 2>/dev/null || true
    brew upgrade node >/dev/null 2>&1 || true
    export PATH="$(brew --prefix node)/bin:$PATH"
    return 0
  fi

  echo "  [1/5] Installing tools..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y neovim git nodejs npm ripgrep curl
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y neovim git nodejs npm ripgrep curl
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm neovim git nodejs npm ripgrep curl
  else
    echo "  Warning: install Neovim, Git, Node.js, npm, ripgrep, and curl manually."
  fi
}

check_nvim() {
  echo "  [2/5] Checking Neovim version..."
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "        Would verify Neovim 0.12+"
    return 0
  fi
  command -v nvim &>/dev/null || die "Neovim was not found. Install Neovim 0.12+ and run this again."

  local version major minor
  version=$(nvim --version 2>/dev/null | head -1 | sed -n 's/.*v\([0-9]*\.[0-9]*\).*/\1/p')
  major=${version%%.*}
  minor=${version#*.}
  echo "        Found: v${version:-unknown}"
  [[ -n "$version" && ( "$major" -gt 0 || "$minor" -ge 12 ) ]] || die "VimZap requires Neovim 0.12 or higher."
}

stage_config() {
  local stage="$1"
  local file
  mkdir -p "$stage/lua/vimzap"
  for file in "${CONFIG_FILES[@]}"; do
    echo "        Downloading $file"
    curl -fsSL "$BASE_URL/$file?vimzap_cache=$CACHE_BUST" -o "$stage/$file" \
      || die "Failed to download $file; your existing config was left untouched."
  done
}

backup_and_install_config() {
  local stage="$1"
  local config_dir="$HOME/.config/nvim"
  local backup_dir="$HOME/.config/nvim.backup.$(date +%s)"
  local file dest

  echo "  [3/5] Installing VimZap config..."
  if [[ -d "$config_dir" && ! -f "$VIMZAP_MARKER" ]]; then
    if ! confirm "Existing Neovim config found. Back up and replace VimZap-owned paths?"; then
      echo "  Installation cancelled."
      exit 0
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "        Would replace ${#CONFIG_FILES[@]} managed files in $config_dir"
    return 0
  fi

  mkdir -p "$config_dir" "$backup_dir"
  for file in "${CONFIG_FILES[@]}"; do
    dest="$config_dir/$file"
    if [[ -f "$dest" ]]; then
      mkdir -p "$backup_dir/$(dirname "$file")"
      cp "$dest" "$backup_dir/$file"
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$stage/$file" "$dest"
  done
  printf 'VimZap owns the files listed in the installer manifest.\n' > "$VIMZAP_MARKER"
  echo "        Backup: $backup_dir"
}

install_required_tools() {
  echo "  [5/5] Installing JavaScript/SFCC developer tools..."
  [[ "$DRY_RUN" == "true" ]] && { echo "        Would install language servers"; return 0; }
  command -v npm &>/dev/null || die "npm is required but was not found."

  local node_major
  node_major=$(node -p 'process.versions.node.split(".")[0]')
  [[ "$node_major" -ge 22 ]] || die "Node.js 22+ is required (found $(node --version))."

  mkdir -p "$VIMZAP_NPM_PREFIX/bin" "$VIMZAP_NPM_PREFIX/lib"
  npm install --global --prefix "$VIMZAP_NPM_PREFIX" \
    typescript@5.9.3 typescript-language-server vscode-langservers-extracted \
    @tailwindcss/language-server
}

sync_plugins() {
  echo "  [4/5] Installing plugins..."
  [[ "$DRY_RUN" == "true" ]] && { echo "        Would synchronize native packages"; return 0; }
  nvim --headless +qa
  echo "        Native packages synchronized"
}

install_or_update() {
  local os
  os=$(uname -s)
  [[ "$os" == "Darwin" || "$os" == "Linux" ]] || die "Unsupported OS: $os (only macOS and Linux supported)"
  echo ""
  [[ "$ACTION" == "update" ]] && echo "  VimZap Update" || echo "  VimZap Install"
  echo "  ==============="
  echo ""

  install_packages "$os"
  check_nvim
  VIMZAP_STAGE=$(mktemp -d "${TMPDIR:-/tmp}/vimzap.XXXXXX")
  trap '[[ -n "${VIMZAP_STAGE:-}" ]] && rm -rf "$VIMZAP_STAGE"' EXIT
  stage_config "$VIMZAP_STAGE"
  backup_and_install_config "$VIMZAP_STAGE"
  sync_plugins
  install_required_tools

  echo ""
  echo "  ✓ VimZap $ACTION complete. Run: nvim"
  echo "  Update:    bash <(curl -fsSL ifaka.github.io/vimzap/i) update"
  echo "  Uninstall: bash <(curl -fsSL ifaka.github.io/vimzap/i) uninstall"
}

uninstall() {
  local config_dir="$HOME/.config/nvim"
  local backup_dir="$HOME/.config/nvim.uninstall-backup.$(date +%s)"
  local file path found=false

  echo ""
  echo "  VimZap Uninstall"
  echo "  ================"
  if [[ ! -f "$VIMZAP_MARKER" ]]; then
    echo "  No VimZap ownership marker found; nothing was removed."
    echo "  If this is a legacy install, back up your config and remove its files manually."
    return 0
  fi
  confirm "Remove VimZap-owned config files?" || { echo "  Uninstall cancelled."; return 0; }
  [[ "$DRY_RUN" == "true" ]] && { echo "  Would remove VimZap-owned files from $config_dir"; return 0; }

  mkdir -p "$backup_dir"
  for file in "${CONFIG_FILES[@]}"; do
    path="$config_dir/$file"
    if [[ -f "$path" ]]; then
      mkdir -p "$backup_dir/$(dirname "$file")"
      cp "$path" "$backup_dir/$file"
      rm -f "$path"
      found=true
    fi
  done
  rm -f "$VIMZAP_MARKER"
  echo "  ✓ VimZap config removed."
  echo "  Backup: $backup_dir"
  echo "  Shared Neovim data and language servers were kept."
  [[ "$found" == true ]] || rmdir "$config_dir" 2>/dev/null || true
}

for arg in "$@"; do
  case "$arg" in
    install) ACTION="install" ;;
    update|--update) ACTION="update" ;;
    uninstall|--uninstall) ACTION="uninstall" ;;
    -y|--yes) SKIP_PROMPTS=true ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument '$arg'. Run with --help for usage." ;;
  esac
done

if [[ "$ACTION" == "uninstall" ]]; then
  uninstall
else
  install_or_update
fi
