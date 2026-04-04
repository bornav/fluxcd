{
  inputs,
  vars,
  deploy-rs,
  self,
  ...
}: {
  # hetzner-01 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # oracle-x86-03 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # oracle-bv1-1 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # oracle-km1-1 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # rke2-local-cp-01 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # rke2-local-node-01 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # rke2-local-node-02 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # rke2-secured-cp-01 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # lighthouse = inputs.nixpkgs-unstable.lib.nixosSystem {};
  deploy.nodes = {
    gatekeeper = {
      hostname = "gatekeeper";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.gatekeeper;
      };
    };
  };
  checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

  # gatekeeper = inputs.nixpkgs-unstable.lib.nixosSystem {};
}
