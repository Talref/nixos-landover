{ config, pkgs, lib, ... }:

{
  systemd.services.mongodb-docker = {
    description = "MongoDB container via Docker";
    after = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = ''
        ${pkgs.docker}/bin/docker run \
          --rm \
          --name mongodb \
          -p 27017:27017 \
          -v /media/configs/mongodb:/data/db \
          mongo:7
      '';
      ExecStop = "${pkgs.docker}/bin/docker stop mongodb";
      Restart = "always";
    };
  };
}
