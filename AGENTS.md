# NixOS Configuration - Agent Guidelines

This is my nix configuration repository. It is responsible mostly for configuring the VMs in my homelab though it also has one laptop 'picard' that is configured here as well.

It follows a pretty standard pattern where hosts are defined in the flake.nix file. These import a vanilla configuration.nix file for each host and then there are
quite a few modules that are shared between each host. The modules directory contains some moduels that are more low level like defining an nginx config
that is used across pretty much every VM and some modules that just define app containers and their direct dependencies that are only used on one VM.

