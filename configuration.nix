{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Core System Configuration
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Boot and Hardware Configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Graphics and GPU Configuration
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
          amdvlk

          rocmPackages.rocm-smi
          rocmPackages.rocminfo
          vulkan-loader
          vulkan-tools
          vulkan-validation-layers
          glxinfo


      libvdpau
      mesa.drivers



      libva
      libva-utils
      rocmPackages.clr
      rocmPackages.rocm-runtime
      ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General.Enable = "Source,Sink,Media,Socket";
    };
    steam-hardware.enable = true;
    opengl = {
      enable = true;
      extraPackages = with pkgs; [

        amdvlk
      ];
    };
  };

  # Display Server and Desktop Environment
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    xkb = {
      layout = "au";
      variant = "";
    };
  };
  services.displayManager = {
    sddm.enable = true;
    autoLogin = {
      enable = true;
      user = "jake";
    };
  };
  services.desktopManager.plasma6.enable = true;

  # Audio Configuration
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;

  # File Systems
  fileSystems = {
    "/mnt/media" = {
      device = "/dev/disk/by-uuid/5d1c0983-80d2-4473-a0c0-4068391ebd05";
      fsType = "btrfs";
      options = [ "defaults" "nofail" "compress=zstd" "x-systemd.automount" ];
    };
    "/mnt/games" = {
      device = "/dev/disk/by-uuid/12AC38D937E36F2B";
      fsType = "ntfs";
      options = [ "defaults" "nofail" "uid=1000" "gid=100" "umask=002" ];
    };
    "/mnt/stuff" = {
      device = "/dev/disk/by-uuid/de462ad8-f282-4831-92e9-9ce0949d761f";
      fsType = "btrfs";
      options = [ "defaults" "nofail" "compress=zstd" "x-systemd.automount" ];
    };
    "/mnt/stuff16tb" = {
      device = "/dev/disk/by-uuid/74a59ea5-5267-42b5-89f2-5d92bee3f28b";
      fsType = "btrfs";
      options = [ "defaults" "compress=zstd" "nofail" "noauto" ];
    };
  };

  # Mount Service Configuration
  systemd.services.delayed-stuff16tb-mount = {
    description = "Mount 16TB drive after desktop";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.util-linux}/bin/mount /mnt/stuff16tb";
    };
    after = [ "plasma-workspace.service" "network.target" ];
    wants = [ "plasma-workspace.service" ];
    wantedBy = [ "multi-user.target" ];
    enable = true;
  };

  services.jellyfin = {
  enable = true;
  user = "jellyfin";
  group = "jellyfin";

  };


systemd.tmpfiles.rules = [
  "d /var/cache/jellyfin 0755 jellyfin jellyfin -"
  "d /var/cache/jellyfin/transcodes 0755 jellyfin jellyfin -"
  "d /var/lib/jellyfin 0755 jellyfin jellyfin -"
  "d /var/lib/jellyfin/config 0755 jellyfin jellyfin -"
];
 systemd.services.jellyfin = {
  serviceConfig = {
    SupplementaryGroups = [ "video" "render" ];
    BindPaths = [
      "/mnt/stuff:/mnt/stuff"
      "/mnt/stuff16tb:/mnt/stuff16tb"
      "/run/opengl-driver:/run/opengl-driver"
      "/var/lib/jellyfin:/var/lib/jellyfin"
    ];
    DeviceAllow = [
      "/dev/dri/renderD128 rw"
      "/dev/dri/card0 rw"
    ];
    Environment = [
      "LIBVA_DRIVER_NAME=radeonsi"  # Add this line
      "LIBVA_DRIVERS_PATH=${pkgs.mesa.drivers}/lib/dri"  # And this line
    ];
  };
  after = [ "network.target" "mnt-stuff.mount" "delayed-stuff16tb-mount.service" ];
  requires = [ "mnt-stuff.mount" "delayed-stuff16tb-mount.service" ];
};
  # Virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };

  # Networking and Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8096 ];
  };

  # User and Group Configuration
  users = {
    users.jake = {
      isNormalUser = true;
      description = "jake";
      extraGroups = [ "networkmanager" "wheel" "input" "bluetooth" "gamepad" ];
      packages = with pkgs; [ kdePackages.kate ];
    };
    users.jellyfin = {
      isSystemUser = true;
      group = "jellyfin";
      home = "/var/lib/jellyfin";
    };
    groups = {
      jellyfin = {};
      video.members = [ "jellyfin" "jake" ];
      render.members = [ "jellyfin" "jake" ];
    };
    extraGroups.libvirtd.members = [ "jake" ];
  };

  # Programs and Services
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };

  services = {
    printing.enable = true;
    blueman.enable = true;
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    # Core Tools
    neovim
    wget
    git
    home-manager

    # System Utilities
    ntfs3g
    gnome-boxes

    # Bluetooth Support
    bluez
    bluez-tools
    bluez-alsa
    input-remapper
  ];

  # Localization and Time
  time.timeZone = "Australia/Perth";
  i18n = {
    defaultLocale = "en_AU.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_AU.UTF-8";
      LC_IDENTIFICATION = "en_AU.UTF-8";
      LC_MEASUREMENT = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
      LC_NAME = "en_AU.UTF-8";
      LC_NUMERIC = "en_AU.UTF-8";
      LC_PAPER = "en_AU.UTF-8";
      LC_TELEPHONE = "en_AU.UTF-8";
      LC_TIME = "en_AU.UTF-8";
    };
  };
}

