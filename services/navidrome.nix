# ~/.dotfiles/services/navidrome.nix
{ config, pkgs, lib, ... }:

let
  # Use your existing user and group matching YAMS setup (eradan:users)
  # Assuming 'eradan' is UID 1000 and 'users' is GID 100
  userForContainer = "eradan";
  groupForContainer = "users";

  # Define paths for Navidrome's configuration and music data
  navidromeConfigDir = "/media/configs/navidrome"; # Persistent config files
  navidromeMusicDir = "/media/music";             # Your music library

in
{
  # Define the SOPS secret for Navidrome's password
  sops.secrets.navidrome_password = {
    sopsFile = ./secrets/navidrome-password.yaml;
    mode = "0400"; # Read-only for owner
    owner = userForContainer;
    group = groupForContainer;
  };

  # Define the Navidrome container using NixOS's declarative OCI (Docker) support
  virtualisation.oci-containers.containers.navidrome = {
    image = "deluan/navidrome:latest"; # Or a specific version for stability
    autoStart = true;
    ports = [ "127.0.0.1:4533:4533" ]; # Expose only internally for Caddy to proxy

    volumes = [
      "${navidromeConfigDir}:/data"      # Container's /data for DB/config
      "${navidromeMusicDir}:/music:ro"   # Container's /music for library (read-only)
    ];

    environment = {
      ND_HOME = "/data";          # Navidrome's data directory inside container
      ND_SCANINTERVAL = "1h";     # Set scan interval (e.g., "0" for manual, "10m" for 10 minutes)
      ND_LOGLEVEL = "info";       # Logging level ("info", "warn", "error", "debug", "trace")
      ND_PASSWORD = lib.strings.fileContents config.sops.secrets.navidrome_password.path; # Get password from SOPS
    };

    # Run the container process as your specified user/group
    user = "${toString userForContainer}:${toString groupForContainer}";

    # Ensure the config directory exists on the host. Permissions are assumed correct for 'eradan'.
    preStart = "mkdir -p ${navidromeConfigDir}";
  };

  # Configure Caddy to serve Navidrome with HTTPS
  services.caddy.virtualHosts."navidrome.andreaferlat.com" = {
    reverse_proxy = "localhost:4533"; # Proxy requests to the internal Navidrome port
  };
}
