{ config, lib, pkgs, ... }: # These are now passed implicitly from flake.nix

{
  imports =
    [ 
      ./hardware-configuration.nix
      ./services/sillytavern.nix # Silly Tavern service (fine, local)
      ./services/mongodb-docker.nix # MongoDB docker (fine, local, but consider OCI containers later)
      ./services/navidrome.nix
      # ./services/gsplay.nix # GSPlay stack (fine, local)
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use Systemd for boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  ## -- NETWORK --

  # Network Setuo
  networking.hostName = "landover";
  networking.networkmanager.enable = true;

  # Set Static IP:
  networking.useDHCP = false;
  networking.interfaces.enp37s0.ipv4.addresses = [
    {
      address = "192.168.1.11";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.1.254";
  networking.nameservers = [ "192.168.1.1" ];

  # Firewall settings
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      111 # NFS Share
      443
      2049 # NFS Share
      6969 # Sillytavern
      7777 # Abiotic Factor Docker
      9090 # Bittorrent
      8989
      27015 # Abiotic Factor Query
      32400 # Plex?
    ];
    allowedUDPPorts = [
      111 # NFS Share
      2049 # NFS Share
      7777 # Abiotic Factor
      27015 # Abiotic Factor
    ];
    # Optional: allow ICMP/ping
    allowPing = true;
    # Optional: log dropped packets
    logRefusedConnections = false;
  };

  ## --SYSTEM --

  # Set your time zone.
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Define users
  users.users.eradan = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "eradan" ]; # Enable ‘sudo’ for the user.
  };

  ## -- STORAGE --

# Mount /media
# Section 1: Mount the individual XFS drives
fileSystems."/mnt/data_2tb" = {
  device = "/dev/disk/by-label/Data2TB";
  fsType = "xfs";
  options = [ "defaults" ];
};

fileSystems."/mnt/data_8tb" = {
  device = "/dev/disk/by-label/Data8TB";
  fsType = "xfs";
  options = [ "defaults" ];
};

fileSystems."/mnt/data_12tb" = {
  device = "/dev/disk/by-label/Data12TB";
  fsType = "xfs";
  options = [ "defaults" ];
};

# NEW: Dedicated downloads drive
fileSystems."/media/downloads" = {
  device = "/dev/disk/by-label/Data3TB"; 
  fsType = "xfs";
  options = [ "defaults" "nofail" ];
};

# Section 2: Configure MergerFS
systemd.mounts = [{
  unitConfig = {
    After = [
      "mnt-data_2tb.mount"
      "mnt-data_8tb.mount"
      "mnt-data_12tb.mount"
    ];
  };
  where = "/media";
  what = "/mnt/data_2tb:/mnt/data_8tb:/mnt/data_12tb";
  type = "fuse.mergerfs";
  options = "cache.files=partial,dropcacheonclose=true,category.create=epmfs,minfreespace=50G,allow_other,auto_unmount";
  wantedBy = [ "multi-user.target" ];
}];

# NFS Media Share
  services.nfs.server = {
    enable = true;
    exports = ''
      /media          192.168.1.0/24(rw,no_subtree_check,no_root_squash,fsid=0)
      /media/downloads 192.168.1.0/24(rw,no_subtree_check,no_root_squash)
    '';
  };

  ## --SOFTWARE--

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Basic
    coreutils
    wget
    btop
    git
    parted
    xfsprogs
    docker-compose
    mergerfs
    node2nix #Fuck you Nix
    # Apps
    neovim
  ];

  # List SERVICES that you want to enable:
  services.openssh.enable = true; #OpenSSH
  virtualisation.docker.enable = true; #Docker
  services.caddy = {
    enable = true;
    email = "eradan83@gmail.com"; # Replace with your real email
  };

  # Caddy SSL
  security.acme = {
    acceptTerms = true;
    defaults.email = "eradan83@gmail.com"; # Use your real email
  };

  system.stateVersion = "24.11"; # Don't change this, ever.

}
