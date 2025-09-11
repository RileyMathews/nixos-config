let
  # Your user SSH public key
  riley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com";
  nixos-test = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0BPGd3sFaR0lrLuG6STXWqJHowivuXf2s02TSE/eQj root@nixos-test";
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTZ+ZwdQ/Eh+qx8PLe5kPk6SYO0+Nn+V7n5WyJNO+4J root@nixos";
  pg17 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILvOTkyp4FxnjriR+Y3E25kaBKdtXWekYph3m9SWSzLX root@nixos";
  playground = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVaKFUEABrVlZPcJqx+nanZ4R/1r46AT4fMqbEnry4v root@nixos";
  all = [riley nixos-test borg pg17 playground];
in
{
  # Cloudflare credentials for ACME DNS challenge
  "cloudflare-credentials.age".publicKeys = all;
  "tailscale-credentials.age".publicKeys = all;
}
