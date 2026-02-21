# NixOS Configuration - Agent Guidelines

This is my nix configuration repository. It serves many purposes. The main one being to deploy configurations to my fleet of homelab VMs living on a proxmox host.

Every configuration is exported as a flake output from the top level `flake.nix` file.

The majority of these outputs are configurations for my VMs but there are two desktop computers.

I make use of tailscale for my hosts. The flake output names match 1 to 1 with the host name of the machine that config is used by.
If you ever need to ssh into a host for diagnostic purposes you can do so with its tailscale name. Example: `ssh enterprise`.

# Nixos module layout
The overall file layout I try to stick with here is that hosts are defined in the `flake.nix` file and import a single entrypoint that lives
at `./hosts/<hostname>/configuration.nix`. The hosts `configuration.nix` file may declare some things that are truly specific to that VM
but for the most part we try to make shareable modules in the `./modules` directory. The vast majority of the modules there are just
modules that setup a containerized application but there are some other ones as well for other host level services i.e. postgres, nginx, caddy, redis etc...

# Homelab
My homelab consists of two physical machines.
- shipyard: the proxmox host
- nas: a network attached storage machine with a large zfs pool.

`shipyard` is where most of the magic happens. Its VMs run everything from containerized applications as well as some VMs with host level services such as
postgres and redis which are used by the applications.

If a flake output is marked as a `VM` deployment it lives on the shipyard proxmox host as a VM.

## Troubleshooting homelab hosts
If you ever need to troubleshoot by collecting logs from VMs you can do so by running systemctl/journalctl over ssh.
The VMs also make heavy use of podman so you can also fetch podman logs in this way.
My ssh key also has direct access to the root account on the Nixos VMs so if needed you can also `ssh root@<host> ...` to troubleshoot things.
When troubleshooting and you want to make changes, prefer to make them declaritavely in the nixos config rather than by one off commands on the hosts.

The `nas` host is a little different. It runs debian as its bare metal OS and basically just serves as a thin host to serve NFS exports to
some of my VMs that have storage hungry apps like immich and jellyfin. You do not have direct root access on `nas`.

# Desktops

## picard
`picard` is a System76 Bonobo WS 15 laptop running nixos. Everything about its configuration is declared inline here. It doesn't share any modules with my VMs and is mostly
on its own. It does consume a home manager module that is shared with my desktop.

## ds9
`ds9` is my gaming PC that runs archlinux. It's only declared here to export a home manager module so that I can share my dotfiles between my hosts via home manager.

