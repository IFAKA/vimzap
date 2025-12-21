#!/bin/bash
# VimZap: Uninstall
echo "🧹 Removing VimZap..."

# Kill any running md-share servers
if lsof -ti:8765 >/dev/null 2>&1; then
  echo "   Stopping markdown share server..."
  kill $(lsof -ti:8765) 2>/dev/null || true
fi

# Remove config and data
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim

echo "✅ VimZap removed!"
echo "   Note: Neovim and other tools were not uninstalled."
echo "   Run 'brew uninstall neovim' if you want to remove them too."
