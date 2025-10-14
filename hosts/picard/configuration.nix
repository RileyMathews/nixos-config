{ config, pkgs, unstablePkgs, lib, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "picard"; # Define your hostname.
  nix.settings.trusted-users = [ "riley" ];
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    IPv6 = {
      Enabled = true;
    };
    Settings = {
      AutoConnect = true;
    };
  };

  nix.settings = {
    keep-outputs = true;
    keep-derivations = true;
  };

  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;


  time.timeZone = "America/New_York";

  programs.hyprland.enable = true;
  services.kolide-launcher.enable = true;
  environment.etc."kolide-k2/secret" = {
    mode = "0600";
    text = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdhbml6YXRpb24iOiJuYWtvbmUiLCJraWQiOiJiODoxZDowNjo5NzpjYjo3OTpjMDo3MTpjNDoxNTpjZDo5Yzo4Mjo0MDo4NjpjYSIsImNyZWF0ZWRBdCI6IjE3MDUxMTgwMzYiLCJjcmVhdGVkQnkiOiJrd29ya2VyIn0.vCMoj_pnDjEG3Ji9y8elRzN10QfFOwGxZrJAQcJWP41SmDN1PsLQusKucX7lwUTlfgm6-9mKLnaJ9uhA-2j0G2_J2TCP9KxyvZ2M2jH4x_5muf1kV99RgwJhhjlFbZU_9ri8ZZc-fOlaaFZi6hKg5GwaaLSNTex2HKzfcx3PVdDjaXoAKc-THHgtQ9-j_4P_co7JkxxCgnsqpMw13qm2nNZ5PAE2wOuU1_MdVeNam4MnLt1BBgxbeclCHfKjrcg-H9UDcQtwiYxllsfDSpmgfNDr2b69Y064UqKAjqWyvE33c-7hBx_R2HC9glXulmdijgPgGABT1Ad6zhA6QS8xTg";
  };

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.tailscale.enable = true;

  # services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.zsh.enable = true;
  environment.shells = with pkgs; [zsh bash];

  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [nerd-fonts.hack];

  environment.systemPackages = with pkgs; [
    git
    dunst
    alacritty
    rofi-wayland
    brave
    curl
    git
    git-prole
    neovim
    fastfetch
    pavucontrol
    zsh
    bash
    slack
    i3
    stow
    gcc
    fzf
    tmux
    direnv
    impala
    nix-direnv
    unstablePkgs.neovim
    just
    hyprland
    waybar
    signal-desktop
    wl-clipboard
    grim
    slurp
    virtualglLib
    mesa-demos
    btop
  ];

  services.xserver.videoDrivers = ["nvidia" "modesetting"];

  hardware.nvidia = {
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

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
