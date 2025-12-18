#!/bin/bash
# VimZap: Uninstall
echo "🧹 Removing VimZap..."
rm -rf ~/.config/nvim ~/.local/share/nvim
echo "✅ VimZap removed!"
echo "   Note: Neovim and other tools were not uninstalled."
echo "   Run 'brew uninstall neovim' if you want to remove them too."
