{ config, lib, pkgs, modulesPath, ... }:
{
    hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
    };
}
