let
  # Your user SSH public key
  riley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com";
  nixos-test = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0BPGd3sFaR0lrLuG6STXWqJHowivuXf2s02TSE/eQj root@nixos-test";
  borg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTZ+ZwdQ/Eh+qx8PLe5kPk6SYO0+Nn+V7n5WyJNO+4J root@nixos"
  all = [riley nixos-test borg];
in
{
  # Cloudflare credentials for ACME DNS challenge
  "cloudflare-credentials.age".publicKeys = all;
  "tailscale-credentials.age".publicKeys = all;
}
