# Keymap Hints and Terminal Compatibility

## Goal

Make VimZap's existing keymaps discoverable while typing and make the terminal
toggle work reliably through Terminal and tmux on macOS.

## Design

- Add `which-key.nvim` as the only new plugin and initialize it with a short
  delay so pressing `<Space>` displays available mappings without changing
  their behavior.
- Register descriptive groups for Find, Code, Debug, Git, Prophet/SFCC, and
  Search/Help. Existing `vim.keymap.set()` descriptions remain authoritative.
- Map both `<C-/>` and `<C-_>` to the same terminal toggle because tmux commonly
  transmits `Ctrl+/` as `Ctrl+_`.
- Document the live hint behavior and the terminal fallback in the README.

## Verification

- Run the repository smoke test.
- Confirm the configuration loads headlessly with Neovim 0.12.
- Update the installed configuration using the repository installer.
