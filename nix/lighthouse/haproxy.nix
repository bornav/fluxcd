{
  config,
  inputs,
  system,
  host,
  vars,
  lib,
  pkgs,
  ...
}: {
  # systemd.services.haproxy-wait-for-cert = { # not terminating tls so no point in doing this
  #   serviceConfig.Type = "oneshot";
  #   requiredBy = [
  #     "haproxy.service"
  #   ];
  #   before = [
  #     "haproxy.service"
  #   ];
  #   script = ''
  #       until [ -f ${cert_path} ]; do sleep 1; done
  #   '';
  # };
  services.haproxy.enable = true;
  services.haproxy.config = lib.mkMerge [
    # global
    ''
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
          ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
          ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

      # Default settings
      defaults
          log     global
          option  tcplog
          option  dontlognull
          timeout connect 5000
          timeout client  86400000  # 1 day for long-running connections
          timeout server  86400000  # 1 day for long-running connections
          timeout tunnel  86400000  # 1 day for WebSocket/long-polling
    ''
    # https 443
    ''
      # Frontend for TLS passthrough
      frontend https-in
          bind *:443
          # mode tcp
          option tcplog
          tcp-request inspect-delay 5s
          tcp-request content accept if { req_ssl_hello_type 1 }
          ${lib.optionalString config.services.headscale.enable
        ''
          use_backend headscale_backend if { req_ssl_sni -i headscale.icylair.com }
        ''}
          ${lib.optionalString (config.systemd.services ? podman-netbird-dashboard.enable) # defined in netbird.nix file | ${lib.optionalString config.services.netbird.server.enable
        ''
          # acl is_http_domain req_ssl_sni -i netbird.icylair.com www.netbird.icylair.com
          # use_backend https_frontend_backend if is_http_domain

          # use_backend https_frontend_backend if { req_ssl_sni -i netbird.icylair.com }
        ''}

          # Load balancing between two backend servers
          default_backend 443-forward

      backend 443-forward
          mode tcp
          balance leastconn
          option ssl-hello-chk

          server vxlan-lb-vip 10.129.16.100:443 send-proxy-v2 check
          # Back-up nodes - activated only if *all* non-backup servers are down
          server oracle-km1-1 10.99.10.11:443 send-proxy-v2 check backup
          server oracle-bv1-1 10.99.10.12:443 send-proxy-v2 check backup
          server hetzner-01   10.99.10.13:443 send-proxy-v2 check backup
          # Optional: once server1 recovers, instantly shift traffic back to it
          option allbackups # let backups share traffic only while primary is dead
    ''
    # http 80
    ''
      frontend 80-forward
          bind *:80
          mode tcp
          option tcplog
          default_backend 80_backends
      backend 80_backends
          mode tcp
          balance leastconn

          server vxlan-lb-vip 10.129.16.100:80 check
          # Back-up nodes - activated only if *all* non-backup servers are down
          server oracle-km1-1 10.99.10.11:80 check backup
          server oracle-bv1-1 10.99.10.12:80 check backup
          server hetzner-01   10.99.10.13:80 check backup
          # Optional: once server1 recovers, instantly shift traffic back to it
          option allbackups # let backups share traffic only while primary is dead
    ''
    # control plane 6443
    ''
      frontend 6443_control_plane
          bind *:6443
          mode tcp
          option tcplog
          default_backend 6443_backend
      backend 6443_backend
          mode tcp
          balance leastconn
          option tcp-check

          server vxlan-lb-vip 10.129.16.2:6443 check
          # Back-up nodes - activated only if *all* non-backup servers are down
          server oracle-km1-1 10.99.10.11:6443 check backup
          server oracle-bv1-1 10.99.10.12:6443 check backup
          server hetzner-01   10.99.10.13:6443 check backup
          # Optional: once server1 recovers, instantly shift traffic back to it
          option allbackups # let backups share traffic only while primary is dead
    ''
    # api plane 9345
    ''
      frontend 9345_api_plane
          bind *:9345
          mode tcp
          option tcplog
          default_backend 9345_backend
      backend 9345_backend
          mode tcp
          balance leastconn
          option tcp-check

          # https://10.129.16.2:9345/v1-rke2/readyz good endpoint, but figure out how to have the token before this is usable as health endpoint is forbiden without token
          server vxlan-lb-vip 10.129.16.2:9345 check
          # Back-up nodes - activated only if *all* non-backup servers are down
          server oracle-km1-1 10.99.10.11:9345 check backup
          server oracle-bv1-1 10.99.10.12:9345 check backup
          server hetzner-01   10.99.10.13:9345 check backup
          option allbackups # let backups share traffic only while primary is dead
    ''
    # headscale 8080
    ''
      ${lib.optionalString config.services.headscale.enable ''
        frontend headscale
            bind *:8080
            mode tcp
            option tcplog
            default_backend headscale_backend
        backend headscale_backend
            mode tcp
            server server1 127.0.0.1:10023
      ''}
    ''
    ''
      frontend stats
        mode http
        bind 127.0.0.1:8404
        stats enable
        stats refresh 10s
        stats uri /stats
        stats show-modules
        stats admin if TRUE
    ''
  ];
  environment.systemPackages = with pkgs; [
    haproxy
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 6443 8080 9345 10022 30033];
  };
}
