{
  config,
  pkgs,
  unstablePkgs,
  lib,
  pr-tracker,
  agenix,
  opencode,
  worktrunk,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia-offload-config.nix
  ];
  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = {
      system = "x86_64-linux";
    };
  };

  environment.variables = {
    GHC_JOBS = "16";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "auto";
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };

    kernel = {
      sysctl = {
        "vm.swappiness" = 10;
        "vm.max_map_count" = 2622144;
        "fs.inotify.max_user_watches" = 524288;
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
      };
    };

    tmp = {
      useTmpfs = true;
      tmpfsSize = "50%";
    };

    initrd = {
      systemd.enable = true;
      luks.devices."luks-acc369d3-8fac-4a34-a4cd-b209e7710813".crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
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
    };
    bluetooth.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        libvdpau-va-gl
      ];
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
    scx = {
      enable = true;
      scheduler = "scx_bpfland";
    };
    xserver = {
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    fwupd.enable = true;

    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    '';

    power-profiles-daemon.enable = true;
    thermald.enable = true;

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
    wrappers = {
      "btop-perf" = {
        owner = "root";
        group = "root";
        capabilities = "cap_perfmon+ep";
        source = "${pkgs.btop}/bin/btop";
      };
    };
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "yourUsernameHere" ];
    };
    niri.enable = true;
    firefox.enable = true;
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

    shells = with pkgs; [
      zsh
      bash
    ];

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    systemPackages = with pkgs; [
      alacritty
      bitwarden-cli
      brave
      brightnessctl
      btop-cuda
      catppuccin-cursors.mochaDark
      sqlite
      curl
      dunst
      fastfetch
      ffmpeg
      forgejo-cli
      fzf
      gcc
      gh
      ghostty
      git
      tree-sitter
      kitty
      wezterm
      git-prole
      google-chrome
      grim
      i3
      impala
      joplin-desktop
      jq
      just
      keyutils
      lazygit
      libnotify
      librewolf
      luajitPackages.lua-lsp
      mesa-demos
      mpv
      nix-search-cli
      nodejs
      pavucontrol
      playerctl
      worktrunk.packages.${pkgs.system}.worktrunk
      podman-compose
      python3
      qutebrowser
      ripgrep
      rofi
      signal-desktop
      skopeo
      slack
      slurp
      spotify
      stow
      thunderbird-bin
      tldr
      tmux
      tpm2-tools
      opencode.packages.${pkgs.system}.opencode
      unstablePkgs.claude-code
      unstablePkgs.hyprcursor
      unstablePkgs.neovim
      virtualglLib
      waybar
      wl-clipboard
      wlr-which-key
      xorg.xlsclients
      yt-dlp
    ];
  };

  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [
      "networkmanager"
      "wheel"
      "podman"
      "video"
    ];
    shell = pkgs.zsh;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.riley = {
      imports = [
        ../../../modules/home-manager/riley
        pr-tracker.homeManagerModules.default
        agenix.homeManagerModules.default
      ];
      riley.browser = "google-chrome-stable";
      riley.opencode.profile = "work";
      services.pr-tracker-sync.enable = true;
    };
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
