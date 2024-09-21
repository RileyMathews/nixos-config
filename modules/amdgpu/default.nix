{ config, pkgs, ... }:
{
    services.xserver.videoDrivers = ["amdgpu"];
    nixpkgs.config.rocmSupport = true;
}
