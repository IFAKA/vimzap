#!/bin/bash
# VimZap Installer - https://github.com/IFAKA/vimzap
# Verify: curl -fsSL ifaka.github.io/vimzap/i | less

set -euo pipefail

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

  # macOS
  if [[ "$OS" == "Darwin" ]]; then
    echo "  [1/4] Installing tools via Homebrew..."

    if ! command -v brew &>/dev/null; then
      echo "        Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    brew install neovim git node ripgrep fzf lazygit 2>/dev/null || {
      echo "        Some packages may have failed, continuing..."
    }
  fi

  # Linux
  if [[ "$OS" == "Linux" ]]; then
    echo "  [1/4] Installing tools..."

    if command -v apt-get &>/dev/null; then
      sudo apt-get update -qq
      sudo apt-get install -y neovim git nodejs npm ripgrep fzf curl
      # lazygit via binary
      if ! command -v lazygit &>/dev/null; then
        echo "        Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
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
      echo "  Please install manually: neovim git nodejs npm ripgrep fzf lazygit"
    fi
  fi

  # Directories
  echo "  [2/4] Setting up config..."
  mkdir -p ~/.config/nvim
  mkdir -p ~/.local/share/nvim/site/pack/plugins/opt

  # Download config
  CONFIG_URL="https://raw.githubusercontent.com/IFAKA/vimzap/main/init.lua"
  if ! curl -fsSL "$CONFIG_URL" -o ~/.config/nvim/init.lua; then
    echo "Error: Failed to download config"
    exit 1
  fi

  # Plugins
  echo "  [3/4] Installing plugins..."
  PLUGINS=(
    "folke/snacks.nvim"
    "folke/which-key.nvim"
    "hrsh7th/nvim-cmp"
    "hrsh7th/cmp-nvim-lsp"
    "lewis6991/gitsigns.nvim"
  )

  PLUGIN_DIR="$HOME/.local/share/nvim/site/pack/plugins/opt"
  for plugin in "${PLUGINS[@]}"; do
    name=$(basename "$plugin")
    if [[ ! -d "$PLUGIN_DIR/$name" ]]; then
      printf "        %s " "$name"
      if git clone --depth=1 --quiet "https://github.com/$plugin" "$PLUGIN_DIR/$name" 2>/dev/null; then
        echo "ok"
      else
        echo "failed"
      fi
    fi
  done

  # LSP servers
  echo "  [4/4] Installing LSP servers..."
  if command -v npm &>/dev/null; then
    npm install -g typescript typescript-language-server vscode-langservers-extracted 2>/dev/null || {
      echo "        Note: Run with sudo if npm install fails"
    }
  else
    echo "        Warning: npm not found, LSP servers not installed"
  fi

  echo ""
  echo "  Done!"
  echo ""
  echo "  Usage:"
  echo "    nvim             Open Neovim"
  echo "    <Space>          Show all commands"
  echo "    <Space>e         File explorer"
  echo "    <Space>ff        Find files"
  echo "    <Space>fg        Grep"
  echo ""
  echo "  Explorer keys:"
  echo "    a                Add file/folder"
  echo "    d                Delete"
  echo "    r                Rename"
  echo "    m                Move"
  echo "    c                Copy"
  echo ""
  echo "  Uninstall:"
  echo "    rm -rf ~/.config/nvim ~/.local/share/nvim"
  echo ""
}

main "$@"
