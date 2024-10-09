{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../modules/vms/basic-disk-config.nix
    ./../../modules/vms/basic-hardware-config.nix
    ./../../modules/vms/basic-config.nix
    ./../../modules/caddy-single-proxy
  ];

  services.tailscale.enable = true;
  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"];
  };

  security.sudo = {
    enable = true;
    extraConfig = ''
      %wheel ALL=(ALL:ALL) NOPASSWD: ALL
    '';
  };

  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = "8000";
    };
  };

  myCaddy = {
    enable = true;
    hostName = "vaultwarden.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:8000";
  };

  environment.systemPackages = with pkgs; [
    restic
  ];

  programs.zsh.enable = true;
  networking.hostName = "vaultwarden";

  systemd.services.restic-backup = {
    description = "Restic Backup Service";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ restic bash curl];
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/var/lib/restic/env";
      ExecStart = "bash /var/lib/restic/backup.sh";
    };
  };

  systemd.timers.restic-backup = {
    description = "Restic Backup Timer";
    wants = [ "restic-backup.service" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00"; # Runs daily at 3 AM
      Persistent = true;
    };
  };
}
