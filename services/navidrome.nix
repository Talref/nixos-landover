# ~/.dotfiles/services/navidrome.nix
{ config, pkgs, lib, ... }:

{
  systemd.services.navidrome = {
    description = "Navidrome Music Server container via Docker";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    enable = true;

    serviceConfig = {
      ExecStart = ''
        ${pkgs.docker}/bin/docker run \
        --name navidrome \
        --rm \
        -p 4533:4533 \
        -v /media/configs/navidrome:/data \
        -v /media/music:/music \
        -e ND_LOGLEVEL=info \
        --user 1000:100 \
        deluan/navidrome:latest
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop navidrome";
      Restart = "always";
    };
  };
  services.caddy.virtualHosts."navidrome.andreaferlat.com" = {
    extraConfig = ''
      reverse_proxy localhost:4533
    '';
  };
}
