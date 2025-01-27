{ config, pkgs, ... }:

{
  # Basic Home Manager Configuration
  home = {
    username = "jake";
    homeDirectory = "/home/jake";
    stateVersion = "25.05";

    # Session Variables
    sessionVariables = {
      EDITOR = "nvim";
    };

   # User Packages
packages = with pkgs; [
  # Media and Entertainment
  discord  # removed duplicate
  anime4k
  jellyfin-media-player
  qbittorrent  # removed duplicate

  # System Tools
  chromium

  # Fonts
  nerd-fonts.jetbrains-mono


];
};

  # Package Management
  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

  # Font Configuration
  fonts.fontconfig.enable = true;

  # XDG Configuration
  xdg.enable = true;

  # Media Player Configuration
  programs.mpv = {
    enable = true;
    package = pkgs.mpv.override {
      scripts = [ pkgs.mpvScripts.mpris ];
    };
    config = {
      # Video Quality Settings
      profile = "gpu-hq";
      scale = "ewa_lanczossharp";
      cscale = "ewa_lanczossharp";
      video-sync = "display-resample";
      interpolation = true;
      tscale = "oversample";

      # Subtitle Configuration
      sub-auto = "fuzzy";
      sub-bold = "yes";
      sub-font = "Noto Sans";
      sub-font-size = 48;

      # Video Processing
      deband = true;
      deband-iterations = 2;
      deband-threshold = 35;
      deband-range = 20;
      deband-grain = 5;

      # Hardware and GPU Settings
      vo = "gpu";
      hwdec = "vaapi";
      gpu-api = "auto";
      fbo-format = "rgba16hf";
      hwdec-codecs = "all";
      gpu-dumb-mode = "no";
      gpu-context = "wayland";

      # Media Handling
      screenshot-format = "png";
      screenshot-png-compression = 9;
      screenshot-directory = "~/Pictures/mpv";

      # Cache Configuration
      cache = "yes";
      cache-secs = 300;
      demuxer-max-bytes = "500MiB";
      demuxer-max-back-bytes = "250MiB";

      # Performance Settings
      hr-seek-framedrop = "no";
      framedrop = "vo";

      # Shader Configuration
      glsl-shaders = [
        "~~/shaders/Anime4K_Clamp_Highlights.glsl"
        "~~/shaders/Anime4K_Restore_CNN_VL.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x2.glsl"
        "~~/shaders/Anime4K_AutoDownscalePre_x4.glsl"
        "~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"
      ];
    };
  };

  # Terminal Configuration
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = {
          x = 10;
          y = 10;
        };
        opacity = 0.95;
        decorations = "none";
      };

      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "JetBrainsMono Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "JetBrainsMono Nerd Font";
          style = "Italic";
        };
        size = 12;
      };

      colors = {
        primary = {
          background = "#1a1f25";
          foreground = "#e6e6e8";
        };
        normal = {
          black = "#20262c";
          red = "#ff6d7e";
          green = "#5cdba3";
          yellow = "#e3d367";
          blue = "#70d7ff";
          magenta = "#7eb7e6";
          cyan = "#4fd6d6";
          white = "#c7c8d1";
        };
        bright = {
          black = "#2c333b";
          red = "#ff8a98";
          green = "#67f0b6";
          yellow = "#f4e47e";
          blue = "#8ce2ff";
          magenta = "#93cfff";
          cyan = "#62efef";
          white = "#e6e6e8";
        };
      };

      cursor = {
        style = {
          shape = "Beam";
          blinking = "On";
        };
        blink_interval = 750;
        unfocused_hollow = true;
      };
    };
  };

  # Development Tools Configuration
  programs.git = {
    enable = true;
    userName = "jake";
    userEmail = "";
  };

  # Shell Configuration
  programs.bash = {
    enable = true;
    shellAliases = {
     smm = "cd $HOME/nixos-config && sudo nixos-rebuild switch --flake .#nixos && cd -";

     hm = "home-manager switch";
    };
  };

  # Browser Configuration
  programs.firefox = {
    enable = true;
  };
}
