let
  # Your user SSH public key
  riley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com";
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0BPGd3sFaR0lrLuG6STXWqJHowivuXf2s02TSE/eQj root@nixos-test";
  pg17 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILvOTkyp4FxnjriR+Y3E25kaBKdtXWekYph3m9SWSzLX root@nixos";
  playground = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEdaKF4qDveUOE7EDKQl5hwUfTh1lPkfpuhnAZVRZM58 root@nixos-playground";
  forgejo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKaNVYYQM1GrTxmROiI82gPlhYO3WOddhak9ks6NhvRu root@forgejo";
  backup-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICIHJHoXMk2fQ7UkPXrYiRMFTmRX842UgJl88WKLya6H root@backup-server";
  defiant = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHYRmmjMCzfaKZv3A9z5Q6MAiE9Xxnel3ScWcmPoMOYC root@defiant";
  worf = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN44i6nHrXX1TFfNeQleNFl789qw7elL9afiTMTqX5k1 root@nixos-playground";
  discovery = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGZ0qHOcH0XH0ZsU3cBwGnN40BwbWZKUwcb4tjFFwLtL root@discovery";
  relay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKX/AOKzEh71NxQqzgMgDDOEbfVq9h/pP4GFDTPkHkZS root@relay";
  bridge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdVIhED8NhLRMlebU5qn353+NIMFQF28qsYZ7eSruQx root@bridge";
  couchdb = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMnQnRAy24MnQ03KSajKqYm085+TxmpJqvRQ5b581BM1 root@couchdb";
  data = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEU1lucp6jkoONSvMbz0ds4N3rYhuT02uwXMkTZKHHQD root@data";
  redis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQ/lz7yITSSPMq2ph0tcGpNs89b+yUurCVhJu2QJbMx root@redis";
  engineering = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxkcMdBd1XreDuoL6Rqm1z1+33oLNixRWZJ0dz6+2Xq root@engineering";
  all = [riley borg pg17 playground forgejo backup-server defiant worf discovery relay bridge couchdb data redis engineering];
in
{
  # Cloudflare credentials for ACME DNS challenge
  "cloudflare-credentials.age".publicKeys = all;
  "tailscale-credentials.age".publicKeys = all;
  "cloudflare-api-key.age".publicKeys = all;
  "forgejo-database-password.age".publicKeys = [forgejo riley backup-server];
  "gatus-credentials.age".publicKeys = [defiant riley];
  "karakeep-env.age".publicKeys = [borg riley defiant];
  "aws-access-key.age".publicKeys = [riley backup-server];
  "gatus-database-password.age".publicKeys = [riley backup-server];
  "miniflux-env-file.age".publicKeys = [riley discovery];
  "vaultwarden-env-file.age".publicKeys = [riley worf];
  "pg17-admin-password-file.age".publicKeys = [riley backup-server];
  "mealie-credentials-file.age".publicKeys = [riley discovery];
  "immich-credentials-file.age".publicKeys = [riley discovery data];
  "karakeep-credentials-file.age".publicKeys = [riley discovery];
  "paperless-credentials-file.age".publicKeys = [riley discovery];
  "homebox-credentials-file.age".publicKeys = [riley discovery];
  "immich-password-file.age".publicKeys = [riley backup-server];
  "joplin-credentials-file.age".publicKeys = [riley discovery];
}
