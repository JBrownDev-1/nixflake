# Declarative NixOS Workstation & Host Configuration

[![NixOS](https://img.shields.io/badge/NixOS-Unstable-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)
[![Nix Flakes](https://img.shields.io/badge/Nix-Flakes-blueviolet.svg?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![Desktop](https://img.shields.io/badge/DE-KDE%20Plasma%206-brightgreen.svg?logo=kde&logoColor=white)](https://kde.org/plasma-desktop/)
[![Kernel](https://img.shields.io/badge/Kernel-6.12%20LTS-orange.svg?logo=linux&logoColor=white)](https://kernel.org)

A fully declarative, hermetic, and reproducible system configuration for a multi-purpose workstation, media host, and development environment managed via **Nix Flakes**.

---

## 🖥️ System Architecture & Specs

| Component | Implementation |
|---|---|
| **OS & Channel** | NixOS (Unstable channel, tracked via pinned `flake.lock`) |
| **Kernel** | Linux Kernel 6.12 (Pinned LTS) + Zenpower Ryzen module |
| **Desktop Environment** | KDE Plasma 6 (Wayland) + SDDM Display Manager |
| **Graphics & Compute** | AMDGPU, ROCm / HIP runtime acceleration, OpenCL |
| **Audio Architecture** | PipeWire with RealtimeKit (`rtkit`) & 32-bit ALSA compatibility |
| **Virtualization & Containers** | Rootless Podman (Docker CLI compatible) & KVM/IOMMU Passthrough |
| **Local Proxy / PKI** | Trusted internal Caddy CA root certificate integration |

---

## ⚙️ Engineering & Architecture Highlights

### 1. Storage Orchestration & Service Dependencies
* **Systemd Unit Ordering:** Configured `systemd.services.jellyfin.unitConfig.RequiresMountsFor` to explicitly delay media server initialization until high-capacity Btrfs pools are mounted, preventing container race conditions and directory creation errors.
* **Hybrid Storage Pools:** 
  * High-capacity Btrfs array using transparent `zstd` compression with systemd auto-mount and tailored drive spin-up/idle timeouts.
  * Native dual-boot interoperability via isolated NTFS-3G mounts.

### 2. Privilege Separation & Kernel Hardening
* **Linux Capabilities (`cap_sys_nice`):** CoreCtrl is wrapped via `security.wrappers` to allow dynamic GPU overclocking and fan curve adjustments without running the graphical application with root privileges.
* **Rootless Networking:** Configured `net.ipv4.ip_unprivileged_port_start = 80` via `sysctl`, permitting non-root Podman containers and local development services to bind to low-order web ports.

### 3. Hardware & Embedded Development
* Custom `udev` rules and user-group delegation (`dialout`, `i2c`) for low-level embedded device flashing, Proffieboard soundboard synthesis, Arduino development, and STM32 DFU bootloaders.

### 4. Binary Caching & Build Optimization
* Integration with **Cachix** binary caches (including optimized Stable Diffusion / ML models) to accelerate build times and minimize compilation overhead.
* Automated weekly Nix garbage collection (`gc`) and continuous hard-link store deduplication (`auto-optimise-store`).

---

## 📁 Repository Structure

```text
.
├── flake.nix                  # Flake entry point and input specifications
├── flake.lock                 # Crytographically pinned dependency lockfile
├── configuration.nix          # Core system-level configuration and module definitions
├── hardware-configuration.nix # Target machine filesystem and hardware modules
├── cachix.nix                 # Custom binary cache and substituter configurations
├── cachix/                    # Specialized cache configurations (e.g., Stable Diffusion)
├── certs/                     # Local internal CA certificates (Caddy root CA)
└── README.md                  # System architecture documentation
