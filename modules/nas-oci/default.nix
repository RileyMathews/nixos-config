{ lib, config, ... }:

let
  cfg = config.services.nasOci;

  defaultNfsOptions = [
    "vers=4.2"
    "proto=tcp"
    "_netdev"
    "nofail"

    "x-systemd.automount"
    "x-systemd.idle-timeout=60"
    "x-systemd.mount-timeout=30s"
    "x-systemd.device-timeout=10s"

    # Resilience: errors instead of indefinite hangs
    "soft"
    "timeo=600"
    "retrans=2"
  ];

  # All mountPoints declared under services.nasOci.mounts
  mountPoints =
    map (m: m.mountPoint) (lib.attrValues cfg.mounts);

  # Extract host path from a volume spec like "/mnt/foo/bar:/container/path:rw"
  hostPathFromVolume = vol:
    let
      s = toString vol;
      parts = lib.splitString ":" s;
    in
      if parts == [] then null else lib.elemAt parts 0;

  # Is host path under mountpoint (exact mountpoint or mountpoint + "/...")
  isUnder = mp: hp:
    hp != null && (hp == mp || lib.hasPrefix (mp + "/") hp);

  # Compute which mountPoints a container uses by scanning its volumes
  mountsForContainer = c:
    let
      vols = c.definition.volumes or [];
      hostPaths = lib.filter (p: p != null) (map hostPathFromVolume vols);
      used = lib.filter (mp: lib.any (hp: isUnder mp hp) hostPaths) mountPoints;
    in
      lib.unique (used ++ (c.extraMounts or [])); # allow manual add-ons

in
  {
  options.services.nasOci = {
    enable = lib.mkEnableOption "NAS mounts + OCI containers with automatic ordering/deps";

    nfsOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = defaultNfsOptions;
      description = "Default mount options applied to all mounts (unless overridden per mount).";
    };

    mounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          mountPoint = lib.mkOption {
            type = lib.types.str;
            description = "Local mount point, e.g. /mnt/mealie";
          };

          device = lib.mkOption {
            type = lib.types.str;
            description = "NFS device string, e.g. nas:/mealie (with /main as fsid=0 root export).";
          };

          fsType = lib.mkOption {
            type = lib.types.str;
            default = "nfs";
          };

          options = lib.mkOption {
            type = lib.types.nullOr (lib.types.listOf lib.types.str);
            default = null;
            description = "Optional per-mount override; null => use global nfsOptions.";
          };
        };
      }));
      default = {};
    };

    containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
        options = {
          definition = lib.mkOption {
            type = lib.types.attrs;
            description = "The oci-containers definition for this container.";
          };

          # Optional escape hatch: add mountpoints that aren't detectable from volumes
          extraMounts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional mount points to require (rare). Usually empty.";
          };

          restart = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
        };
      }));
      default = {};
    };

    extraDepends = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "tailscale-ready.service" "run-agenix.d.mount" "network.target" ];
      description = "Units every container will require/after (even if redundant).";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelModules = [ "nfs" ];
    boot.supportedFilesystems = [ "nfs" ];

    fileSystems = lib.mkMerge (map
      (m: {
        "${m.mountPoint}" = {
          device = m.device;
          fsType = m.fsType;
          options = if m.options == null then cfg.nfsOptions else m.options;
        };
      })
      (lib.attrValues cfg.mounts));

    virtualisation.oci-containers.containers =
      lib.mapAttrs (_: c: c.definition) cfg.containers;

    systemd.services =
      lib.mapAttrs'
      (name: c:
        let
          svcName = "podman-${name}";
          requiredMountPoints = mountsForContainer c;
        in {
          name = svcName;
          value = {
            unitConfig = {
              RequiresMountsFor = requiredMountPoints;
              Wants = cfg.extraDepends;
              After = cfg.extraDepends;
            };

            serviceConfig = lib.mkIf c.restart {
              Restart = "always";
              RestartSec = "5s";
            };
          };
        }
      )
      cfg.containers;
  };
}

