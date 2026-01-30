{ config, pkgs, unstablePkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "auto";
      };
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      systemd.enable = true;
      luks.devices."luks-acc369d3-8fac-4a34-a4cd-b209e7710813".crypttabExtraOpts = [ "tpm2-device=auto" ];
    };

    kernelParams = [ "nvidia-drm.modeset=1" ];
  };

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "riley" ];
      keep-outputs = true;
      keep-derivations = true;
    };
  };

  networking = {
    hostName = "picard";
    wireless.iwd = {
      enable = true;
      settings = {
        IPv6.Enabled = true;
        Settings.AutoConnect = true;
      };
    };
  };

  hardware = {
    system76 = {
      firmware-daemon.enable = true;
      kernel-modules.enable = true;
      power-daemon.enable = true;
    };
    bluetooth.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
      ];
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        intelBusId  = "PCI:0:2:0";
        nvidiaBusId = "PCI:2:0:0";
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
    };
  };

  time.timeZone = "America/Chicago";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };

  services = {
    xserver = {
      xkb = {
        layout = "us";
        variant = "";
      };
      videoDrivers = [ "nvidia" "modesetting" ];
    };

    tailscale.enable = true;
    kolide-launcher.enable = true;
    pulseaudio.enable = false;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security = {
    tpm2.enable = true;
    rtkit.enable = true;
  };

  programs = {
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
    obs-studio.enable = true;
    hyprland = {
      enable = true;
      package = unstablePkgs.hyprland;
    };
    zsh.enable = true;

    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv = {
        enable = true;
      };
    };
  };

  environment = {
    etc."kolide-k2/secret" = {
      mode = "0600";
      text = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdhbml6YXRpb24iOiJuYWtvbmUiLCJraWQiOiJiODoxZDowNjo5NzpjYjo3OTpjMDo3MTpjNDoxNTpjZDo5Yzo4Mjo0MDo4NjpjYSIsImNyZWF0ZWRBdCI6IjE3MDUxMTgwMzYiLCJjcmVhdGVkQnkiOiJrd29ya2VyIn0.vCMoj_pnDjEG3Ji9y8elRzN10QfFOwGxZrJAQcJWP41SmDN1PsLQusKucX7lwUTlfgm6-9mKLnaJ9uhA-2j0G2_J2TCP9KxyvZ2M2jH4x_5muf1kV99RgwJhhjlFbZU_9ri8ZZc-fOlaaFZi6hKg5GwaaLSNTex2HKzfcx3PVdDjaXoAKc-THHgtQ9-j_4P_co7JkxxCgnsqpMw13qm2nNZ5PAE2wOuU1_MdVeNam4MnLt1BBgxbeclCHfKjrcg-H9UDcQtwiYxllsfDSpmgfNDr2b69Y064UqKAjqWyvE33c-7hBx_R2HC9glXulmdijgPgGABT1Ad6zhA6QS8xTg";
    };

    shells = with pkgs; [ zsh bash ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    systemPackages = with pkgs; [
      alacritty
      bitwarden-cli
      brave
      brightnessctl
      btop
      catppuccin-cursors.mochaDark
      curl
      dunst
      fastfetch
      ffmpeg
      fzf
      gcc
      git
      git-prole
      grim
      i3
      impala
      joplin-desktop
      jq
      just
      keyutils
      lazygit
      mesa-demos
      mpv
      nix-search-cli
      nodejs
      nvtopPackages.nvidia
      pavucontrol
      playerctl
      qutebrowser
      ripgrep
      rofi
      signal-desktop
      slack
      slurp
      spotify
      stow
      thunderbird-bin
      tldr
      tmux
      tpm2-tools
      unstablePkgs.claude-code
      unstablePkgs.hyprcursor
      unstablePkgs.neovim
      unstablePkgs.opencode
      virtualglLib
      waybar
      wl-clipboard
      xorg.xlsclients
      yt-dlp
    ];
  };

  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [ "networkmanager" "wheel" "podman" ];
    shell = pkgs.zsh;
  };
  
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
    };
  };

  fonts.packages = with pkgs; [ nerd-fonts.hack ];

  system.stateVersion = "25.05";
}

