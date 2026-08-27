#!/bin/bash
# VimZap Installer - https://github.com/IFAKA/vimzap
# Verify: curl -fsSL ifaka.github.io/vimzap/i | less

set -euo pipefail

VIMZAP_MARKER="# VimZap aliases"
BASE_URL="https://raw.githubusercontent.com/IFAKA/vimzap/main"

# Single source of truth for config files
CONFIG_FILES=(
  "init.lua"
  "nvim-pack-lock.json"
  "lua/options.lua"
  "lua/plugins.lua"
  "lua/lsp.lua"
  "lua/debug.lua"
  "lua/keymaps.lua"
  "lua/md-share.lua"
  "lua/health.lua"
  "scripts/md-server.py"
)

get_shell_rc() {
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
    echo "$HOME/.zshrc"
  elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == *"bash"* ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
      echo "$HOME/.bash_profile"
    else
      echo "$HOME/.bashrc"
    fi
  else
    echo "$HOME/.profile"
  fi
}

add_aliases() {
  local rc_file
  rc_file=$(get_shell_rc)

  # Replace older VimZap alias blocks so updates get the latest shell helpers.
  remove_aliases >/dev/null 2>&1 || true

  echo "" >> "$rc_file"
  echo "$VIMZAP_MARKER" >> "$rc_file"
  cat >> "$rc_file" <<'EOF'
v() {
  if [ "$#" -eq 1 ]; then
    _vimzap_target="${1%:*}"
    _vimzap_line="${1##*:}"
    if [ "$_vimzap_target" != "$1" ] && [ -n "$_vimzap_target" ] && [ -e "$_vimzap_target" ]; then
      case "$_vimzap_line" in
        ""|*[!0-9]*) ;;
        *) nvim "+$_vimzap_line" "$_vimzap_target"; return ;;
      esac
    fi
  fi
  nvim "$@"
}
alias vi='nvim'
alias vim='nvim'
EOF
  echo "$VIMZAP_MARKER end" >> "$rc_file"
}

remove_aliases() {
  local rc_file
  rc_file=$(get_shell_rc)

  if [[ -f "$rc_file" ]] && grep -q "$VIMZAP_MARKER" "$rc_file"; then
    # Remove lines between markers (inclusive)
    sed -i.bak "/$VIMZAP_MARKER/,/$VIMZAP_MARKER end/d" "$rc_file"
    rm -f "${rc_file}.bak"
    echo "  Removed aliases from $rc_file"
  fi
}

uninstall() {
  echo ""
  echo "  VimZap Uninstall"
  echo "  ================"
  echo ""
  echo "  This will remove:"
  echo "    - ~/.config/nvim (VimZap config)"
  echo "    - ~/.local/share/nvim (plugins & data)"
  echo "    - ~/.cache/nvim (cache files)"
  echo "    - Shell aliases (v, vi, vim)"
  echo ""
  
  if [[ "$SKIP_PROMPTS" != "true" ]]; then
    read -p "  Are you sure? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "  Uninstall cancelled."
      exit 0
    fi
    echo ""
  fi

  # Remove aliases
  remove_aliases

  # Kill any running md-share servers
  if lsof -ti:8765 >/dev/null 2>&1; then
    echo "  Stopping markdown share server..."
    kill $(lsof -ti:8765) 2>/dev/null || true
  fi

  # Create backup before removing (just in case)
  if [[ -d ~/.config/nvim ]]; then
    echo "  Creating backup at ~/.config/nvim.backup.$(date +%s)..."
    cp -r ~/.config/nvim ~/.config/nvim.backup.$(date +%s)
  fi

  # Remove nvim config and data
  echo "  Removing config..."
  rm -rf ~/.config/nvim

  echo "  Removing plugins and data..."
  rm -rf ~/.local/share/nvim

  echo "  Removing cache..."
  rm -rf ~/.cache/nvim

  echo ""
  echo "  ✓ VimZap uninstalled successfully!"
  echo "  Backup saved at ~/.config/nvim.backup.*"
  echo ""
  echo "  Run: source $(get_shell_rc)"
  echo ""
}

# Parse flags
SKIP_PROMPTS=false
ACTION=""

for arg in "$@"; do
  case "$arg" in
    --uninstall|uninstall)
      ACTION="uninstall"
      ;;
    --update|update)
      ACTION="update"
      ;;
    --yes|-y)
      SKIP_PROMPTS=true
      ;;
  esac
done

# Check for --uninstall flag
if [[ "$ACTION" == "uninstall" ]]; then
  uninstall
  exit 0
fi

update() {
  echo ""
  echo "  VimZap Update"
  echo "  ============="
  echo ""

  # Counters for summary
  local config_updated=0
  local config_unchanged=0

  # Update config files
  echo "  Updating config..."
  mkdir -p ~/.config/nvim/lua
  mkdir -p ~/.config/nvim/lua/vimzap
  mkdir -p ~/.config/nvim/syntax
  mkdir -p ~/.config/nvim/scripts

  for file in "${CONFIG_FILES[@]}"; do
    local dest="$HOME/.config/nvim/$file"
    local temp="/tmp/vimzap_${file//\//_}"
    
    # Download to temp file
    if curl -fsSL "$BASE_URL/$file" -o "$temp" 2>/dev/null; then
      # Check if file exists and has changed
      if [[ -f "$dest" ]]; then
        if ! cmp -s "$dest" "$temp"; then
          mv "$temp" "$dest"
          echo "    Updated: $file"
          ((config_updated += 1))
        else
          rm "$temp"
          ((config_unchanged += 1))
        fi
      else
        mv "$temp" "$dest"
        echo "    Added: $file"
        ((config_updated += 1))
      fi
    else
      echo "    Failed: $file"
      rm -f "$temp"
    fi
  done
  
  if [[ $config_unchanged -gt 0 ]]; then
    echo "    ($config_unchanged unchanged)"
  fi

  # Prophet v2 owns SFCC support; remove files installed by older VimZap releases.
  rm -f ~/.config/nvim/lua/sfcc.lua ~/.config/nvim/lua/benchmark.lua ~/.config/nvim/syntax/isml.vim ~/.config/nvim/syntax/ds.vim ~/.config/nvim/ftdetect/isml.vim ~/.config/nvim/ftdetect/ds.vim
  
  # Make scripts executable
  chmod +x ~/.config/nvim/scripts/md-server.py

  # Update plugins through Neovim's native package manager.
  echo ""
  echo "  Updating plugins..."
  nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
  echo "    Native packages synchronized"

  # Update shell aliases/functions
  echo ""
  echo "  Updating aliases..."
  add_aliases
  echo "    Updated: $(get_shell_rc)"

  # Summary
  echo ""
  echo "  Summary"
  echo "  -------"
  echo "    Config files: $config_updated updated, $config_unchanged unchanged"
  echo "    Plugins: managed by vim.pack"
  echo ""
  
  echo "  ✓ Update complete!"
  echo ""
  echo "  Verify everything works:"
  echo "    nvim -c 'VimZapHealth'"
  echo ""
}

# Check for --update flag
if [[ "$ACTION" == "update" ]]; then
  update
  exit 0
fi

main() {
  echo ""
  echo "  VimZap Installer"
  echo "  ================"
  echo ""

  OS="$(uname -s)"
  if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
    echo "Error: Unsupported OS: $OS (only macOS and Linux supported)"
    exit 1
  fi

  echo "  OS: $OS"
  echo ""
  
  # Check for existing nvim config and warn
  if [[ -d "$HOME/.config/nvim" ]]; then
    echo "  Warning: Existing Neovim config detected!"
    echo "  This will overwrite: ~/.config/nvim"
    echo ""
    
    if [[ "$SKIP_PROMPTS" != "true" ]]; then
      read -p "  Continue? (y/N) " -n 1 -r
      echo ""
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "  Installation cancelled."
        exit 0
      fi
      echo ""
    else
      echo "  Continuing (--yes flag provided)..."
      echo ""
    fi
  fi

  # macOS
  if [[ "$OS" == "Darwin" ]]; then
    echo "  [1/6] Installing tools via Homebrew..."

    if ! command -v brew &>/dev/null; then
      echo "        Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew install neovim git node tree-sitter-cli ripgrep fzf lazygit 2>/dev/null || {
      echo "        Some packages may have failed, continuing..."
    }
  fi

  # Linux
  if [[ "$OS" == "Linux" ]]; then
    echo "  [1/6] Installing tools..."

    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
      sudo apt-get install -y neovim git nodejs npm ripgrep fzf curl
      # lazygit via binary
      if ! command -v lazygit &>/dev/null; then
        echo "        Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | sed -n 's/.*"tag_name": "v\([^"]*\)".*/\1/p' | head -1)
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        sudo tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
        rm /tmp/lazygit.tar.gz
      fi
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y neovim git nodejs npm ripgrep fzf
      sudo dnf copr enable atim/lazygit -y 2>/dev/null && sudo dnf install -y lazygit || true
    elif command -v pacman &>/dev/null; then
      sudo pacman -Sy --noconfirm neovim git nodejs npm ripgrep fzf lazygit
    else
      echo "  Warning: Unknown package manager."
      echo "  Please install manually: neovim git nodejs npm tree-sitter-cli ripgrep fzf lazygit"
    fi

    if ! command -v tree-sitter &>/dev/null; then
      echo "        Installing tree-sitter CLI..."
      if command -v npm &>/dev/null; then
        sudo npm install -g tree-sitter-cli 2>/dev/null || {
          echo "        Failed to install tree-sitter CLI via npm."
          echo "        Install manually: npm install -g tree-sitter-cli"
        }
      else
        echo "        npm not found. Install manually: npm install -g tree-sitter-cli"
      fi
    fi
  fi

  # Check Neovim version
  echo "  [2/6] Checking Neovim version..."
  if command -v nvim &>/dev/null; then
    NVIM_VERSION=$(nvim --version 2>/dev/null | head -1 | sed -n 's/.*v\([0-9]*\.[0-9]*\).*/\1/p')
    if [[ -z "$NVIM_VERSION" ]]; then
      NVIM_VERSION="0.0"
    fi
    NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
    NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)
    
    echo "        Found: v${NVIM_VERSION}"
    
    if [[ "$NVIM_MAJOR" -eq 0 && "$NVIM_MINOR" -lt 12 ]]; then
      echo ""
      echo "  Error: VimZap requires Neovim 0.12 or higher"
      echo "  Your version: v${NVIM_VERSION}"
      echo ""
      echo "  Update Neovim:"
      if [[ "$OS" == "Darwin" ]]; then
        echo "    brew upgrade neovim"
      else
        echo "    See: https://github.com/neovim/neovim/releases"
      fi
      exit 1
    fi
  else
    echo "        Neovim not found (will be installed)"
  fi
  echo ""

  # Directories
  echo "  [3/6] Setting up config..."
  mkdir -p ~/.config/nvim/lua
  mkdir -p ~/.config/nvim/lua/vimzap
  mkdir -p ~/.config/nvim/syntax
  mkdir -p ~/.config/nvim/scripts

  # Download config files
  for file in "${CONFIG_FILES[@]}"; do
    if ! curl -fsSL "$BASE_URL/$file" -o ~/.config/nvim/"$file"; then
      echo "Error: Failed to download $file"
      exit 1
    fi
  done
  
  # Make scripts executable
  chmod +x ~/.config/nvim/scripts/md-server.py

  # Plugins are declared by the config and installed by vim.pack.
  echo "  [4/6] Installing plugins..."
  nvim --headless +qa
  echo "        Native packages installed"

  # LSP servers (installed via Mason on first launch)
  echo "  [5/6] LSP servers will be installed via Mason on first launch..."

  # Add shell aliases
  echo "  [6/6] Setting up aliases..."
  add_aliases
  echo "        v -> nvim (supports path:line), vi/vim -> nvim"

  echo ""
  echo "  Done! Run: source $(get_shell_rc)"
  echo ""
  echo "  Usage:"
  echo "    v                Open Neovim (also vi, vim)"
  echo "    v file:line      Open file at line"
  echo "    <Space>?         Show all commands"
  echo "    <Space>e         File explorer"
  echo "    <Space>ff        Find files"
  echo "    <Space>fg        Grep"
  echo "    <Space>fp        Copy project-relative file path"
  echo ""
  echo "  Explorer keys:"
  echo "    a                Add file/folder"
  echo "    d                Delete"
  echo "    r                Rename"
  echo "    m                Move"
  echo "    c                Copy"
  echo ""
  echo "  Update:"
  echo "    bash <(curl -fsSL ifaka.github.io/vimzap/i) update"
  echo ""
  echo "  Uninstall:"
  echo "    bash <(curl -fsSL ifaka.github.io/vimzap/i) uninstall"
  echo ""
}

main "$@"
