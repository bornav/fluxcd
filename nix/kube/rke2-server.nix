{ config, lib, system, inputs, host, node_config, vars, pkgs, ... }:
let
  # inherit host;
  # pkgs = import inputs.nixpkgs-stable { #TODO figure out why i cant migrate this one
  #   system = host.system;
  #   config.allowUnfree = true;
  # };
  tls_san = 
  ''
  tls-san:
    - 10.0.0.71
    - 10.0.0.100
    - 10.2.11.24
    - 10.2.11.25
    - 10.2.11.36
    - 10.2.11.38
    - 10.2.11.41
    - 10.2.11.42
    - 10.99.10.10
    - 10.99.10.11
    - 10.99.10.12
    - 10.99.10.13
    - 10.99.10.14
    - 10.99.10.15
    - 10.99.10.51
    - oraclearm1.cloud.icylair.com
    - oraclearm2.cloud.icylair.com
    - oraclearm3.cloud.icylair.com
    - contabo-01-4v-8m-800g.cloud.icylair.com
    - k3s-local-01.local.icylair.com
    - k3s-local-01
    - k3s-local-02.local.icylair.com
    - k3s-local-02
    - k3s-oraclearm1
    - k3s-oraclearm2
    - k3s-oraclearm3
    - rke2-oraclearm1
    - rke2-oraclearm2
    - rke2-oraclearm3
    - contabo-01-4v-8m-800g
    - rke2-local-example.local.icylair.com
    - rke2-local.local.icylair.com
    - lb.local.icylair.com
    - lb.cloud.icylair.com
  '';
  combined_config = node_config + "\n" + tls_san;
in
{
  imports = [( import ./rke2-server-spec.nix)];
  # options = {
  #   rke2 = {
  #     server = lib.mkOption {
  #       type = lib.types.bool;
  #       default = false;
  #     };
  #     client = lib.mkOption {
  #       type = lib.types.bool;
  #       default = false;
  #     };    
  #   };
  # };
  # config = {
  # k3s specific
  networking.useNetworkd = true;
  networking.firewall.enable = true;  ## recent change, if stuff breaks this is prob it
  networking.firewall = {
    allowedTCPPorts = [
      6443 # RKE2 api server
      9345 # RKE2 controll plane
      2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
      2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
      443 8443 # https
      80 8080 # http
       
      22 # ssh

      9987 10011 30033 # TS3
    ];
    allowedTCPPortRanges = [
    { from = 4; to = 65535; }
    ];
    # allowedUDPPorts = [
    #   # 8472 # k3s, flannel: required if using multi-node for inter-node networking
    #   443 8443 # https
    #   80 8080 # http

    #   9987 10011 30033 # TS3


    #   51872 # wg-mesh

    # ];
    allowedUDPPortRanges = [
    { from = 4; to = 65535; }
    ];
  };
  # # Given that our systems are headless, emergency mode is useless.
  # # We prefer the system to attempt to continue booting so
  # # that we can hopefully still access it remotely.
  # systemd.enableEmergencyMode = false;
  system.activationScripts.usrlocalbin = ''  
      mkdir -m 0755 -p /usr/local
      ln -nsf /run/current-system/sw/bin /usr/local/
  ''; # TODO look into, potentialy undeeded

  systemd.watchdog.rebootTime = "2m";

  # environment.etc."rancher/rke2/config.yaml".source = pkgs.writeText "config.yaml" node_config;
  environment.etc."rancher/rke2/config.yaml".source = pkgs.writeText "config.yaml" combined_config;
  # services.rke2 = {
  #   package = pkgs-unstable.rke2_latest;
  #   # package = pkgs.rke2;
  #   # clusterInit=true;
  #   role=kube-role;
  #   tokenFile ="/var/token";
  #   enable = true;
  #   configPath = "/etc/rancher/rke2";
  #   # cni = "cilium";
  #   # cni = if kube-role == "agent" then "canal" else "none"; # canal is default
  #   extraFlags = [ # space at the start important ! :|
  #     # " --disable rke2-kube-proxy"
  #     " --kube-apiserver-arg default-not-ready-toleration-seconds=30"
  #     " --kube-apiserver-arg default-unreachable-toleration-seconds=30" 
  #     " --kube-controller-manager-arg node-monitor-period=20s"
  #     " --kube-controller-manager-arg node-monitor-grace-period=20s" 
  #     " --kubelet-arg node-status-update-frequency=5s"
  #   ];
  #   # extraFlags = toString ([
	#   #   "--write-kubeconfig-mode \"0644\""
	#   #   "--disable rke2-kube-proxy"
	#   #   "--disable rke2-canal"
	#   #   "--disable rke2-coredns"
  #   #   "--disable rke2-ingress-nginx"
  #   #   "--disable rke2-metrics-server"
  #   #   "--disable rke2-service-lb"
  #   #   "--disable rke2-traefik"
  #   # ] ++ (if meta.hostname == "homelab-0" then [] else [
	#   #     "--server https://homelab-0:6443"
  #   # ]));
  # };

  services.openiscsi = {
    enable = true;
    name = "iqn.2000-05.edu.example.iscsi:${config.networking.hostName}";
  };
  services.nfs.server.enable = true;
  # services.nfs.settings = {
  #     nfsd.udp = false;
  #     nfsd.vers3 = false;
  #     nfsd.vers4 = true;
  #     nfsd."vers4.0" = true;
  #     nfsd."vers4.1" = true;
  #     nfsd."vers4.2" = true;
  #   };
  

  environment.systemPackages = with pkgs; [
    nfs-utils
    openiscsi
    wireguard-tools
    python3
    cilium-cli
    cni-plugins
    cifs-utils
    git
    kubectl
    # k3s_1_30
    vim
    nano
    # rke2
    k9s
    tcpdump

    util-linux ## longhorn nsenter, seems nsenter is available without this

  ];
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    #"zfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
    "nfs" # required by longhorn
  ];
  services.rpcbind.enable = true;
  services.kubernetes.apiserver.allowPrivileged = true;
  boot.initrd = {
    supportedFilesystems = [ "nfs" ];
    kernelModules = [ "nfs" ];
    availableKernelModules = [ "dm_crypt" ];
  };
  boot.kernelModules = [ "rbd" "br_netfilter" "ceph"];
  
  virtualisation.docker.logDriver = "json-file";
  # virtualisation.containerd = {
  #   enable = true;
  #   # settings =
  #   #   let
  #   #     fullCNIPlugins = pkgs.buildEnv {
  #   #       name = "full-cni";
  #   #       paths = with pkgs;[
  #   #         cni-plugins
  #   #         cni-plugin-flannel
  #   #       ];
  #   #     };
  #   #   in {
  #   #     plugins."io.containerd.grpc.v1.cri".cni = {
  #   #       bin_dir = "${fullCNIPlugins}/bin";
  #   #       conf_dir = "/var/lib/rancher/k3s/agent/etc/cni/net.d/";
  #   #     };
  #   #     # Optionally set private registry credentials here instead of using /etc/rancher/k3s/registries.yaml
  #   #     # plugins."io.containerd.grpc.v1.cri".registry.configs."registry.example.com".auth = {
  #   #     #  username = ""; 
  #   #     # };
  #   # };
  # }; 


  # TODO lookinto
  # https://github.com/ryan4yin/nix-config/blob/36ba5a4efcc523f45f391342ef49bee07261c22d/lib/genKubeVirtHostModule.nix#L62
  # boot.kernel.sysctl = {
  #   # --- filesystem --- #
  #   # increase the limits to avoid running out of inotify watches
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;

  #   # --- network --- #

    # net.ipv4.ip_local_reserved_ports=30000-32767
    "net.bridge.bridge-nf-call-iptables"=1;
    "net.bridge.bridge-nf-call-arptables"=1;
    "net.bridge.bridge-nf-call-ip6tables"=1;
    "net.core.somaxconn" = 32768;
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.neigh.default.gc_thresh1" = 4096;
    "net.ipv4.neigh.default.gc_thresh2" = 6144;
    "net.ipv4.neigh.default.gc_thresh3" = 8192;
    "net.ipv4.neigh.default.gc_interval" = 60;
    "net.ipv4.neigh.default.gc_stale_time" = 120;

    "net.ipv4.conf.all.send_redirects"=0;
    # net.ipv4.conf.default.send_redirects=0
    # net.ipv4.conf.default.accept_source_route=0
    "net.ipv4.conf.all.accept_redirects"=0;
    # net.ipv4.conf.default.accept_redirects=0
    # net.ipv4.conf.all.log_martians=1
    # net.ipv4.conf.default.log_martians=1
    # net.ipv4.conf.all.rp_filter=1
    # net.ipv4.conf.default.rp_filter=1

    # "net.ipv6.conf.all.disable_ipv6" = 1; # disable ipv6
    # net.ipv6.conf.all.accept_ra=0
    # net.ipv6.conf.default.accept_ra=0
    # net.ipv6.conf.all.accept_redirects=0
    # net.ipv6.conf.default.accept_redirects=0
    "kernel.keys.root_maxbytes"=25000000;
    "kernel.keys.root_maxkeys"=1000000;
    "kernel.panic"=10;
    "kernel.panic_on_oops"=1;
    "vm.overcommit_memory"=1;
    "vm.panic_on_oom"=0;
    "vm.swappiness" = 0; # don't swap unless absolutely necessary
  };

  # longhorn specific so it has /boot/config kernel modules file to read
  systemd.services.save-kernel-config = {
    description = "Save kernel config to boot directory";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.gzip}/bin/zcat /proc/config.gz > /boot/config-$(${pkgs.coreutils}/bin/uname -r)'";
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"                   # exposes binaryes
    "L! /lib/modules - - - - /run/current-system/kernel-modules/lib/modules/"   # make current modules exposed to /lib/modules
  ];


}
