{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/tailscale
      ../../modules/restic-backup
      ../../modules/caddy-multi-proxy
    ];

  myTailscale.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;

  networking.hostName = "thegenerosityco"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

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

  # Set your time zone.
  time.timeZone = "America/NewYork";

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    vim
  ];

  users.users.riley = {
    isNormalUser = true;
    home = "/home/riley";
    description = "Riley Mathews";
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"
  ];


  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  system.stateVersion = "25.11"; # Did you read the comment?

  virtualisation.docker.enable = true;
  virtualisation.docker.logDriver = "json-file";
  myCaddy.proxies.komga = {
      listenHost = "thegenerosityco-production.rileymathews.com";
      backendHost = "http://127.0.0.1:8080";
  };
  services.resticBackup = {
    enable = true;
    backups.thegenerosityco-database = {
      type = "sqlite-live-copy";
      gatusHealthcheckId = "backups_thegenerosityco-production-backup";
      databases = [
        "/var/lib/thegenerosityco/database/db.sqlite3"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [80 443];
}
