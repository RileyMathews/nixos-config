{ config, pkgs, inputs, ... }:

{
  boot = {
    initrd = {
      kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
    };
    kernelParams = [ "nvidia-drm.modeset=1" ];
  };
  hardware = {
    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };

  services = {
    xserver = {
      videoDrivers = [
        "nvidia"
        "modesetting"
      ];
    };
  };

  environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];

  system.stateVersion = "25.11";
}
