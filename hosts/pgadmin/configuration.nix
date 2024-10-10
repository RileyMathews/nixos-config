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
    ./../../modules/backup
  ];

  services.tailscale.enable = true;
  networking.hostName = "pgadmin";
  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [ "networkmanager" "wheel" ];
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

  services.pgadmin.enable = true;
  services.pgadmin.initialEmail = "dev@rileymathews.com";
  services.pgadmin.initialPasswordFile = "/home/riley/pgpass";

  myCaddy = {
    enable = true;
    hostName = "pgadmin.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:5050";
  };

  programs.zsh.enable = true;
}
