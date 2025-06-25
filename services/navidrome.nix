# ~/.dotfiles/services/navidrome.nix
{ config, pkgs, lib, ... }:

let
  navidromeUser = "navidrome";
  navidromeGroup = "navidrome";

  navidromeConfigDir = "/media/configs/navidrome"; # Persistent config files
  navidromeMusicDir = "/media/music";             # Your music library

in
{
  # Ensure the Navidrome user and group exist
  users.users.${navidromeUser} = {
    isSystemUser = true;
    group = navidromeGroup;
    # Ensure this user can access /media/configs and /media/music
    extraGroups = [ "users" ];
  };
  users.groups.${navidromeGroup} = {};

  # Define the Navidrome container using NixOS's declarative OCI (Docker) support
  virtualisation.oci-containers.containers.navidrome = {
    image = "deluan/navidrome:latest"; # Or a specific version like "deluan/navidrome:0.50.0" for more control
    autoStart = true;
    extraHostConfig = {
      ContainerName = "navidrome";
    };

    ports = [ "127.0.0.1:4533:4533" ];

    # Volume mounts for config and music
    volumes = [
      "${navidromeConfigDir}:/data"
      "${navidromeMusicDir}:/music:ro"
    ];

    # Environment variables for Navidrome
    environment = {
      # ND_HOME points to the data directory inside the container
      ND_HOME = "/data";
      # ND_SCANINTERVAL: set to "1h" for hourly scans, "0" for manual, or "10m" for 10 minutes
      ND_SCANINTERVAL = "1h";
      # ND_LOGLEVEL: "info", "warn", "error", "debug", "trace"
      ND_LOGLEVEL = "info";
      ND_USERNAME = "admin";
      ND_PASSWORD = "my_secure_password";
    };

    # Run the container as the dedicated user/group
    user = "${toString navidromeUser}:${toString navidromeGroup}";

    # Ensure the necessary directories exist on the host before container starts
    preStart = ''
      mkdir -p ${navidromeConfigDir}
      chown -R ${navidromeUser}:${navidromeGroup} ${navidromeConfigDir}
    '';
  };

  # Configure Caddy to serve Navidrome with HTTPS
  services.caddy.virtualHosts."navidrome.andreaferlat.com" = {
    # Ensure Caddy is set up for automatic HTTPS via Let's Encrypt (which you already have enabled)
    # The 'email' for ACME is set in your main configuration.nix, so it will be used here.
    # No 'tls internal' needed for public domain.
    reverse_proxy = "localhost:4533"; # Proxy requests to the internal port of the Navidrome container
  };
}
