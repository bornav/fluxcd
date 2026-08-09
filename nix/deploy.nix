{
  inputs,
  vars,
  # deploy-rs,
  self,
  ...
}: {
  # nix run github:serokell/deploy-rs ~/git/kubernetes/fluxcd

  # hetzner-01 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # oracle-x86-03 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # oracle-bv1-1 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # oracle-km1-1 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # rke2-local-cp-01 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # rke2-local-node-01 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # rke2-local-node-02 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # rke2-secured-cp-01 = inputs.nixpkgs-unstable.lib.nixosSystem {};
  # lighthouse = inputs.nixpkgs-unstable.lib.nixosSystem {};
  nodes = {
    gatekeeper = {
      hostname = "gatekeeper";
      profiles.system = {
        user = "root";
        sshUser = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.gatekeeper;
      };
    };
    lighthouse = {
      hostname = "lighthouse";
      profiles.system = {
        user = "root";
        sshUser = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.lighthouse;
      };
    };

    rke2-local-cp-01 = {
      hostname = "rke2-local-cp-01";
      profiles.system = {
        user = "root";
        sshUser = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.rke2-local-cp-01;
      };
    };
    rke2-local-node-01 = {
      hostname = "rke2-local-node-01";
      profiles.system = {
        user = "root";
        sshUser = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.rke2-local-node-01;
      };
    };
    rke2-local-node-02 = {
      hostname = "rke2-local-node-02";
      profiles.system = {
        user = "root";
        sshUser = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.rke2-local-node-02;
      };
    };
    # rke2-local-node-03-secured = {
    #   hostname = "rke2-local-node-03-secured";
    #   profiles.system = {
    #     user = "root";
    #     sshUser = "root";
    #     path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.rke2-local-node-03-secured;
    #   };
    # };
  };
}
