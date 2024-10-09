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
  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"];
  };

  # virtualisation.docker = {
  #   enable = true;
  #   enableOnBoot = true;
  # };

  virtualisation.oci-containers.containers."whoami" = {
    image = "containous/whoami";
    ports = ["8000:80"];
  };

  myCaddy = {
    enable = true;
    hostName = "debug.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:8000";
  };

  programs.zsh.enable = true;

  services.backup = {
    enable = true;
  };
}
