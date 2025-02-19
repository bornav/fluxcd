{ config, lib, system, inputs, host, vars, ... }:
let
  pkgs = import inputs.nixpkgs-stable {
    system = host.system;
    config.allowUnfree = true;
  };
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = host.system;
    config.allowUnfree = true;
  };
  token = ''
  this-is-temp-token
  '';
  master_rke = ''
    write-kubeconfig-mode: "0644"
    cluster-cidr: "10.32.0.0/16"
    service-cidr: "10.33.0.0/16"
    disable-kube-proxy: true
    disable-cloud-controller: true
    disable:
      - rke2-canal
      - rke2-ingress-nginx
      - rke2-service-lb
      - rke2-snapshot-controller
      - rke2-snapshot-controller-crd
      - rke2-snapshot-validation-webhook
    node-label:
      - "node-location=local"
      - "node-arch=amd64"
      - "nixos-nvidia-cdi=enabled"
      - "nvidia.com/gpu.present=true"
      - "storage=ceph"
      - "storage/ceph=true"
    node-ip: 10.2.11.41
  '';
    # runtime-image: "index.docker.io/rancher/rke2-runtime:v1.30.1-rke2r1"
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;}
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disk-config.nix
    ./nvidia.nix
    (import ../rke2-server.nix {inherit inputs vars config lib host system;node_config  = master_rke;})
    {_module.args.disks = [ "/dev/sda" ];}
  ];
  rke2.server = true;
  boot.loader = {
    timeout = 1;
    grub.enable = true;
    grub.device = "nodev";
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = lib.mkForce true;
  };
  environment.etc."rancher/rke2/token".source = pkgs.writeText "token" token;
  services.rke2.tokenFile = lib.mkForce "/etc/rancher/rke2/token";
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
  services.journald = {
    extraConfig = ''
      SystemMaxUse=50M      # Maximum disk usage for the entire journal
      SystemMaxFileSize=50M # Maximum size for individual journal files
      RuntimeMaxUse=50M     # Maximum disk usage for runtime journal
      MaxRetentionSec=1month # How long to keep journal files
    '';
  };
}
