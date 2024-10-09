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
    extraGroups = [ "networkmanager" "wheel"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"];
  };

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.rileymathews.com";
      upstream-base-url = "https://ntfy.sh";
      listen-http = ":8000";
    };
  };

  myCaddy = {
    enable = true;
    hostName = "ntfy.rileymathews.com";
    reverseProxyAddress = "127.0.0.1:8000";
  };

  programs.zsh.enable = true;
  networking.hostName = "ntfy";
}
