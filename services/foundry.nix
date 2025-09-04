{ config, pkgs, ... }:

{
  users.groups.eradan = {};
  systemd.services.foundry = {
    description = "Foundry Virtual Tabletop Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      User = "eradan";
      Group = "eradan";
      WorkingDirectory = "/home/eradan/s/foundry";
      ExecStart = "${pkgs.nodejs}/bin/node main.js --dataPath=/home/eradan/s/foundrydata";
      Restart = "on-failure";
    };
  };
  
  services.caddy = {
    enable = true;
    virtualHosts."foundry.daje.cc" = {
      extraConfig = ''
        reverse_proxy localhost:30000
      '';
    };
  };
}
