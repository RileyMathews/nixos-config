# Server management repository

This is my server management repository. It helps me manage a fleet of servers that are a mix of proxmox VMs, bare metal servers, and cloud VMs.

Most of my VMs are running nixos and that is what the majority of this repository is dedicated to managing. There are a few exceptions however which will
be called out below.

# Nixos module layout
The overall file layout I try to stick with here is that VM hosts are discovered from `./hosts/vms/<hostname>/configuration.nix`.
Host `configuration.nix` files may declare some things that are truly specific to that machine
but for the most part we try to make shareable modules in the `./modules` directory. The vast majority of the modules there are just
modules that setup a containerized application but there are some other ones as well for other host level services i.e. postgres, nginx, caddy, redis etc...

# Machines
These are the physical machines that I run in my home.

## shipyard
Shipyard is a proxmox host that runs on an old gaming PC.
Most of my VMs live here. As much as possible I try to run most application workloads on a VM on this machine with a few exceptions discussed later.

## nas
this is a small nas machine that runs on a FriendlyElec CM3588. It has an ARM cpu which means that its images cannot be built on most of my x86 powered workstations.
For this reason the justfile has a dedicated recipe for deploying the nas that runs the build on the nas itself.

The NAS has zfs running on some NVME drives that has ZFS pools for some more data heavy applications that are mounted to VMs over NFS.
It also runs a postgres 18 server that I am slowly trying to migrate apps to.

# VMs
The following is a list of the VMs I currently run and their purpose for context when working with them as well as any specific rules you should follow when working with them.

## enterprise
enterprise is a proxmox VM that runs 'mission critical' applications that are used by more people than just me. Be extremely careful when working on this server.
Other than that it is a pretty standard deployment running containerized applications.

## data
data is a proxmox VM that has an Nvidia gtx 1080 attached for CUDA workflows. It runs a handful of small ML applications like immich ML.

## yamato
yamato is a VM that runs applications that have large storage requirements like immich that have their mounted volumes synced to the nas over NFS.
Any applications that require nas level storage should be deployed here and have a dedicated zfs pool spun up on the NAS.

## immichdb
immich has some specific requirements around what database image you run. To isolate this and make sure its explicit I spun up a VM
whos sole purpose is to run this database container.

## lab
Lab is my personal playground for testing things. You shouldn't have to deal with it much

## defiant
defiant runs homelab apps that are more personal to me and not used by anyone else. For this reason you can be a little more carefree with dealing with this
VM but still don't do anything stupid here.

## thegenerosityco-staging
The staging server for a client that I manage the CMS website for. This uses my tailscale funnel method described below to be exposed publically.

## postgres-dev
A simple postgres server that I can use for random one off things I want to test with a postgres server. No data here is important

## redis
Just runs redis to support any service that needs it.

## rabbitmq
Similarly just runs rabbitmq to support some other homelab apps.

## worf
Runs my vaultwarden password manager server. Also exposed via tailscale funnel setup. Be extra careful when working on this server. It is the most mission critical server.

## bridge
Runs homeassistant and homeassistant related apps like homebridge. In a dedicated VM so things like zigbee radios can be passed through cleanly.

## rpgweave
This is a debian server that runs a public app I run for me and some friends. Exposed via tailscale funnel method.

## rpgweave-staging
internal staging server for rpgweave.

## git
runs my personal forgejo instance. On its own dedicated VM due to it needing control over ssh

## relay
The relay that accepts incoming connections from my tailscale funnel and routes them to other VMs/apps accordingly

## engineering
Where my monitoring stack lives, Things like dozzel for simple monitoring, grafana/prometheus for advanced monitoring, and gatus for uptime.

## pg17
A postgres server used by many apps. I am slowly trying to migrate apps to use my new postgres 18 setup that is running on my nas.

## backup-server
A server that acts as a control center connecting to my other database instances and running backups from them.

## thegenerosityco
A server running on linode that runs the production app for a client of mine. Deployed on linode instead of my homelab for obvious reliability benefits.
It is completely self isolated and while its on my tailnet. It should not depend on any other homelab based services.

## wormhole
A server running on linode that proxies traffic to relay via HAProxy TCP proxy mode. More details below.
Currently runs debian but long term I want to setup a linode nixos machine similar to thegenerosityco server
that runs the same setup.

# backups
I run most of my backups through a dedicated restic module. When deploying a new app consider if any of the directories may need to be backed
up via restic and if so add that module. We use cloudflare r2 for the backing storage.

For postgres backups the backup server runs pg backup on each postgres server and uploads the result to cloudflare r2.

# Tailscale
All of my servers are on tailsclae and should be accessible via ssh over tailscale by their hostnames. Use tailscale status if you need to find a hostname or troubleshoot tailnet stauts.

## Proxy funnel
To expose services publically I have a handrolled proxy setup where wormhole runs haproxy in TCP proxy mode.
This is configured to proxy all TCP traffic over the tailscale connection to the relay host running in my homelab
This VM then runs nginx and accepts the TCP proxy and proxies connections to other apps as needed.

# Troubleshooting homelab hosts
If you ever need to troubleshoot by collecting logs from VMs you can do so by running systemctl/journalctl over ssh.
The VMs also make heavy use of podman so you can also fetch podman logs in this way.
My ssh key also has direct access to the root account on the Nixos VMs so if needed you can also `ssh root@<host> ...` to troubleshoot things.
When troubleshooting and you want to make changes, prefer to make them declaritavely in the nixos config rather than by one off commands on the hosts.

