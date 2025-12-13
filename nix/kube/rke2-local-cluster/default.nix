{
  config,
  lib,
  system,
  inputs,
  host,
  vars,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disk-config.nix
    # ./iscsi-drive.nix
    ./virt.nix
    # ./net-forward.nix
    {_module.args.disks = ["/dev/sda"];}
  ];
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs-unstable.linuxKernel.packages.linux_6_8;
  boot.loader = {
    timeout = 1;
    grub.enable = true;
    grub.device = "nodev";
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = lib.mkForce true;
  };
  boot.initrd.systemd.network.wait-online.enable = false;

  systemd.network.wait-online.enable = false;
  services.journald = {
    extraConfig = ''
      SystemMaxUse=50M      # Maximum disk usage for the entire journal
      SystemMaxFileSize=50M # Maximum size for individual journal files
      RuntimeMaxUse=50M     # Maximum disk usage for runtime journal
      MaxRetentionSec=1month # How long to keep journal files
    '';
  };

  services.rke2.tokenFile = lib.mkForce "/etc/rancher/rke2/token";
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
    # truenas nfs storage
    device = "10.2.11.200:/mnt/vega/vega/kubernetes";
    fsType = "nfs";
    options = [
      "soft"
      "timeo=50"
      "x-systemd.automount"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
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
