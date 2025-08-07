{ config, pkgs, ... }:

{
  # 1. Define the dedicated 'gsplay' user and group
  users.users.gsplay = {
    isSystemUser = true;
    group = "gsplay";
  };
  users.groups.gsplay = {};

  # 2. Define the systemd service for your backend
  systemd.services.gsplay-backend = {
    description = "GSPlay Node.js Backend";
    # Ensure the service starts after network is up and MongoDB is running
    after = [ "network.target" "mongodb-docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      # Path to your Node.js executable and your server.js file
      ExecStart = "${pkgs.nodejs}/bin/node /srv/gsplay/server.js";
      # Set the working directory to where your backend files are
      WorkingDirectory = "/srv/gsplay";
      # Run the service as the dedicated 'gsplay' user
      User = "gsplay";
      Group = "gsplay";
      # Always restart if the service fails
      Restart = "always";
      RestartSec = "5s"; # Wait 5 seconds before attempting a restart
      # Load environment variables from your .env file
      EnvironmentFile = "/srv/gsplay/.env";
    };
  };

  # 3. Configure Caddy to serve the frontend and proxy the backend
  services.caddy.virtualHosts."gs.andreaferlat.com" = {
    extraConfig = ''
      handle /api/* {
        reverse_proxy localhost:3000
      }

      handle {
        root * /srv/gsplay/gsplay-frontend/dist
        file_server
        try_files {path} /index.html
      }
    '';
  }
;}
