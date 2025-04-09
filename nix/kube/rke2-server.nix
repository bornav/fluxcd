{ config, lib, system, inputs, host, node_config, vars, pkgs, ... }:
let
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

  services.openiscsi = {
    enable = true;
    name = "iqn.2005-10.org.freenas.ctl:${config.networking.hostName}";
  };
  services.nfs.server.enable = true;
  

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
    # "L+ /sbin - - - - /run/current-system/sw/bin/"
    # "L+ /usr/sbin - - - - /run/current-system/sw/bin/"
    "L! /lib/modules - - - - /run/current-system/kernel-modules/lib/modules/"   # make current modules exposed to /lib/modules
  ];


}
