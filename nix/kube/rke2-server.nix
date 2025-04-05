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
    - oracle-bv1-1.cloud.icylair.com
    - oracle-km1-1.cloud.icylair.com
    - oraclearm3.cloud.icylair.com
    - contabo-1.cloud.icylair.com
    - k3s-local-01.local.icylair.com
    - k3s-local-01
    - k3s-local-02.local.icylair.com
    - k3s-local-02
    - oracle-bv1-1
    - oracle-km1-1
    - contabo-1
    - k3s-oraclearm3
    - rke2-oraclearm3
    - rke2-local-example.local.icylair.com
    - rke2-local.local.icylair.com
    - lb.local.icylair.com
    - lb.cloud.icylair.com
  kube-apiserver-extra-mount: 
    - /etc/localtime:/etc/localtime:ro
  kube-scheduler-extra-mount:
    - /etc/localtime:/etc/localtime:ro
  kube-controller-manager-extra-mount:
    - /etc/localtime:/etc/localtime:ro
  etcd-extra-mount:
    - /etc/localtime:/etc/localtime:ro
  # kube-apiserver-extra-env:
  #   - "MY_FOO=FOO"
  #   - "MY_BAR=BAR"
  # kube-scheduler-extra-env:
  #   - "TZ=Europe/Vienna"
  '';
  server=# first init uncomment the ip based once, after the loadbalancer, origin one needs both commented out
  ''
  server: https://lb.cloud.icylair.com:9345  
  # server: https://10.99.10.11:9345
  '';
  combined_config = if host.kube_ha then
    node_config + "\n" + tls_san + "\n" + server
  else
    node_config + "\n" + tls_san;
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
    name = "iqn.2005-10.org.freenas.ctl:${config.networking.hostName}";
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
    conntrack-tools

    
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
    "L+ /sbin - - - - /run/current-system/sw/bin/"
    "L! /lib/modules - - - - /run/current-system/kernel-modules/lib/modules/"   # make current modules exposed to /lib/modules
  ];


}
