{ config, inputs, system, host, vars, lib, pkgs, ... }:
{
  services.haproxy.enable = true;
  services.haproxy.config = ''
    global
        log /dev/log    local0
        log /dev/log    local1 notice
        # chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        stats timeout 30s
        user haproxy
        group haproxy
        daemon

        # SSL-related options to improve performance and security
        tune.ssl.default-dh-param 2048

    # Default settings
    defaults
        log     global
        option  tcplog
        option  dontlognull
        timeout connect 5s
        timeout client  30s
        timeout server  30s
    # Frontend for TLS passthrough

    frontend https-in
        bind *:443
        mode tcp
        option tcplog
        tcp-request inspect-delay 5s
        tcp-request content accept if { req_ssl_hello_type 1 }
        # use_backend 443-forward if { req_ssl_sni -i headscale.icylair.com/admin } # seems to work
        use_backend headscale_backend if { req_ssl_sni -i headscale.icylair.com }
        # Load balancing between two backend servers
        default_backend 443-forward

    backend 443-forward
        mode tcp
        balance leastconn
        option ssl-hello-chk

        server vxlan-lb 10.129.16.100:443 send-proxy-v2 check

         # Back-up nodes - activated only if *all* non-backup servers are down
        server oracle-km1-1 10.99.10.11:443 send-proxy-v2 check backup
        server oracle-bv1-1 10.99.10.12:443 send-proxy-v2 check backup
        server contabo-1 10.99.10.13:443 send-proxy-v2 check backup

        # Optional: once server1 recovers, instantly shift traffic back to it
        option  allbackups        # let backups share traffic only while primary is dead

    frontend 80-forward
        bind *:80
        mode tcp
        option tcplog
        default_backend 80_backends
    backend 80_backends
        mode tcp
        balance leastconn
        server server1 oracle-bv1-1.cloud.icylair.com:80 check
        server server2 oracle-km1-1.cloud.icylair.com:80 check
        server server3 contabo-1.cloud.icylair.com:80 check

    frontend 6443-forward
        bind *:6443
        mode tcp
        option tcplog
        default_backend 6443_backends
    backend 6443_backends
        mode tcp
        balance roundrobin
        option tcp-check
        server control-plane-1 oracle-km1-1.cloud.icylair.com:6443 check
        server control-plane-2 oracle-bv1-1.cloud.icylair.com:6443 check
        server control-plane-3 contabo-1.cloud.icylair.com:6443 check
    
    frontend control_plane
        bind *:9345
        mode tcp
        option tcplog
        default_backend control_plane_backend
    backend control_plane_backend
        mode tcp
        balance roundrobin
        option tcp-check

        #     mode tcp
        #     balance roundrobin
        #     option httpchk
        #     http-check connect ssl alpn h2
        #     http-check send meth HEAD uri /cacerts  # this works but unneccesary

        server control-plane-1 10.99.10.11:9345 check
        server control-plane-2 10.99.10.12:9345 check
        server control-plane-3 10.99.10.13:9345 check
    
    frontend headscale
        bind *:8080
        mode tcp
        option tcplog
        default_backend headscale_backend
    backend headscale_backend
        mode tcp
        server server1 127.0.0.1:10023
        
    # frontend udp-9987
    #     bind *:9987 udp
    #     mode tcp
    #     option tcplog
    #     default_backend udp_9987_backend
    # backend udp_9987_backend
    #     mode tcp
    #     balance roundrobin
    #     server server1 oracle-bv1-1.cloud.icylair.com:9987 check
    #     server server2 oracle-km1-1.cloud.icylair.com:9987 check

    # frontend tcp-30033
    #     bind *:30033
    #     mode tcp
    #     option tcplog
    #     default_backend tcp_30033_backend
    # backend tcp_30033_backend
    #     mode tcp
    #     balance roundrobin
    #     server server1 oracle-bv1-1.cloud.icylair.com:30033 check
    #     server server2 oracle-km1-1.cloud.icylair.com:30033 check
    
    # frontend ssh-forward
    #     bind *:10022
    #     mode tcp
    #     option tcplog
    #     default_backend ssh_forward_backend
    # backend ssh_forward_backend
    #     mode tcp
    #     balance roundrobin
    #     server server1 oracle-bv1-1.cloud.icylair.com:22 check
    #     server server2 oracle-km1-1.cloud.icylair.com:22 check
    #     server server3 contabo-1.cloud.icylair.com:22 check

    # frontend catch_rest
    #     # bind *:1-21
    #     bind *:8443-65535
    #     mode tcp
    #     option tcplog
    #     default_backend catch_rest
    # backend catch_rest
    #     mode tcp
    #     balance roundrobin
    #     server server1 oracle-bv1-1.cloud.icylair.com check
    #     server server2 oracle-km1-1.cloud.icylair.com check
    '';
  environment.systemPackages = with pkgs; [
    haproxy
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 6443 8080 9345 10022 30033];
  };
}