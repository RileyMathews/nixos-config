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
  ];

  users.users.riley = {
    isNormalUser = true;
    description = "Riley Mathews";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"];
  };

  programs.zsh.enable = true;

  services.rabbitmq.enable = true;
  services.rabbitmq.listenAddress = "0.0.0.0";

  services.tailscale.enable = true;
  networking.firewall.allowedTCPPorts = [5672];

  networking.hostName = "rabbitmq";
}
