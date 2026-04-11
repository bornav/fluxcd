{
  description = "A very basic flake";

  inputs = {
    # References Used by Flake
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";                     # Stable Nix Packages (Default)
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable"; # Unstable Nix Packages
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    # nixpkgs-bornav.url = "github:bornav/nixpkgs/feat/headscale-allow-external-config";
    nixpkgs-bornav.url = "github:bornav/nixpkgs/test-rebase";
    nixpkgs-test.url = "github:bornav/nixpkgs/noissue-testing";
    # nixpkgs-bornav.url = "git+file:///home/user/git/nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master"; #https://github.com/NixOS/nixos-hardware/tree/master
    home-manager = {
      url = "github:nix-community/home-manager";
      # inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nur.url = "github:nix-community/NUR";
    disko = {
      url = "github:nix-community/disko";
      #  inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    sops-nix.url = "github:Mic92/sops-nix";
    deploy-rs.url = "github:serokell/deploy-rs";
  };
  outputs = {self, ...} @ inputs:
  # Function telling flake which inputs to use
  let
    vars = {
      # Variables Used In Flake
      user = "nix";
      location = "$HOME/.flake";
      terminal = "alacritty";
      editor = "vim";
      stateVersion = "25.11";
    };
    inherit (self) outputs;
  in {
    nixosConfigurations = (
      import ./nix {
        inherit inputs outputs self vars; # Inherit inputs
      }
    );
    deploy = import ./nix/deploy.nix {inherit inputs outputs self vars;};
    # hydraJobs = import ./hydra.nix {inherit inputs outputs;};
    # homeConfigurations = (
    # 	import ./nix {
    # 	inherit (nixpkgs) lib;
    # 	inherit inputs nixpkgs nixpkgs-unstable home-manager vars;
    # 	}
    # );
    #

    # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
