{ config, lib, inputs, vars, pkgs, pkgs-unstable, ... }:
{
  networking = {
  firewall = {
    enable = true;
    allowedTCPPorts = [ 1880 ];
  };
  nat = {
    enable = true;
    internalInterfaces = [ "cilium_host" ];
    externalInterface = "wg0";
    forwardPorts = [
      {
        sourcePort = 1880;
        proto = "tcp";
        destination = "10.99.10.200:80";
      }
    ];
  };
  # # Previous section is equivalent to :
  # nftables = {
  #   enable = true;
  #   ruleset = ''
  #       table ip nat {
  #         chain PREROUTING {
  #           type nat hook prerouting priority dstnat; policy accept;
  #           iifname "ens3" tcp dport 80 dnat to 10.100.0.3:80
  #         }
  #       }
  #   '';
  # };
};
}