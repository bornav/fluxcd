{ config, lib, host, inputs, pkgs, pkgs-unstable, ... }:
{
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 7000 ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ens18" ];
      externalInterface = "ens18";
      forwardPorts = [
        {
          sourcePort = 7000;
          proto = "tcp";
          destination = "10.2.11.200:80";
        }
      ];
    };
    # Previous section is equivalent to :
    nftables = {
      enable = true;
      ruleset = ''
          table ip nat {
            chain PREROUTING {
              type nat hook prerouting priority dstnat; policy accept;
              iifname "ens18" tcp dport 7000 dnat to 10.33.48.222:7000
            }
          }
      '';
    };
  };
}
