{ inputs, vars, ... }:

# let
#   pkgs-stable = import inputs.nixpkgs-stable {
#     config.allowUnfree = true;                              # Allow Proprietary Software
#     system = "x86_64-linux";
#   };

#   pkgs-unstable = import inputs.nixpkgs-unstable {
#     config.allowUnfree = true;
#     system = "x86_64-linux";
#   };

#   pkgs-master = import inputs.nixpkgs-master {
#     config.allowUnfree = true;
#     system = "x86_64-linux";
#   };
# in
{ 
  contabo-01-4v-8m-800g = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";  
    specialArgs = {
      inherit vars inputs;
      host = {
        hostName = "contabo-01-4v-8m-800g";
        vars = vars;
        system = "x86_64-linux"; 
      };
      pkgs-stable   = import inputs.nixpkgs-stable   {system = "x86_64-linux";config.allowUnfree = true;};
      pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";config.allowUnfree = true;};
      pkgs-master   = import inputs.nixpkgs-master   {system = "x86_64-linux";config.allowUnfree = true;};
      system = "x86_64-linux";
    };
    modules = [
        ./kube/contabo-01-4v-8m-800g
        ./kube/common.nix
    ];
  };
  k3s-local-01 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";  
    specialArgs = {
      inherit vars inputs;
      host = {
        hostName = "k3s-local-01";
        vars = vars;
        system = "x86_64-linux"; 
      };
      pkgs-stable   = import inputs.nixpkgs-stable   {system = "x86_64-linux";config.allowUnfree = true;};
      pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";config.allowUnfree = true;};
      pkgs-master   = import inputs.nixpkgs-master   {system = "x86_64-linux";config.allowUnfree = true;};
      system = "x86_64-linux";
    };
    modules = [
        ./kube/k3s-local-01
        ./kube/common.nix
    ];
  };
  k3s-local-02 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";  
    specialArgs = {
      inherit vars inputs;
      host = {
        hostName = "k3s-local-02";
        vars = vars;
        system = "x86_64-linux"; 
      };
      pkgs-stable   = import inputs.nixpkgs-stable   {system = "x86_64-linux";config.allowUnfree = true;};
      pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";config.allowUnfree = true;};
      pkgs-master   = import inputs.nixpkgs-master   {system = "x86_64-linux";config.allowUnfree = true;};
      system = "x86_64-linux"; 
    };
    modules = [
        ./kube/k3s-local-02
        ./kube/common.nix
    ];
  };
  oracle-x86-03 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";  
    specialArgs = {
      inherit vars inputs;
      host = {
        hostName = "oracle-x86-03";
        vars = vars;
        system = "x86_64-linux"; 
      };
      pkgs-stable   = import inputs.nixpkgs-stable   {system = "x86_64-linux";config.allowUnfree = true;};
      pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";config.allowUnfree = true;};
      pkgs-master   = import inputs.nixpkgs-master   {system = "x86_64-linux";config.allowUnfree = true;};
      system = "x86_64-linux"; 
    };
    modules = [
        ./kube/oracle-x86-03
        ./kube/common.nix
    ];
  };
  k3s-oraclearm1 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "aarch64-linux";  
    specialArgs = {
      inherit vars inputs;
      host = {
        hostName = "k3s-oraclearm1";
        vars = vars;
        system = "aarch64-linux"; 
      };
      pkgs-stable   = import inputs.nixpkgs-stable   {system = "aarch64-linux";config.allowUnfree = true;};
      pkgs-unstable = import inputs.nixpkgs-unstable {system = "aarch64-linux";config.allowUnfree = true;};
      pkgs-master   = import inputs.nixpkgs-master   {system = "aarch64-linux";config.allowUnfree = true;};
      system = "aarch64-linux";  
    };
    modules = [
        ./kube/k3s-oraclearm1
        ./kube/common.nix
    ];
  };
  oracle-km1-1 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "aarch64-linux";  
    specialArgs = {
      inherit vars inputs;
      host = {
        hostName = "oracle-km1-1";
        vars = vars;
        system = "aarch64-linux"; 
      };
      pkgs-stable   = import inputs.nixpkgs-stable   {system = "aarch64-linux";config.allowUnfree = true;};
      pkgs-unstable = import inputs.nixpkgs-unstable {system = "aarch64-linux";config.allowUnfree = true;};
      pkgs-master   = import inputs.nixpkgs-master   {system = "aarch64-linux";config.allowUnfree = true;};
      system = "aarch64-linux";  
    };
    modules = [
        ./kube/oracle-km1-1
        ./kube/common.nix
    ];
  };
  rke2-local-node-01 = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";  
    specialArgs = {
        inherit vars inputs;
        host = {
          hostName = "rke2-local-node-01";
          vars = vars;
          system = "x86_64-linux"; 
        };
        pkgs-stable   = import inputs.nixpkgs-stable   {system = "x86_64-linux";config.allowUnfree = true;};
        pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";config.allowUnfree = true;};
        pkgs-master   = import inputs.nixpkgs-master   {system = "x86_64-linux";config.allowUnfree = true;};
        system = "x86_64-linux"; 
    };
    modules = [
        ./kube/rke2-local-node-01
        ./kube/common.nix
    ];
  };
  rke2-local-example = inputs.nixpkgs-unstable.lib.nixosSystem {
    system = "x86_64-linux";  
    specialArgs = {
        inherit vars inputs;
        host = {
          hostName = "rke2-local-example";
          vars = vars;
          system = "x86_64-linux"; 
        };
        pkgs-stable   = import inputs.nixpkgs-stable   {system = "x86_64-linux";config.allowUnfree = true;};
        pkgs-unstable = import inputs.nixpkgs-unstable {system = "x86_64-linux";config.allowUnfree = true;};
        pkgs-master   = import inputs.nixpkgs-master   {system = "x86_64-linux";config.allowUnfree = true;};
        system = "x86_64-linux"; 
    };
    modules = [
        ./kube/rke2-local-example
        ./kube/common.nix
    ];
  };
}
