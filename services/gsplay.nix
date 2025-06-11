{ config, pkgs, lib, ... }:

let
  gsplaySrc = pkgs.fetchFromGitHub {
    owner = "Talref";
    repo = "gsplay";
    rev = "7e45710cb88bd88bea522f489abf916c67038615";
    sha256 = "sha256-mSMIfCGbMZwDUQ8ZR6wKjbXF4xQ1zHbfZ/4u3JTR6/0=";
  };

  nodejs = pkgs.nodejs_20;
  nodePackages = pkgs.nodePackages.override { inherit nodejs; };

  # Frontend Build
  gsplayFrontend = pkgs.stdenv.mkDerivation {
    pname = "gsplay-frontend";
    version = "1.0";
    src = "${gsplaySrc}/gsplay-frontend";

    nativeBuildInputs = [
      nodejs
      pkgs.python3 # Often needed for node-gyp
      pkgs.makeWrapper
    ];

    buildPhase = ''
      export HOME=$(mktemp -d) # Some npm packages need a home directory
      npm install --no-optional --loglevel=verbose
      npm run build
    '';

    installPhase = ''
      mkdir -p $out
      cp -r dist/* $out/ # */
    '';
  };

  # Backend Application
  gsplayBackend = pkgs.buildNpmPackage {
    pname = "gsplay-backend";
    version = "1.0";
    src = gsplaySrc;

    npmDepsHash = "sha256-0000000000000000000000000000000000000000000000000000"; # You'll need to replace this

    nativeBuildInputs = [
      nodejs
      pkgs.python3
    ];

    # Don't run npm install in installPhase
    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };

in {
  systemd.services.gsplay-backend = {
    description = "GSPlay Express Backend";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${nodejs}/bin/node ${gsplayBackend}/server.js";
      WorkingDirectory = "${gsplayBackend}";
      User = "gsplay";
      Group = "gsplay";
      Restart = "on-failure";
      RestartSec = "5s";
    };

    environment = {
      NODE_ENV = "production";
      # MONGO_URI = "mongodb://localhost:27017/gsplaydb";
    };
  };

  users.users.gsplay = {
    isSystemUser = true;
    group = "gsplay";
  };
  users.groups.gsplay = {};

{
  services.caddy.virtualHosts."gs.andreaferlat.com" = {
    # Add this line to ensure HTTPS is properly configured
    useACMEHost = "gs.andreaferlat.com";
    
    extraConfig = ''
      root * ${gsplayFrontend}
      file_server
      
      @api {
        path /api*
      }
      reverse_proxy @api http://localhost:3000
      
      @notFound {
        file {
          try_files {path} {path}/ /index.html
          not_found
        }
      }
      rewrite @notFound /index.html
    '';
  };
}
