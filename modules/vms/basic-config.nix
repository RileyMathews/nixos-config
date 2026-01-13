{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;
  services.qemuGuest.enable = true;

  environment.systemPackages = with pkgs; [
    zsh
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"
  ];

  users.groups.riley = { gid = 1000; };

  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [ "networkmanager" "wheel" "docker" "podman"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    group = "riley";
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"];
  };
  nix.settings.trusted-users = [ "root" "riley" ];
  programs.zsh.enable = true;

  security.sudo = {
    enable = true;
    extraConfig = ''
      %wheel ALL=(ALL:ALL) NOPASSWD: ALL
    '';
  };

  # Garbage collect daily, keep only 7 days of generations
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # Deduplicate the store weekly
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # Keep only 3 most recent generations per profile
  # (runs after garbage collection)
  nix.settings.keep-outputs = false;
  nix.settings.keep-derivations = false;

  # Tight journal limits
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=20M
    MaxRetentionSec=1week
  '';

  # do not include enable here.
  # individual hosts should
  # enable podman on their own
  virtualisation.podman = {
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
  };
  services.prometheus = {
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
  };

  networking.firewall.allowedTCPPorts = [9002];

  system.stateVersion = "25.11";
}
