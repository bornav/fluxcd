{
  description = "A very basic flake";

  inputs = {                                                              # References Used by Flake
      # nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";                     # Stable Nix Packages (Default)
      # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
      nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";         # Unstable Nix Packages
      nixpkgs-master.url = "github:nixos/nixpkgs/master"; 
      nixos-hardware.url = "github:NixOS/nixos-hardware/master"; #https://github.com/NixOS/nixos-hardware/tree/master
      home-manager = {url = "github:nix-community/home-manager";
                      # inputs.nixpkgs.follows = "nixpkgs-unstable";
                      };
      nix-flatpak.url = "github:gmodena/nix-flatpak";
      nur.url = "github:nix-community/NUR";
      disko = {url = "github:nix-community/disko";
              #  inputs.nixpkgs.follows = "nixpkgs-unstable";
               };
      nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    };
  outputs = { self, nur, nixpkgs-unstable, nixpkgs-stable, nixpkgs-master, home-manager, nixos-hardware, nix-flatpak, disko, ... } @ inputs:   # Function telling flake which inputs to use
	let
		vars = {                                                              # Variables Used In Flake
			user = "nix";
			location = "$HOME/.flake";
			terminal = "alacritty";
			editor = "vim";
      stateVersion = "24.11";
		};
    inherit (self) outputs;
	in {
		nixosConfigurations = (
			import ./nix {
			inherit inputs outputs self vars;   # Inherit inputs
			}
		);
		# homeConfigurations = (
		# 	import ./nix {
		# 	inherit (nixpkgs) lib;
		# 	inherit inputs nixpkgs nixpkgs-unstable home-manager vars;
		# 	}
		# );
	};
}
