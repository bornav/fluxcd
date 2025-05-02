{ config, lib, inputs, vars, pkgs, pkgs-unstable, ... }:
{
  # boot.kernel = {
  #   sysctl = {
  #     "net.ipv4.conf.all.forwarding" = true;
  #     "net.ipv6.conf.all.forwarding" = false;
  #   };
  # };
  networking = {
  firewall = {
    enable = true;
    allowedTCPPorts = [ 1880 1881 ];
    # extraCommands = lib.mkMerge [ (lib.mkBefore ''


    #   iptables -t nat -A PREROUTING -p tcp --dport 1881 -j DNAT --to-destination 10.99.10.200:1881
    #   iptables -t nat -A POSTROUTING -j MASQUERADE

    # '') ];
  };
  nat = {
    enable = true;
    # internalInterfaces = [ "enp0s3" ];
    # externalInterface = "cilium_net";
    # internalInterfaces = [ "cilium_host" "cilium_net" "wg0" ];
    externalInterface = "enp0s3";
    forwardPorts = [
      {
        sourcePort = 1881;
        proto = "tcp";
        destination = "10.99.10.200:80";
      }
    ];
  };
  nftables = {
        enable = true;
        flushRuleset = true;
        tables."nixos-nat" = {
          family = "ip";
          content = ''
            chain post {
              masquerade
            }
          '';
        };
      };
  # nftables = {
  #   enable = true;};
  #   ruleset = ''
  #       table ip nat {
  #           chain prerouting {
  #               type nat hook prerouting priority dstnat; policy accept;
  #               tcp dport 1881 dnat to 10.49.22.2:443;
  #           }

  #           chain postrouting {
  #               type nat hook postrouting priority srcnat; policy accept;
  #               oifname "enp0s3" masquerade;
  #           }
  #       }
  #   '';
  # };
#   # nat = {
#   #   enable = true;
#   #   internalInterfaces = [ "cilium_host" ];
#   #   externalInterface = "wg0";
#   #   forwardPorts = [
#   #     {
#   #       destination = "10.99.10.200";
#   #       proto = "tcp";
#   #       sourcePort = 1880;
#   #       targetPort = 80;
#   #     }
#   #   ];
#   # };
#   # # Previous section is equivalent to :
#   nftables = {
#     enable = true;
#     ruleset = ''

# flush ruleset

# table ip nat {
#     chain prerouting {
#         type nat hook prerouting priority dstnat;
#         # Forward incoming traffic on port 1880 to internal host 10.99.10.200:80
#         tcp dport 1880 dnat to 10.99.10.200:80
#     }

#     chain postrouting {
#         type nat hook postrouting priority srcnat;
#         # Apply masquerading for traffic going to internal network
#         ip daddr 10.99.10.200 snat to 207.180.245.14
#     }
# }

# table ip filter {
#     chain input {
#         type filter hook input priority 0;
#         policy drop;

#         # Accept established/related connections
#         ct state established,related accept

#         # Allow traffic on loopback
#         iif lo accept

#         # Allow incoming traffic on port 1880
#         tcp dport 1880 accept
#     }

#     chain forward {
#         type filter hook forward priority 0;
#         policy drop;

#         # Allow forwarded traffic to internal IP
#         ip daddr 10.99.10.200 tcp dport 80 accept

#         # Allow return traffic
#         ct state established,related accept
#     }
# }
#     '';
#   };
};
}