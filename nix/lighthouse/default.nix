{ config, lib, host, inputs, pkgs, pkgs-unstable, pkgs-master, ... }:
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
    ./vxlan.nix
    ./traefik.nix
    ./haproxy.nix
    ./headscale.nix
    {_module.args.disks = [ "/dev/sda" ];}


    # inputs.headplane.nixosModules.headplane
    # {
    #   # provides `pkgs.headplane` and `pkgs.headplane-agent`.
    #   nixpkgs.overlays = [ inputs.headplane.overlays.default ];
    # }
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs-unstable.linuxKernel.packages.linux_6_8;
  # boot.kernelPackages = pkgs-master.linuxPackages_testing;
  boot.kernelModules = [ "rbd" "br_netfilter" ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.loader = {
    timeout = 1;
    grub.enable = true;
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = true;
  };
  # services.nginx.enable = true;
  # services.nginx.config = ''
  #   events {
  #       worker_connections 1024;  # You can adjust this based on your expected traffic
  #   }

  #   stream {
  #       # Define the upstream (backend) servers
  #       upstream backend_servers {
  #           # The two HTTPS servers (port 443)
  #           server 138.3.244.139:443;
  #           server 141.144.255.9:443;
  #       }

  #       # Define the proxy server
  #       server {
  #           # The port on which NGINX will listen for HTTPS connections
  #           listen 443;
  #           proxy_pass backend_servers;

  #           # Enable proxying the SSL/TLS traffic without terminating it (TLS passthrough)
  #           proxy_protocol off;  # Disables Proxy Protocol if enabled by upstream
  #       }
  #   }
  # '';
  networking.hostName = host.hostName; # Define your hostname.
  programs.nh.enable = true;
  services = {
    openssh = {                             # SSH
      enable = true;
      allowSFTP = true;                     # SFTP
      extraConfig = ''
        HostKeyAlgorithms +ssh-rsa
      '';
      settings.PasswordAuthentication = true;
      settings.KbdInteractiveAuthentication = true;
      settings.PermitRootLogin = "yes";
    };
    xserver = {
      xkb.layout = "us";
      xkb.variant = "";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEGiVyNsVCk2KAGfCGosJUFig6PyCUwCaEp08p/0IDI7"];
  users.users.root.initialPassword = "nixos";
  users.users.${host.vars.user} = {
    isNormalUser = true;
    initialPassword = "nixos";
    description = "${host.vars.user}";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    # packages = with pkgs; [];
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEGiVyNsVCk2KAGfCGosJUFig6PyCUwCaEp08p/0IDI7"];
  };
  time.timeZone = "Europe/Vienna";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_AT.UTF-8";
      LC_IDENTIFICATION = "de_AT.UTF-8";
      LC_MEASUREMENT = "de_AT.UTF-8";
      LC_MONETARY = "de_AT.UTF-8";
      LC_NAME = "de_AT.UTF-8";
      LC_NUMERIC = "de_AT.UTF-8";
      LC_PAPER = "de_AT.UTF-8";
      LC_TELEPHONE = "de_AT.UTF-8";
      LC_TIME = "de_AT.UTF-8";
    };
  };
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    jq
    gparted
    pciutils # lspci
    zip
    p7zip
    unzip
    unrar
    gnutar
    ser2net
    par2cmdline
    rsync
    vim
    nfs-utils
    wireguard-tools
    python3
    cilium-cli
    cni-plugins
    cifs-utils
    git
    kubectl
    vim
    nano
    inetutils
    nettools
    util-linux
  ];
  system.stateVersion = "${host.vars.stateVersion}";
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=20s
  ''; # sets the systemd stopjob timeout to somethng else than 90 seconds
  nix = {
    settings.auto-optimise-store = true;
    gc = {                                  # Garbage Collection
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes";
    settings.max-jobs = 4;
  };
  networking.useDHCP = lib.mkForce false; # forcing dissable cus of systemd network
  systemd.network.enable = true;
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
  # systemd.network.wait-online.enable = false;
  # boot.initrd.systemd.network.wait-online.enable = false;

  # wirenix = {
  #   enable = true;
  #   peerName = "node1"; # defaults to hostname otherwise
  #   configurer = "static"; # defaults to "static", could also be "networkd"
  #   keyProviders = ["acl"]; # could also be ["agenix-rekey"] or ["acl" "agenix-rekey"]
  #   # secretsDir = ./secrets; # only if you're using agenix-rekey
  #   aclConfig = import ./mesh.nix;
  # };

  # networking.nat.forwardPorts = 
  # [
  #   {
  #     destination = "oracle-km1-1.cloud.icylair.com:80";
  #     proto = "tcp";
  #     sourcePort = 80;
  #   }
  #   {
  #     destination = "oracle-km1-1.cloud.icylair.com:443";
  #     proto = "tcp";
  #     sourcePort = 443;
  #   }
  # ];
  
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 3000 6443 8080 9345 10022];
    allowedUDPPortRanges = [
      { from = 1000; to = 6550; }
    ];
  };

  # #ipv6
  # # networking.interfaces.eth0.name = "eth0";
  # networking = {
  #   interfaces.eth0 = {
  #     name = "eth0";
  #     useDHCP = true;
  #     ipv6 = {
  #       addresses = [ "2001:db8:0:3df1::1/64" ];
  #       routes = [
  #         {
  #           to = "default";
  #           via = "fe80::1";
  #         }
  #       ];
  #     };
  #   };
  # };
  # networking.nameservers = {
  #   ipv6 = {
  #     addresses = [ "2a01:4ff:ff00::add:2" "2a01:4ff:ff00::add:1" ];
  #   };
  # };
  # ####
  # services.caddy = {
  #   enable = true;
  #   virtualHosts."lb.cloud.icylair.com".extraConfig = ''
  #     reverse_proxy * 127.0.0.1:8080
  #   '';
  # };
  
  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "ebe7fbd44549ab73"
    ];
  };

  # systemd.services.expose-bridge-binary = {
  #   description = "expose binary";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "local-fs.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.bash}/bin/bash -c 'ln -s  ${pkgs.iproute2}/bin/bridge /bin/bridge2'";
  #   };
  # };


  # systemd.tmpfiles.rules = [
  #   "L+ ${pkgs.iproute2}/bin - - - - /root/bin/"                   # exposes binaryes
  # ];  
} 
