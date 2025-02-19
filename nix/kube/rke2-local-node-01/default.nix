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
    # node-taint:
    #   - "node-role.kubernetes.io/control-plane=true:NoSchedule"
    kube-apiserver-arg:
      - oidc-issuer-url=https://sso.icylair.com/realms/master
      - oidc-client-id=kubernetes
      - oidc-groups-claim=groups
    node-ip: 10.99.10.51
    # node-ip: 10.2.11.42
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
    # (import ../k3s-server.nix {inherit inputs vars config lib system;node_config = master3;})
    (import ../rke2-server.nix {inherit inputs vars config lib host system;node_config  = master_rke;})
    # ./k3s-server.nix
    {_module.args.disks = [ "/dev/sda" ];}
  ];
  rke2.server = true;
  # rke2.agent = true;

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs-unstable.linuxKernel.packages.linux_6_8;
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
  services.rke2.package = lib.mkForce (pkgs.callPackage ../../../modules/custom_pkg/rke2_custom.nix {
          rke2Version = "1.32.0+rke2r1";
          rke2Commit = "1182e7eb91b27b1686e69306eb2e227928a27a38";
          rke2TarballHash = "sha256-mmHQxiNcfgZTTdYPJPO7WTIlaCRM4CWsWwfRUcAR8ho=";
          rke2VendorHash = "sha256-6Y3paEQJ8yHzONqalzoe15TjWhF3zGsM92LS1AcJ2GM=";
          # k8sVersion = "v1.32.0";
          k8sImageTag = "v1.32.0-rke2r1-build20241212";
          etcdVersion = "v3.5.16-k3s1-build20241106";
          pauseVersion = "3.6";
          ccmVersion = "v1.32.0-rc3.0.20241220224140-68fbd1a6b543-build20250101";
          dockerizedVersion = "v1.32.0-rke2r1";
          # golangVersion = "go1.23.3";
          # eol = "2026-02-28";
          });

  fileSystems."/kubernetes" = {#truenas nfs storage
        device = "10.2.11.200:/mnt/vega/vega/kubernetes";
        fsType = "nfs";
        options = [ "soft" "timeo=50" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s"];
      };



}
