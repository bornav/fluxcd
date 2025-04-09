{ config, lib, system, inputs, host, vars, pkgs, pkgs-unstable, ... }:
{
  networking.hostName = host.hostName; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "cilium_host" "cilium_net" "lxc+" ];
  networking.firewall.checkReversePath = false;

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
}
