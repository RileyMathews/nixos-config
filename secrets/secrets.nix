let
  # Your user SSH public key
  local = "age1zdptqyrz3qt609tuw4f2t6ffvfuu7dgxhcgn3kdhc3d4ztlq53kqnx0279";
  riley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com";
  keyDir = ./host-keys;
  hostKeyFiles = builtins.attrNames (builtins.readDir keyDir);
  pubFiles = builtins.filter (n: builtins.match ".*\\.pub" n != null) hostKeyFiles;
  hostKeyName = n: builtins.replaceStrings [".pub"] [""] n;
  hostKeysByName = builtins.listToAttrs (map (n: {
    name = hostKeyName n;
    value = builtins.readFile (keyDir + "/${n}");
  }) pubFiles);
  hostKeys = builtins.attrValues hostKeysByName;

  all = [local riley] ++ hostKeys;
in
{
  # DNS provider credentials for ACME DNS challenges
  "cloudflare-credentials.age".publicKeys = all;
  "godaddy-credentials.age".publicKeys = all;
  "tailscale-credentials.age".publicKeys = all;
  "cloudflare-api-key.age".publicKeys = all;
  "forgejo-database-password.age".publicKeys = [hostKeysByName.forgejo riley hostKeysByName."backup-server"];
  "gatus-credentials.age".publicKeys = [hostKeysByName.defiant hostKeysByName.engineering riley];
  "aws-access-key.age".publicKeys = all;
  "vaultwarden-env-file.age".publicKeys = [riley hostKeysByName.worf];
  "pg17-admin-password-file.age".publicKeys = [riley hostKeysByName."backup-server"];
  "mealie-credentials-file.age".publicKeys = [riley hostKeysByName.enterprise];
  "radicale-users.age".publicKeys = [riley hostKeysByName.enterprise];
  "immich-credentials-file.age".publicKeys = [riley hostKeysByName.yamato hostKeysByName.data hostKeysByName.immichdb];
  "karakeep-credentials-file.age".publicKeys = [riley hostKeysByName.defiant];
  "paperless-credentials-file.age".publicKeys = [riley hostKeysByName.enterprise];
  "homebox-credentials-file.age".publicKeys = [riley hostKeysByName.enterprise];
  "immich-password-file.age".publicKeys = [riley hostKeysByName."backup-server"];
  "joplin-credentials-file.age".publicKeys = [riley hostKeysByName.defiant];
  "litellm-env-file.age".publicKeys = [riley hostKeysByName.yamato];
  "vikunja-credentials-file.age".publicKeys = [riley hostKeysByName.enterprise];
  "vikunja-project-reset.age".publicKeys = [riley hostKeysByName.enterprise];
  "buffer-credentials-file.age".publicKeys = [riley hostKeysByName.defiant];
  "openwebui-credentials-file.age".publicKeys = [riley hostKeysByName.yamato];
  "pinchflat-env-file.age".publicKeys = [riley hostKeysByName.yamato];
  "homeassistant-secrets-file.age".publicKeys = [riley hostKeysByName.bridge];
  "restic-password.age".publicKeys = all;
  "forgejo-runner-token-file.age".publicKeys = [riley hostKeysByName.forgejo hostKeysByName.lab];
  "gatus-push-token.age".publicKeys = all;
  "freshrss-credentials-file.age".publicKeys = [riley hostKeysByName.defiant];
  "bookshelf-credentials-file.age".publicKeys = [riley hostKeysByName.defiant];
  "hermes-tailscale-credentials.age".publicKeys = [riley hostKeysByName.hermes];
  "hermes-cloudflare-api-key.age".publicKeys = [riley hostKeysByName.hermes];
  "hermes-cloudflare-credentials.age".publicKeys = [riley hostKeysByName.hermes];
  "hermes-dashboard-env.age".publicKeys = [riley hostKeysByName.hermes];
}
