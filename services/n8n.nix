{ config, pkgs, lib, ... }:

{
  systemd.services.n8n = {
    description = "n8n Automation Server container via Docker";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    enable = true;

    serviceConfig = {
      ExecStart = ''|
        ${pkgs.docker}/bin/docker rm -f n8n 2>/dev/null || true
        ${pkgs.docker}/bin/docker run \
          --name n8n \
          -d \
          -p 5678:5678 \
          -v /media/configs/n8n:/home/node/.n8n \
          --env-file /home/eradan/.dotfiles/.env \
          n8nio/n8n:latest
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop n8n";
      Restart = "always";
    };
  };

  services.caddy.virtualHosts."n8n.andreferlat.com" = {
    extraConfig = ''
      reverse_proxy localhost:5678
    '';
  };
}
