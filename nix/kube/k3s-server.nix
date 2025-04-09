{ config, lib, system, inputs, node_config, vars, pkgs, pkgs-unstable, ... }:
{
  # k3s specific
  # environment.etc."rancher/rke2/config.yaml".source = pkgs.writeText "config.yaml" master4;
  # services.rke2 = {
  #   package = pkgs.rke2;
  #   enable = true;
  #   # cni = "cilium";
  #   cni = "none";
  # };

  # # Given that our systems are headless, emergency mode is useless.
  # # We prefer the system to attempt to continue booting so
  # # that we can hopefully still access it remotely.
  # systemd.enableEmergencyMode = false;
  system.activationScripts.usrlocalbin = ''  
      mkdir -m 0755 -p /usr/local
      ln -nsf /run/current-system/sw/bin /usr/local/
  ''; # TODO look into, potentialy undeeded
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  systemd.watchdog.rebootTime = "3m";
  environment.etc."rancher/k3s/config.yaml".source = pkgs.writeText "config.yaml" node_config;
  services.k3s = {
    package = pkgs.k3s_1_30;
    enable = true;
    # tokenFile="/var/token";
    # # role = "server";
    # # token = "<randomized common secret>";
    # # clusterInit = true;
    # # extraFlags = toString [
    # #   "--container-runtime-endpoint unix:///run/containerd/containerd.sock"
    # # # "--kubelet-arg=v=4" # Optionally add additional args to k3s
    # # ];
    configPath = "/etc/rancher/k3s/config.yaml";
    # # serverAddr = "https://<ip of first node>:6443";
  };
  services.openiscsi = {
    enable = true;
    name = "iqn.2000-05.edu.example.iscsi:${config.networking.hostName}";
  };
  # services.nfs.server.enable = true;
  environment.systemPackages = with pkgs; [
    nfs-utils
    wireguard-tools
    python3
    cilium-cli
    cni-plugins
    cifs-utils
    git
    kubectl
    k3s_1_30
    vim
    nano
    # rke2
    k9s

    nettools
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
  };
  boot.kernelModules = [ "rbd" "br_netfilter" ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

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
}
