# Nerd Font Installer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement the plan task-by-task.

**Goal:** Make the VimZap macOS installer install the Nerd Font required for which-key icons.

**Architecture:** Extend the existing macOS Homebrew setup with an idempotent font-cask installation. Linux behavior and VimZap configuration remain unchanged; the installer will print the font name so the user can select it in Terminal.app.

**Tech Stack:** Bash installer, Homebrew cask, existing Bash syntax/smoke checks.

---

### Task 1: Add macOS Nerd Font installation

**Files:**
- Modify: `i`

**Step 1:** Add a helper that checks whether `font-jetbrains-mono-nerd-font` is already installed and installs it with Homebrew when missing.

**Step 2:** Call the helper from the existing macOS Homebrew setup after Homebrew is available.

**Step 3:** Print a concise Terminal.app instruction identifying `JetBrainsMono Nerd Font`.

**Step 4:** Run `bash -n i` and `bash tests/smoke.sh`.

**Step 5:** Review the focused diff, commit only the installer and plan files, reinstall VimZap with the public installer, and verify the installed config contains the expected setup.
