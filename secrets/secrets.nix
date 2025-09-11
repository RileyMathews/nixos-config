let
  # Your user SSH public key
  riley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com";
  nixos-test = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0BPGd3sFaR0lrLuG6STXWqJHowivuXf2s02TSE/eQj root@nixos-test";
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTZ+ZwdQ/Eh+qx8PLe5kPk6SYO0+Nn+V7n5WyJNO+4J root@nixos";
  pg17 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILvOTkyp4FxnjriR+Y3E25kaBKdtXWekYph3m9SWSzLX root@nixos";
  playground = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEdaKF4qDveUOE7EDKQl5hwUfTh1lPkfpuhnAZVRZM58 root@nixos-playground";
  all = [riley nixos-test borg pg17 playground];
in
{
  # Cloudflare credentials for ACME DNS challenge
  "cloudflare-credentials.age".publicKeys = all;
  "tailscale-credentials.age".publicKeys = all;
  "cloudflare-api-key.age".publicKeys = all;
  "forgejo-database-password.age".publicKeys = all;
}
