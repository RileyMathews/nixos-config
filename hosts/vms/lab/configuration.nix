{
  config,
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/vms/swap-config.nix
    ./../../../modules/tailscale
    ./../../../modules/dozzle/agent.nix
  ];
  networking.hostName = "lab";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  myTailscale.enable = true;

  programs.ssh.knownHosts.defiant.publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYRmmjMCzfaKZv3A9z5Q6MAiE9Xxnel3ScWcmPoMOYC";

  users.groups.gitea-runner = { };
  users.users.gitea-runner = {
    isSystemUser = true;
    group = "gitea-runner";
    home = "/var/lib/gitea-runner/forgejo";
  };

  age.secrets.forgejo-runner-token-file = {
    file = ../../../secrets/forgejo-runner-token-file.age;
    mode = "0400";
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.forgejo = {
      enable = true;
      name = "forgejo-runner-lab-01";
      url = "https://git.rileymathews.com";
      tokenFile = config.age.secrets.forgejo-runner-token-file.path;
      labels = [
        "homelab-coordinator:host"
      ];
      hostPackages = with pkgs; [
        bash
        coreutils
        curl
        gawk
        gitMinimal
        gnused
        nodejs
        openssh
        pnpm
        wget
        rsync
      ];
      settings = {
        runner.capacity = 1;
        cache.enable = true;
      };
    };
  };

  systemd.services.forgejo-runner-ssh-key = {
    description = "Create the Forgejo runner SSH identity";
    before = [ "gitea-runner-forgejo.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "gitea-runner";
      UMask = "0077";
    };
    script = ''
      key_dir=/var/lib/gitea-runner/forgejo/.ssh

      # State created by the module's former DynamicUser is owned by nobody
      # after systemd migrates it to the static runner account.
      ${pkgs.coreutils}/bin/chown -R gitea-runner:gitea-runner /var/lib/gitea-runner
      ${pkgs.coreutils}/bin/install -d -m 0700 \
        -o gitea-runner -g gitea-runner "$key_dir"

      if [ ! -e "$key_dir/id_ed25519" ]; then
        ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -N "" \
          -C "forgejo-runner@lab" -f "$key_dir/id_ed25519"
      elif [ ! -e "$key_dir/id_ed25519.pub" ]; then
        ${pkgs.openssh}/bin/ssh-keygen -y -f "$key_dir/id_ed25519" \
          > "$key_dir/id_ed25519.pub"
      fi

      ${pkgs.coreutils}/bin/chown gitea-runner:gitea-runner \
        "$key_dir/id_ed25519" "$key_dir/id_ed25519.pub"
    '';
  };

  systemd.services.gitea-runner-forgejo = {
    after = [
      "forgejo-runner-ssh-key.service"
      "run-agenix.d.mount"
    ];
    requires = [
      "forgejo-runner-ssh-key.service"
      "run-agenix.d.mount"
    ];
    unitConfig.RequiresMountsFor = [ config.age.secrets.forgejo-runner-token-file.path ];
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "gitea-runner";
      Group = "gitea-runner";
    };
  };
}
