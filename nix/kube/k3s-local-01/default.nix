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
  master3 = ''
    ---
    token: xx
    flannel-backend: none
    disable-kube-proxy: true
    disable-network-policy: true
    write-kubeconfig-mode: "0644"
    cluster-init: true
    disable:
      - servicelb
      - traefik
    node-ip: 10.99.10.13
    server: https://10.99.10.11:6443
  '';
  master3_rke = ''
    ---
    write-kubeconfig-mode: "0644"
    disable:
      - rke2-canal
      - rke2-ingress-nginx
      - rke2-service-lb
    disable-kube-proxy: true
    cluster-cidr: "10.52.0.0/16"
    service-cidr: "10.53.0.0/16"
    node-label:
      - "node-location=local"
      - "node-arch=amd64"
    kube-apiserver-arg:
      - oidc-issuer-url=https://sso.icylair.com/realms/master
      - oidc-client-id=kubernetes
      - oidc-username-claim=email
      - oidc-groups-claim=groups
    node-taint:
      - "node-role.kubernetes.io/control-plane=true:NoSchedule"
    node-ip: 10.99.10.13
    server: https://10.99.10.11:9345
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
    # (import ../k3s-server.nix {inherit inputs vars config lib system;node_config = master3;})
    (import ../rke2-server.nix {inherit inputs vars config lib host system;node_config  = master3_rke;})
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
    # efi.canTouchEfiVariables = true;
    # grub.efiInstallAsRemovable = lib.mkForce false;
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = lib.mkForce true;
  };
  # networking.firewall = {
  #   # nat = {
  #   #   enable = true;
  #   #   enableIPv6 = false;  # Disable IPv6 NAT if not needed
      
  #   #   # External interface (change this to match your setup)
  #   #   # This is typically your main network interface
  #   #   externalInterface = "ens18";  # Common VMware interface name
      
  #   #   # Configure port forwarding
  #   #   forwardPorts = [
  #   #     {
  #   #       sourcePort = 443;  # HTTPS traffic
  #   #       destination = "10.49.20.20:8443";  # Forward to internal IP
  #   #       proto = "tcp";
  #   #     }
  #   #   ];
      
  #   #   # Optional: Configure internal interfaces if needed
  #   #   internalInterfaces = [ "ens18" ];  # Add your internal interfaces here
  #   # };
  #   extraCommands = ''
  #     # Forward TCP traffic
  #     iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 10.49.20.20:8080
  #     iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 10.49.20.20:8443
      
  #     # Forward UDP traffic
  #     iptables -t nat -A PREROUTING -p udp --dport 80 -j DNAT --to-destination 10.49.20.20:8080
  #     iptables -t nat -A PREROUTING -p udp --dport 443 -j DNAT --to-destination 10.49.20.20:8443
      
  #     # Enable masquerading (NAT)
  #     iptables -t nat -A POSTROUTING -j MASQUERADE
  #   '';
    
  #   # # Cleanup rules when stopping the firewall
  #   # extraStopCommands = ''
  #   #   iptables -t nat -F PREROUTING
  #   #   iptables -t nat -F POSTROUTING
  #   # '';
    
  #   # Enable firewall and open the required port
  #     enable = lib.mkForce true;
  #     allowedTCPPorts = [ ];
  #     allowedUDPPorts = [ ];
  #     # allowedTCPPortRanges = [{ from = 10; to = 30443; }];
  #     # allowedUDPPortRanges = [{ from = 10; to = 30443; }];
  # };
  
  # systemd.network.networks."10-wan" = {
  #   matchConfig.Name = "enp1s0";
  #   networkConfig = {
  #     # start a DHCP Client for IPv4 Addressing/Routing
  #     DHCP = "ipv4";
  #     # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
  #     IPv6AcceptRA = true;
  #   };
  #   # make routing on this interface a dependency for network-online.target
  #   linkConfig.RequiredForOnline = "routable";
  # };
#  networking = {
#     nat = {
#       enable = true;
#       externalInterface = "ens18";
#       forwardPorts = [
#         {
#           sourcePort = 8443;
#           destination = "10.49.21.1:8443";
#           proto = "tcp";
#           # Specify the external interface if needed
#           #   # uncomment and adjust if needed
#         }
#       ];
#     };
    
#     firewall = {
#       # enable = true;
#       allowedTCPPorts = [ ];
#       allowedUDPPorts = [ ];
#       # allowedTCPPorts = [ 8443 ];
#       # Enable connection tracking
#       # Add explicit rules to ensure both directions work
#       extraCommands = ''
#         iptables -A FORWARD -p tcp --dport 8443 -j ACCEPT
#         iptables -A FORWARD -p tcp --sport 8443 -j ACCEPT
#       '';
#     };
#   };

  environment.systemPackages = with pkgs; [iptables
                                           nftables];

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
