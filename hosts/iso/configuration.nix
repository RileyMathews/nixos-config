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

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.git
    pkgs.neovim
    pkgs.fastfetch
  ];

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com"
  ];

  system.stateVersion = "24.05";
}

