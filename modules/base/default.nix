{ config, pkgs, ... }:
{
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    nix.settings.experimental-features = ["nix-command" "flakes"];
    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    # Enable networking
    networking.networkmanager.enable = true;

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.riley = {
        isNormalUser = true;
        description = "Riley Mathews";
        extraGroups = [ "networkmanager" "wheel" "docker" ];
        packages = with pkgs; [];
        shell = pkgs.zsh;
    };
    services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        # If you want to use JACK applications, uncomment this
        #jack.enable = true;

        # use the example session manager (no others are packaged yet so this is enabled by default,
        # no need to redefine it in your config for now)
        #media-session.enable = true;
    };
    sops.defaultSopsFormat = "yaml";
    sops.age.keyFile = "/home/riley/.config/sops/age/keys.txt";

    virtualisation.docker = {
        enable = true;
        enableOnBoot = false;
    };

    services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
    };

    programs.firefox.enable = true;

    nixpkgs.config.allowUnfree = true;

    programs.zsh.enable = true;

    services.tailscale.enable = true;
}
