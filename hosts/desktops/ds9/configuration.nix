{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../shared/base.nix
      ../shared/nvidia-core.nix
    ];
  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users.riley.imports = [
      ./home.nix
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = inputs.unstablePkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;
  nix.settings = {
    substituters = [ "https://attic.xuyh0120.win/lantian" ];
    trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  networking.hostName = "ds9"; # Define your hostname.

  networking.networkmanager.enable = true;

  services.xserver.xkb.layout = "us";

  services = {
    printing.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  programs.steam = {
    enable = true;
  };

  system.stateVersion = "25.11";

}
