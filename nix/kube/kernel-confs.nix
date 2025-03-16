{ config, lib, system, inputs, host, node_config, vars, pkgs, ... }:
{ 
  boot.kernelModules = [ "rbd" "br_netfilter" "ceph"];
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
}
