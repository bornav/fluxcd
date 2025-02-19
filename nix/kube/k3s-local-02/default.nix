{ config, lib, system, inputs, host, vars, ... }: # TODO remove system, only when from all modules it is removed
let
  pkgs = import inputs.nixpkgs-stable {
    system = host.system;
    config.allowUnfree = true;
  };
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = host.system;
    config.allowUnfree = true;
  };
  master4_rke = ''
    ---
    write-kubeconfig-mode: "0644"
    node-label:
      - "node-location=local"
      - "node-arch=amd64"
    node-taint:
      - "node-role.kubernetes.io/role=worker:PreferNoSchedule"
    node-ip: 10.99.10.14
  '';
  # kubectl label nodes k3s-local-02 kubernetes.io/role=worker
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
    # (import ../k3s-server.nix {inherit inputs vars config lib system;node_config = master3;})
    (import ../rke2-server.nix {inherit inputs vars config lib host system ;node_config = master4_rke;})
    # ./k3s-server.nix
    {_module.args.disks = [ "/dev/sda" ];}
  ];
  # rke2.server = true;
  rke2.agent = true;

  # virtualization.enable = true;
  # virtualization.qemu = true;
  
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

  systemd.network.networks."10-wan" = {
    matchConfig.Name = "enp1s0";
    networkConfig = {
      # start a DHCP Client for IPv4 Addressing/Routing
      DHCP = "ipv4";
      # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
      IPv6AcceptRA = true;
    };
    # make routing on this interface a dependency for network-online.target
    linkConfig.RequiredForOnline = "routable";
  };

  # services.openiscsi = {
  #   enable = true;
  #   discoverPortal = [ "10.2.11.200:3260" ];
  #   name = lib.mkForce "iqn.2005-10.org.freenas.ctl:iscsi-worker-local-02";
  # };
  # systemd.services.iscsi-login-lingames = {
  #   description = "Login to iSCSI target iqn.2005-10.org.freenas.ctl:iscsi-worker-local-02";
  #   after = [ "network.target" "iscsid.service" ];
  #   wants = [ "iscsid.service" ];
  #   serviceConfig = {
  #     ExecStartPre = "${pkgs.openiscsi}/bin/iscsiadm -m discovery -t sendtargets -p 10.2.11.200";
  #     ExecStart = "${pkgs.openiscsi}/bin/iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:iscsi-worker-local-02 -p 10.2.11.200 --login";
  #     ExecStop = "${pkgs.openiscsi}/bin/iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:iscsi-worker-local-02 -p 10.2.11.200 --logout";
  #     Restart = "on-failure";
  #     RemainAfterExit = true;
  #   };
  #   wantedBy = [ "multi-user.target" ];
  # }; 
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
