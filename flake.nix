{
  description = "Home Server Main Flake";

  inputs = {
    # The actual NixOS repo
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Home Manager: Manages user-level configurations.
    # Use the 'release-24.11' branch for consistency with nixpkgs.
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # IMPORTANT: Ensures HM uses *your* nixpkgs

    # SOPS-Nix: For managing encrypted secrets.
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs"; # IMPORTANT: Ensures sops-nix uses *your* nixpkgs

    # (Later: Your Webapp Flake will go here)
    # my-webapp.url = "github:YourUser/your-webapp-repo";
    # my-webapp.inputs.nixpkgs.follows = "nixpkgs";
  };

outputs = inputs@{ self, nixpkgs, home-manager, sops-nix, ... }:
    let
      # Define the system architecture
      system = "x86_64-linux";

      # Get the Nixpkgs for the specified system - this defines 'pkgs' for *this* scope
      pkgs = nixpkgs.legacyPackages.${system};

      # Define a common 'lib' for convenience - this defines 'lib' for *this* scope
      lib = nixpkgs.lib;

      # Define custom configuration for nixpkgs (like allowUnfreePredicate)
      nixpkgsConfig = {
        allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          # Add names of unfree packages you use, e.g., "nvidia-drivers"
        ];
      };

      # Define your custom package overrides as an overlay
      myOverlays = [
        (final: prev: {
          # ... your overlays if any ...
        })
      ];

    in
    {
      nixosConfigurations = {
        # Define your server's configuration named 'landover'
        landover = lib.nixosSystem {
          inherit system;

          # === THE CRUCIAL CHANGE IS HERE: specialArgs ===
          # specialArgs allows you to pass arbitrary values to *all* modules.
          # Modules receive these values automatically as part of their function arguments.
          specialArgs = {
            inherit inputs pkgs lib; # Pass 'inputs', 'pkgs', and 'lib' to all modules
          };
          # === END CRUCIAL CHANGE ===

          modules = [
            # The order here can matter for some imports.
            ./hardware-configuration.nix

            # Your main configuration file.
            # Make sure this module (and all modules it imports) can receive 'pkgs' and 'lib'.
            ./configuration.nix

            # Home Manager module (must be explicitly imported now)
            home-manager.nixosModules.home-manager

            # SOPS-Nix module (must be explicitly imported now)
            sops-nix.nixosModules.sops

            # Apply your custom nixpkgs config and overlays here
            {
              nixpkgs.config = nixpkgsConfig;
              nixpkgs.overlays = myOverlays;
            }
          ];
        };
      };
    };
}

