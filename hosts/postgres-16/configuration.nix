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
    ./../../modules/pgBackupJobs
  ];

  services.tailscale.enable = true;
  networking.hostName = "postgres-16";
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

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    authentication = ''
      local all pgadmin peer
      local all all trust
      host all all 0.0.0.0/0 md5
    '';
    settings = {
      timezone = "UTC";
      log_timezone = "UTC";
    };
  };
  networking.firewall.allowedTCPPorts = [5432];

  programs.zsh.enable = true;

  pgBackupJobs = {
    testBackup.command = "test-backup";
    fooBackup.command = "bar-backup";
  };
}
