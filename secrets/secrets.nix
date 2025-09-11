let
  # Your user SSH public key
  riley = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgBrMhlYyFQuzLE2dEIJ/vEEN769EiPrpKYVzBKERoe rileymathews80@gmail.com";
  nixos-test = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0BPGd3sFaR0lrLuG6STXWqJHowivuXf2s02TSE/eQj root@nixos-test";
  all = [riley nixos-test];
in
{
  # Cloudflare credentials for ACME DNS challenge
  "cloudflare-credentials.age".publicKeys = all;
  "tailscale-credentials.age".publicKeys = all;

}
