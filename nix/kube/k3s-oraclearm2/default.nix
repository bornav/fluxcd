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
  master1 = ''
    ---
    flannel-backend: none
    disable-kube-proxy: true
    disable-network-policy: true
    write-kubeconfig-mode: "0644"
    cluster-init: true
    disable:
      - servicelb
      - traefik
    node-ip: 10.99.10.11
  '';
  master1_rke = ''
    write-kubeconfig-mode: "0644"
    cluster-cidr: "10.52.0.0/16"
    service-cidr: "10.53.0.0/16"
    disable-kube-proxy: true
    disable-cloud-controller: true
    disable:
      - rke2-canal
      - rke2-ingress-nginx
      - rke2-service-lb
      - rke2-metrics-server
      # - rke2-kube-proxy
      # - rke2-coredns
      - rke2-snapshot-controller
      - rke2-snapshot-controller-crd
      - rke2-snapshot-validation-webhook
    # control-plane-resource-requests:
    #   - kube-apiserver-cpu=500m
    #   - kube-apiserver-memory=512M
    #   - kube-scheduler-cpu=250m
    #   - kube-scheduler-memory=512M
    #   - etcd-cpu=1000m
    kube-apiserver-arg:
      - oidc-issuer-url=https://sso.icylair.com/realms/master
      - oidc-client-id=kubernetes
      - oidc-groups-claim=groups
    node-label:
      - "node-location=cloud"
      - "node-arch=arm64"
      - "nat-policy=enabled"
      # - "storage=longhorn"
      - "storage/longhorn=true"
    node-ip: 10.99.10.11
    server: https://lb.cloud.icylair.com:9345
  '';
  
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;}
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.disko.nixosModules.disko
    # ./vxlan.nix
    # inputs.wirenix.nixosModules.default
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../failtoban.nix
    # (import ../k3s-server.nix {inherit inputs vars config lib system;node_config = master1;})
    (import ../rke2-server.nix {inherit inputs vars config lib host system;node_config = master1_rke;})
    # ./k3s-server.nix
    # ./mesh.nix
    {_module.args.disks = [ "/dev/sda" ];}
  ];
  rke2.server = true;
  # rke2.agent = true;

  fileSystems."/storage" =
    { device = "/dev/disk/by-uuid/a640f0aa-5604-4bf7-8b8f-265c233d9813"; 
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };

  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs-unstable.linuxKernel.packages.linux_6_8;
  boot.loader = {
    timeout = 1;
    grub.enable = true;
    grub.device = "nodev";
    # efi.canTouchEfiVariables = true;
    # grub.efiInstallAsRemovable = lib.mkForce false;
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = lib.mkForce true;
  };
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
