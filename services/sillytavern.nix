{ config, pkgs, lib, ... }:

# Run the service
let
  sillyTavernUser = "eradan";
  sillyTavernPath = "/home/${sillyTavernUser}/ai/Sillytavern";
in
{
  systemd.services.sillytavern = {
    description = "SillyTavern AI Chat Interface";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.git ];

    # Configuration options for the systemd service itself.
    serviceConfig = {
      ExecStart = "${pkgs.nodejs}/bin/node server.js";
      WorkingDirectory = sillyTavernPath;
      User = sillyTavernUser;
      Group = "users";
      Restart = "always";

      # Environment variables for the service.
      Environment = [
        "NODE_ENV=production"
        "PORT=6969"
      ];
    };
    enable = true;
  };

  # Serve the service locally through Caddy
  services.caddy.virtualHosts."silly.lan" = {
    extraConfig = ''
    tls internal
    reverse_proxy http://localhost:6969
    '';
  };
}

