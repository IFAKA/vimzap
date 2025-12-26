#!/bin/bash
# VimZap Installer - https://github.com/IFAKA/vimzap
# Verify: curl -fsSL ifaka.github.io/vimzap/i | less

set -euo pipefail

VIMZAP_MARKER="# VimZap aliases"

# Single source of truth for VimZap plugins
# Both install and update use this list
VIMZAP_PLUGINS=(
  "williamboman/mason.nvim"
  "folke/snacks.nvim"
  "folke/which-key.nvim"
  "hrsh7th/nvim-cmp"
  "hrsh7th/cmp-nvim-lsp"
  "hrsh7th/cmp-buffer"
  "hrsh7th/cmp-path"
  "lewis6991/gitsigns.nvim"
  "MeanderingProgrammer/render-markdown.nvim"
  "stevearc/conform.nvim"
  "echasnovski/mini.nvim"
  "nvim-treesitter/nvim-treesitter"
  "mfussenegger/nvim-dap"
  "rcarriga/nvim-dap-ui"
  "nvim-neotest/nvim-nio"
  "IFAKA/prophet.nvim"
)

# Fetch the PLUGINS array from the latest installer script on GitHub
fetch_plugins_list() {
  local temp_script="/tmp/vimzap_installer_$$"
  
  # Download the latest installer script
  if ! curl -fsSL "https://raw.githubusercontent.com/IFAKA/vimzap/main/i" -o "$temp_script" 2>/dev/null; then
    rm -f "$temp_script"
    return 1
  fi
  
  # Extract the PLUGINS array from main() function
  # Use the "Installing plugins" echo as a marker (only in main(), not update())
  local plugins=$(sed -n '/Installing plugins\.\.\./,/^  PLUGIN_DIR=/{
    /^    "[^"]*\/[^"]*"/{
      s/^[[:space:]]*"\([^"]*\)".*/\1/p
    }
  }' "$temp_script" | tr '\n' ' ')
  
  rm -f "$temp_script"
  
  if [[ -z "$plugins" ]]; then
    return 1
  fi
  
  echo "$plugins"
  return 0
}

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

  # Skip if already added
  if grep -q "$VIMZAP_MARKER" "$rc_file" 2>/dev/null; then
    return 0
  fi

  echo "" >> "$rc_file"
  echo "$VIMZAP_MARKER" >> "$rc_file"
  echo "alias v='nvim'" >> "$rc_file"
  echo "alias vi='nvim'" >> "$rc_file"
  echo "alias vim='nvim'" >> "$rc_file"
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
  local plugins_updated=0
  local plugins_unchanged=0
  local plugins_failed=0

  # Update config files
  echo "  Updating config..."
  mkdir -p ~/.config/nvim/lua
  mkdir -p ~/.config/nvim/scripts
  BASE_URL="https://raw.githubusercontent.com/IFAKA/vimzap/main"
  
  CONFIG_FILES=(
    "init.lua"
    "lua/options.lua"
    "lua/plugins.lua"
    "lua/lsp.lua"
    "lua/debug.lua"
    "lua/keymaps.lua"
    "lua/benchmark.lua"
    "lua/md-share.lua"
    "lua/health.lua"
    "scripts/md-server.py"
  )
  
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
          ((config_updated++))
        else
          rm "$temp"
          ((config_unchanged++))
        fi
      else
        mv "$temp" "$dest"
        echo "    Added: $file"
        ((config_updated++))
      fi
    else
      echo "    Failed: $file"
      rm -f "$temp"
    fi
  done
  
  if [[ $config_unchanged -gt 0 ]]; then
    echo "    ($config_unchanged unchanged)"
  fi
  
  # Make scripts executable
  chmod +x ~/.config/nvim/scripts/md-server.py

  # Update plugins
  echo ""
  echo "  Updating plugins..."
  PLUGIN_DIR="$HOME/.local/share/nvim/site/pack/plugins/opt"
  
  # Try to fetch the latest PLUGINS list from GitHub
  local plugins_str=$(fetch_plugins_list)
  
  # Prefer dynamic list, fall back to bundled list
  if [[ $? -ne 0 ]] || [[ -z "$plugins_str" ]]; then
    # Use the bundled VIMZAP_PLUGINS array (defined at top of script)
    PLUGINS=("${VIMZAP_PLUGINS[@]}")
  else
    # Convert space-separated string to array
    read -ra PLUGINS <<< "$plugins_str"
  fi
  
  local plugins_installed=0
  
  # First, install any missing plugins
  mkdir -p "$PLUGIN_DIR"
  for plugin in "${PLUGINS[@]}"; do
    name=$(basename "$plugin")
    if [[ ! -d "$PLUGIN_DIR/$name" ]]; then
      printf "    %s... " "$name"
      if git clone --depth=1 --quiet "https://github.com/$plugin" "$PLUGIN_DIR/$name" 2>/dev/null; then
        echo "installed"
        ((plugins_installed++))
      else
        echo "failed to install"
        ((plugins_failed++))
      fi
    fi
  done
  
  # Then, update existing plugins
  if [[ ! -d "$PLUGIN_DIR" ]]; then
    echo "    No plugins directory found"
  else
    for dir in "$PLUGIN_DIR"/*/; do
      if [[ ! -d "$dir" ]]; then
        continue
      fi
      
      name=$(basename "$dir")
      
      # Skip if we just installed this plugin
      local just_installed=false
      for plugin in "${PLUGINS[@]}"; do
        if [[ "$(basename "$plugin")" == "$name" ]] && [[ ! -d "$dir/.git" ]] || [[ $plugins_installed -gt 0 ]]; then
          just_installed=true
          break
        fi
      done
      
      # Skip newly installed plugins in the update loop
      if [[ $just_installed == true ]] && [[ ! -d "$dir/.git" ]]; then
        continue
      fi
      
      printf "    %s... " "$name"
      
      # Check if it's a git repo
      if [[ ! -d "$dir/.git" ]]; then
        echo "not a git repo"
        ((plugins_failed++))
        continue
      fi
      
      # Get current HEAD before pulling
      local old_head=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
      
      # Pull changes
      if git -C "$dir" pull --quiet 2>/dev/null; then
        local new_head=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
        
        if [[ "$old_head" != "$new_head" ]]; then
          # Get number of new commits
          local commit_count=$(git -C "$dir" rev-list --count "$old_head..$new_head" 2>/dev/null || echo "?")
          echo "updated (+$commit_count commits)"
          ((plugins_updated++))
        else
          echo "up to date"
          ((plugins_unchanged++))
        fi
      else
        echo "failed"
        ((plugins_failed++))
      fi
    done
  fi

  # Summary
  echo ""
  echo "  Summary"
  echo "  -------"
  echo "    Config files: $config_updated updated, $config_unchanged unchanged"
  if [[ $plugins_installed -gt 0 ]]; then
    echo "    Plugins: $plugins_installed installed, $plugins_updated updated, $plugins_unchanged up to date"
  else
    echo "    Plugins: $plugins_updated updated, $plugins_unchanged up to date"
  fi
  if [[ $plugins_failed -gt 0 ]]; then
    echo "    Failed: $plugins_failed plugins"
  fi
  echo ""
  
  # Suggest health check if updates were made
  if [[ $config_updated -gt 0 || $plugins_updated -gt 0 || $plugins_installed -gt 0 ]]; then
    echo "  ✓ Updates applied successfully!"
    echo ""
    echo "  Verify everything works:"
    echo "    nvim -c 'VimZapHealth'"
    echo ""
  else
    echo "  ✓ Already up to date!"
    echo ""
  fi
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

    brew install neovim git node ripgrep fzf lazygit 2>/dev/null || {
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

  # Check Neovim version
  echo "  [2/6] Checking Neovim version..."
  if command -v nvim &>/dev/null; then
    NVIM_VERSION=$(nvim --version 2>/dev/null | head -1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0.0")
    NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
    NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)
    
    echo "        Found: v${NVIM_VERSION}"
    
    if [[ "$NVIM_MAJOR" -eq 0 && "$NVIM_MINOR" -lt 11 ]]; then
      echo ""
      echo "  Error: VimZap requires Neovim 0.11 or higher"
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
  mkdir -p ~/.config/nvim/scripts
  mkdir -p ~/.local/share/nvim/site/pack/plugins/opt

  # Download config files
  BASE_URL="https://raw.githubusercontent.com/IFAKA/vimzap/main"
  CONFIG_FILES=(
    "init.lua"
    "lua/options.lua"
    "lua/plugins.lua"
    "lua/lsp.lua"
    "lua/debug.lua"
    "lua/keymaps.lua"
    "lua/benchmark.lua"
    "lua/md-share.lua"
    "lua/health.lua"
    "scripts/md-server.py"
  )
  for file in "${CONFIG_FILES[@]}"; do
    if ! curl -fsSL "$BASE_URL/$file" -o ~/.config/nvim/"$file"; then
      echo "Error: Failed to download $file"
      exit 1
    fi
  done
  
  # Make scripts executable
  chmod +x ~/.config/nvim/scripts/md-server.py

  # Plugins
  echo "  [4/6] Installing plugins..."
  # Use the shared VIMZAP_PLUGINS array (defined at top of script)
  PLUGINS=("${VIMZAP_PLUGINS[@]}")

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

  # LSP servers (installed via Mason on first launch)
  echo "  [5/6] LSP servers will be installed via Mason on first launch..."

  # Add shell aliases
  echo "  [6/6] Setting up aliases..."
  add_aliases
  echo "        v, vi, vim -> nvim"

  echo ""
  echo "  Done! Run: source $(get_shell_rc)"
  echo ""
  echo "  Usage:"
  echo "    v                Open Neovim (also vi, vim)"
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
  echo "  Update:"
  echo "    bash <(curl -fsSL ifaka.github.io/vimzap/i) update"
  echo ""
  echo "  Uninstall:"
  echo "    bash <(curl -fsSL ifaka.github.io/vimzap/i) uninstall"
  echo ""
}

main "$@"
