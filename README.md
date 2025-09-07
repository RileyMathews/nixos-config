# NixOS Config

I tried reviving this old config for my homelab but ran into issues due to being away and trying to do everything over tailscale. Here are some notes to help me try this again once I'm home.

I need to bootstrap an initial nixos state using nixos anywhere. However this is difficult to do over tailscale as it requires rebooting the system during the process. I should follow this quickstart guide to try this again once I am home and can work over LAN ip addresses.

https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md

Then once the VM is initially provisioned I should be able to do further updates to the system with
```
nix run nixpkgs#nixos-rebuild -- switch --flake .#<flake name> --target-host <hostname>
```

Another thing I could try to do is manually setting up a 'bootstraping' VM manually in proxmox via its VM console and then use that VM to run these commands. But that might have to wait for another day to go through that slog.
