{ config, lib, ... }:

let
  cfg = config.mySwap;
in
{
  options.mySwap = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable swap + zram defaults for VMs.";
    };

    zramPercent = lib.mkOption {
      type = lib.types.int;
      default = 25;
      description = "Percentage of RAM to allocate to zram.";
    };

    zramPriority = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "zram swap priority.";
    };

    swapFile = lib.mkOption {
      type = lib.types.str;
      default = "/swapfile";
      description = "Swap file path.";
    };

    swapSize = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = "Swap size in MiB.";
    };

    swapPriority = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Swap file priority.";
    };

    swappiness = lib.mkOption {
      type = lib.types.int;
      default = 15;
      description = "vm.swappiness value.";
    };
  };

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      memoryPercent = cfg.zramPercent;
      priority = cfg.zramPriority;
    };

    swapDevices = lib.mkIf (cfg.swapSize > 0) [
      {
        device = cfg.swapFile;
        size = cfg.swapSize;
        priority = cfg.swapPriority;
      }
    ];

    boot.kernel.sysctl."vm.swappiness" = cfg.swappiness;
  };
}
