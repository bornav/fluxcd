{ config, lib, system, inputs, host, vars, pkgs, pkgs-unstable, ... }: # TODO remove system, only when from all modules it is removed
let
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
      - "storage/ceph=false"
      - "storage/longhorn=true"
    # node-taint:
    #   - "node-role.kubernetes.io/control-plane=true:NoSchedule"
    kube-apiserver-arg:
      - "oidc-issuer-url=https://sso.icylair.com/realms/master"
      - "oidc-client-id=kubernetes"
      - "oidc-username-claim=email"
      - "oidc-groups-claim=groups"
    node-ip: 10.99.10.52
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
    # ./nvidia_new.nix
    # ./nvidia_new2.nix
    # ./iscsi-drive.nix
    ./virt.nix
    # ./net-forward.nix
    # (import ../k3s-server.nix {inherit inputs vars config lib system;node_config = master3;})
    (import ../rke2-server.nix {inherit inputs vars config lib host system pkgs;node_config  = master_rke;})
    # ./k3s-server.nix
    {_module.args.disks = [ "/dev/sda" ];}
  ];
  # "server" or "agent"
  rke2.type = "agent";
  rke2.server_lb_address= "https://rke2-local-cp-01.local.icylair.com:9345";

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
  services.rke2.package = lib.mkForce (
    pkgs.callPackage ../../modules/custom_pkg/rke2_custom.nix {
      rke2Version = "1.34.1+rke2r1";
      rke2Commit = "98b87c78e2c5a09fd8ff07bcaf4f102db1894a93";
      rke2TarballHash = "sha256-dRmIDXeZabWxknqPod0RLZfT3I20llXELJhuQgDQHIc=";
      rke2VendorHash = "sha256-i8VS4NviyVxjTJpsO/sL9grYyUzy72Ql6m3qHbtnLnw=";
      k8sImageTag = "v1.34.1-rke2r1-build20250910";
      etcdVersion = "v3.6.4-k3s3-build20250908";
      pauseVersion = "3.6";
      ccmVersion = "v1.33.0-rc1.0.20250905195603-857412ae5891-build20250908";
      dockerizedVersion = "v1.34.1-rke2r1";
    }
  );

  fileSystems."/kubernetes" = {
        #truenas nfs storage
        device = "10.2.11.200:/mnt/vega/vega/kubernetes";
        fsType = "nfs";
        options = [ "soft" "timeo=50" "x-systemd.automount" "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s"];
      };

  environment.systemPackages = with pkgs; [
    zfs
    nvme-cli
    nfs-utils
    openiscsi
    lsscsi
    sg3_utils
    multipath-tools
  ];
  # networking = {
  #   vlans = {
  #     vlan12 = { id=12; interface="ens19"; };
  #   };
  #   interfaces.vlan12.useDHCP = true;
  #   # interfaces.vlan12.ipv4.addresses = [{
  #   #   address = "10.2.12.42";
  #   #   prefixLength = 24;
  #   # }];
  # };

}
