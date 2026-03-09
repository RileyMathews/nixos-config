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
  # Cloudflare credentials for ACME DNS challenge
  "cloudflare-credentials.age".publicKeys = all;
  "tailscale-credentials.age".publicKeys = all;
  "cloudflare-api-key.age".publicKeys = all;
  "forgejo-database-password.age".publicKeys = [hostKeysByName.forgejo riley hostKeysByName."backup-server"];
  "gatus-credentials.age".publicKeys = [hostKeysByName.defiant riley];
  "karakeep-env.age".publicKeys = [hostKeysByName.borg riley hostKeysByName.defiant];
  "aws-access-key.age".publicKeys = all;
  "gatus-database-password.age".publicKeys = [riley hostKeysByName."backup-server"];
  "miniflux-env-file.age".publicKeys = [riley hostKeysByName.discovery];
  "vaultwarden-env-file.age".publicKeys = [riley hostKeysByName.worf];
  "pg17-admin-password-file.age".publicKeys = [riley hostKeysByName."backup-server"];
  "mealie-credentials-file.age".publicKeys = [riley hostKeysByName.enterprise];
  "immich-credentials-file.age".publicKeys = [riley hostKeysByName.yamato hostKeysByName.data hostKeysByName.immichdb];
  "karakeep-credentials-file.age".publicKeys = [riley hostKeysByName.discovery];
  "paperless-credentials-file.age".publicKeys = [riley hostKeysByName.enterprise];
  "homebox-credentials-file.age".publicKeys = [riley hostKeysByName.enterprise];
  "immich-password-file.age".publicKeys = [riley hostKeysByName."backup-server"];
  "joplin-credentials-file.age".publicKeys = [riley hostKeysByName.discovery];
  "vikunja-credentials-file.age".publicKeys = [riley hostKeysByName.enterprise];
  "buffer-credentials-file.age".publicKeys = [riley hostKeysByName.discovery];
  "openwebui-credentials-file.age".publicKeys = [riley hostKeysByName.yamato];
  "pinchflat-env-file.age".publicKeys = [riley hostKeysByName.yamato];
  "homeassistant-secrets-file.age".publicKeys = [riley hostKeysByName.bridge];
  "openclaw-credentials-file.age".publicKeys = [riley hostKeysByName.openclaw];
  "opecde-test-secrets-file.age".publicKeys = [riley];
  "restic-password.age".publicKeys = all;
  "forgejo-runner-token-file.age".publicKeys = [riley hostKeysByName.forgejo hostKeysByName.lab];
  "davhome-credentials-file.age".publicKeys = [riley hostKeysByName.discovery];
  "github-token-file.age".publicKeys = [riley];
  "forgejo-token-file.age".publicKeys = [riley];
  "gatus-push-token.age".publicKeys = all;
  "forgebot-credentials-file.age".publicKeys = [riley hostKeysByName.forgebot];
}
