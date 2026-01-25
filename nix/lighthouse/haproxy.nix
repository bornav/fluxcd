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
          mode tcp
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

          server vxlan-lb 10.129.16.100:443 send-proxy-v2 check

            # Back-up nodes - activated only if *all* non-backup servers are down
          server oracle-km1-1 10.99.10.11:443 send-proxy-v2 check backup
          server oracle-bv1-1 10.99.10.12:443 send-proxy-v2 check backup
          server contabo-1 10.99.10.13:443 send-proxy-v2 check backup

          # Optional: once server1 recovers, instantly shift traffic back to it
          option  allbackups        # let backups share traffic only while primary is dead
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
          server server1 oracle-bv1-1.cloud.icylair.com:80 check
          server server2 oracle-km1-1.cloud.icylair.com:80 check
          server server3 contabo-1.cloud.icylair.com:80 check
    ''
    # api plane 6443
    ''
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
    ''
    # control plane 9345
    ''
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
  ];
  environment.systemPackages = with pkgs; [
    haproxy
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 6443 8080 9345 10022 30033];
  };
}
