{ config, pkgs, ... }:

{
  systemd.services.sillytavern = {
    description = "SillyTavern HappyChats Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      User = "eradan";
      Group = "eradan";
      WorkingDirectory = "/home/eradan/ai/SillyTavern";
      ExecStart = "${pkgs.nodejs}/bin/node server.js";
      Restart = "on-failure";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."silly.lan" = {
      extraConfig = ''
        reverse_proxy localhost:6969
      '';
    };
  };
}
