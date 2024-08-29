{ config, pkgs, ... }:
{
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;

    virtualisation.docker = {
        enable = true;
    };

    services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
    };
}
