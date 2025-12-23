# Changelog

All notable changes to VimZap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-12-24

### Changed
- **Simplified keymaps** - Changed health check from `<Space>H` to `<Space>h` (lowercase)
- **Improved uninstall** - Added confirmation prompt and automatic backup before removal
- **Improved update** - Suggests health check after successful updates
- **Removed redundant benchmark keymap** - Health check now includes performance metrics

### Removed
- **Benchmark keymap (`<Space>B`)** - Functionality merged into health check

## [1.0.0] - 2025-12-24

### Added
- **VimZapHealth command** - Comprehensive diagnostics for troubleshooting
  - Checks Neovim version, plugins, LSP servers, external tools
  - Measures startup performance
  - Accessible via `:VimZapHealth` or `<Space>H`
- **CI/CD pipeline** - Automated testing on Ubuntu and macOS
  - Tests install script syntax
  - Validates Lua file syntax
  - Verifies config can load in Neovim
- **Configuration override support** - Load custom settings from `~/.config/nvim/vimzap-custom.lua`
- **Neovim version check** - Installer validates Neovim 0.11+ before installation
- **Backup warning** - Prompts before overwriting existing config
- **Troubleshooting guide** - Comprehensive README section for common issues
- **CHANGELOG** - Version history tracking

### Fixed
- **Critical: LSP root_dir bug** - Changed from deprecated `root_markers` to `root_dir` function
  - All LSP servers now properly detect project roots
  - Uses `vim.fs.root()` for Neovim 0.11+ compatibility
- **Markdown share error handling** - Added retry logic and validation
  - Checks if Python script exists before running
  - 10 retry attempts with 100ms intervals
  - Better error messages throughout
- **Treesitter silent failures** - Added user notifications when parsers fail to install
- **LazyGit graceful fallback** - Checks if lazygit is installed before launching
  - Shows helpful message with install command if missing

### Changed
- **Improved installer** - Now shows 6 steps instead of 5 for better clarity
- **Better error recovery** - More robust handling of partial install failures

### Removed
- **Redundant uninstall.sh** - Consolidated into main installer script

## [0.9.0] - 2025-12-23

### Added
- Initial public release
- File explorer with snacks.nvim
- Fuzzy finder (files, grep, buffers)
- LSP support (TypeScript, JavaScript, Lua, HTML, CSS, JSON, Tailwind)
- Git integration (lazygit, gitsigns)
- Markdown rendering and QR code sharing
- Node.js debugging support
- Completion with nvim-cmp
- Code formatting with conform.nvim
- Auto-pairs, comments, surround operations
- Buffer navigation (VSCode-like tabs)
- Floating terminal
- Performance benchmark tool
- One-line installer

[1.0.0]: https://github.com/IFAKA/vimzap/compare/v0.9.0...v1.0.0
[0.9.0]: https://github.com/IFAKA/vimzap/releases/tag/v0.9.0
