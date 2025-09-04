{ config, pkgs, ... }:

{
  users.groups.eradan = {};
  systemd.services.sillytavern = {
    description = "SillyTavern HappyChats Service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      User = "eradan";
      Group = "eradan";
      WorkingDirectory = "/home/eradan/ai/Sillytavern";
      ExecStart = "${pkgs.nodejs}/bin/node server.js";
      Restart = "on-failure";
      # Add this line to include git and other essential tools
      Environment="PATH=${pkgs.git}/bin:${pkgs.coreutils}/bin";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."silly.lan" = {
      extraConfig = ''
        reverse_proxy localhost:6969
        tls internal
      '';
    };
  };
}
