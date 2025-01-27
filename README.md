# NixOS Configuration Files

My personal NixOS configuration files (dotfiles) using the Nix Flakes system. This setup provides a reproducible and declarative system configuration with KDE Plasma 6 as the desktop environment.

## Overview

- **System**: NixOS (Unstable)
- **Desktop**: KDE Plasma 6
- **Terminal**: Alacritty + Ghostty
- **Browser**: Firefox, Chromium
- **Media**: MPV (with Anime4K), Jellyfin

## Structure

- `flake.nix` - The entry point for the flake configuration
- `configuration.nix` - Main NixOS system configuration
- `home.nix` - Home-manager configuration for user environment
- `hardware-configuration.nix` - Hardware-specific settings

## Features

### System Configuration
- AMD GPU support with hardware acceleration
- Bluetooth functionality
- Advanced storage setup with BTRFS and NTFS mounts
- Jellyfin media server integration

### Desktop Environment
- KDE Plasma 6 with SDDM
- Custom terminal configuration (Alacritty)
- Customized MPV with Anime4K shaders

### Development
- Git configuration
- Neovim as default editor
- Development tools and utilities

### Gaming
- Steam with Remote Play support
- Gaming-specific hardware configurations
- Controller and gamepad support

## Installation

1. Clone this repository:

git clone https://github.com/JBrownDev-1/nixflake.git

    Build and switch to the configuration:

sudo nixos-rebuild switch --flake .#nixos

    Apply home-manager configuration:

home-manager switch

Useful Aliases

    smm - Rebuild and switch NixOS configuration
    hm - Switch home-manager configuration

License

Feel free to use and modify these configurations as you see fit!
