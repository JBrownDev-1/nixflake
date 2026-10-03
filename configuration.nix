{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # =========================================================================
  # 1. SYSTEM & NIX DAEMON CONFIGURATION
  # =========================================================================

  # Tracks the initial NixOS release version for stateful data compatibility
  system.stateVersion = "25.05";

  # Allow proprietary software (e.g., Steam, Discord, Vivaldi codecs)
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      # Enable Flakes and the new command-line interface
      experimental-features = [ "nix-command" "flakes" ];

      # Automatically deduplicate Nix store paths to conserve disk space
      auto-optimise-store = true;

      # Storage boundaries for garbage collection / build thresholds
      min-free = 10 * 1024 * 1024 * 1024; # 10 GB
      max-free = 20 * 1024 * 1024 * 1024; # 20 GB
    };

    # Automated weekly maintenance to prune old generations
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 10d";
    };
  };

  # =========================================================================
  # 2. BOOTLOADER & KERNEL CONFIGURATION
  # =========================================================================

  boot = {
    # Pinning a modern LTS/stable kernel for hardware support & Zenpower compatibility
    kernelPackages = pkgs.linuxPackages_6_12;

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3; # Restrict generation list in the boot menu
      };
      efi.canTouchEfiVariables = true;
    };

    kernelParams = [
      # AMD IOMMU & Virtualization Passthrough settings
      "amd_iommu=on"
      "iommu=pt"
      "kvm.ignore_msrs=1"
      "kvm.report_ignored_msrs=0"

      # Enable overdrive/powerplay controls for AMDGPU (required for CoreCtrl)
      "amdgpu.ppfeaturemask=0xffffffff"
    ];

    kernelModules = [
      "zenpower" # In-tree Ryzen thermal and power monitoring
      "kvm-amd"
      "i2c-dev"
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      zenpower
    ];

    kernel.sysctl = {
      # Permits rootless containers/dev servers to bind to lower standard ports
      "net.ipv4.ip_unprivileged_port_start" = 80;
    };
  };

  # =========================================================================
  # 3. HARDWARE & GRAPHICS (AMDGPU / ROCm)
  # =========================================================================

  hardware = {
    amdgpu.opencl.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true; # Critical for 32-bit Wine / Steam titles
      extraPackages = with pkgs; [
        rocmPackages.clr
        rocmPackages.rocm-runtime
        libvdpau
        libva
        libva-utils
      ];
    };
  };

  # Provide standardized paths expected by certain OpenCL/HIP workloads
  systemd.tmpfiles.rules = [
    "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
  ];

  # Allow CoreCtrl to control CPU/GPU power profiles without running the entire GUI as root
  security.wrappers.corectrl = {
    source = "${pkgs.corectrl}/bin/corectrl";
    capabilities = "cap_sys_nice+ep";
    owner = "root";
    group = "root";
    permissions = "u+rx,g+rx,o+rx";
  };

  # Embedded device access & flashing permissions
  services.udev.extraRules = ''
    # Proffieboard (Lightsaber soundboard flashing)
    KERNEL=="hidraw*", ATTRS{idVendor}=="289b", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="6668", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666"
  '';

  # =========================================================================
  # 4. STORAGE & MOUNT POINTS
  # =========================================================================

  fileSystems = {
    # Windows Shared Drive (Dual-boot parity)
    "/mnt/windowsgames" = {
      device = "/dev/disk/by-uuid/B06C21526C21149E";
      fsType = "ntfs-3g";
      options = [ "defaults" "nofail" "uid=1000" "gid=100" "umask=0022" "rw" ];
    };

    # High-capacity Btrfs Media Pool
    "/mnt/stuff16tb" = {
      device = "/dev/disk/by-uuid/74a59ea5-5267-42b5-89f2-5d92bee3f28b";
      fsType = "btrfs";
      options = [
        "compress=zstd"
        "nofail"
        "x-systemd.automount"
        "x-systemd.idle-timeout=0"    # Prevent cyclic spin-up/down on idle
        "x-systemd.device-timeout=30" # Allow slow HDD spin-up before systemd aborts mount
      ];
    };
  };

  # Prevent Jellyfin from starting before the dependent storage drive is ready
  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "/mnt/stuff16tb" ];

  # Allow unprivileged users to mount FUSE filesystems with allow_other (e.g. sshfs, rclone)
  programs.fuse.userAllowOther = true;

  # =========================================================================
  # 5. NETWORKING & FIREWALL
  # =========================================================================

  networking = {
    hostName = "nixos";
    enableIPv6 = false;

    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
    };

    firewall = {
      enable = true;
      # Note: KDE Connect, Sunshine, and Jellyfin configure their standard ports via their respective service modules
      allowedTCPPortRanges = [ { from = 42000; to = 42001; } ];
      allowedUDPPortRanges = [ { from = 42000; to = 42001; } ];
    };
  };

  services.resolved.enable = true;

  # Local mDNS discovery configuration
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # =========================================================================
  # 6. DESKTOP ENVIRONMENT & AUDIO
  # =========================================================================

  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    xkb.layout = "au";
  };

  services.desktopManager.plasma6.enable = true;
  services.libinput.enable = true;

  services.displayManager = {
    sddm.enable = true;
    autoLogin = {
      enable = true;
      user = "jake";
    };
  };

  # Real-time audio configuration with PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # =========================================================================
  # 7. GAMING & STREAMING
  # =========================================================================

  programs = {
    steam.enable = true;
    gamemode.enable = true;
    gamescope.enable = true;
    kdeconnect.enable = true;
  };

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;  # Required for KMS capture and input injection
    openFirewall = true; # Dynamically handles Sunshine firewall requirements
  };

  # =========================================================================
  # 8. SERVICES & VIRTUALIZATION
  # =========================================================================

  # Rootless Podman daemon with Docker CLI drop-in alias
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Media Server
  services.jellyfin = {
    enable = true;
    user = "jellyfin";
    group = "jellyfin";
    openFirewall = true;
  };

  # Synchronization
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
  };

  # General desktop integration services
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  services.printing.enable = true;
  services.blueman.enable = true;
  services.spice-vdagentd.enable = true; # VM guest integration utilities

  # =========================================================================
  # 9. USER ACCOUNTS
  # =========================================================================

  users.users.jake = {
    isNormalUser = true;
    extraGroups = [
      "wheel"          # Sudo privileges
      "networkmanager" # Network configuration
      "video" "render" # Direct hardware/GPU access
      "input" "gamepad"# Input handling
      "dialout" "i2c"  # Hardware flashing/serial buses (Arduino/Proffieboard)
      "kvm" "libvirtd" # Virtualization
      "docker"         # Podman compatibility socket access
      "bluetooth"
    ];
  };

  # =========================================================================
  # 10. LOCALIZATION & FONTS
  # =========================================================================

  time.timeZone = "Australia/Perth";
  i18n.defaultLocale = "en_AU.UTF-8";

  # Synchronize BIOS clock to local time to prevent desync when dual-booting with Windows
  time.hardwareClockInLocalTime = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # =========================================================================
  # 11. SYSTEM PACKAGES
  # =========================================================================

  environment.systemPackages = with pkgs; [
    # --- System Diagnostics & Utilities ---
    htop
    iotop
    lm_sensors
    smartmontools
    usbutils
    pciutils
    util-linux
    coreutils
    findutils
    wget
    git
    p7zip
    unrar
    unzip

    # --- Networking & Security Analysis ---
    iperf3
    tcpdump
    nmap
    sshfs

    # --- Containerization & Development ---
    docker-compose
    nodejs
    arduino
    dfu-util

    # --- Filesystem Drivers ---
    ntfs3g
    fuse

    # --- Audio / Video / Graphics Production ---
    easyeffects
    mpv
    yt-dlp
    darktable
    qgis
    kdePackages.libkscreen
    kdePackages.kate

    # --- Gaming, Compatibility & Emulation ---
    wine
    winetricks
    protontricks
    protonup-qt
    mangohud

    # --- Productivity & Communication ---
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = true;
    })
    firefox
    discord
    vesktop
    obsidian
    qbittorrent
    jellyfin-media-player
    bluez
    bluez-tools
  ];
}
