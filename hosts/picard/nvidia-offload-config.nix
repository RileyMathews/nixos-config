{
  config,
  pkgs,
  unstablePkgs,
  lib,
  ...
}:

{
  services.udev.extraRules = ''
    # Intel iGPU (your intelBusId is PCI:0:2:0 -> 0000:00:02.0)
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/intel-igpu"

    # NVIDIA dGPU (your nvidiaBusId is PCI:2:0:0 -> 0000:02:00.0)
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:02:00.0", SYMLINK+="dri/nvidia-dgpu"
  '';

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

  environment.sessionVariables.AQ_DRM_DEVICES =
    "/dev/dri/nvidia-dgpu:/dev/dri/intel-igpu";
  hardware = {
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:2:0:0";
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        sync = {
          enable = false;
        };
      };
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
}
