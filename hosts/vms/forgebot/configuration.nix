{
  modulesPath,
  lib,
  pkgs,
  unstablePkgs,
  config,
  forgebot,
  ...
}:
{
  imports = [
    ./../../../modules/vms/basic-disk-config.nix
    ./../../../modules/vms/basic-hardware-config.nix
    ./../../../modules/vms/basic-config.nix
    ./../../../modules/tailscale
    forgebot.nixosModules.forgebot
  ];
  networking.hostName = "forgebot";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  myTailscale.enable = true;
  age.secrets.forgebot-credentials-file = {
      file = ../../../secrets/forgebot-credentials-file.age;
  };

  services.forgebot = {
    enable = true;
    
    forgejo.url = "https://git.rileymathews.com";
    secretsFilePath = config.age.secrets.forgebot-credentials-file.path;
  };
}
