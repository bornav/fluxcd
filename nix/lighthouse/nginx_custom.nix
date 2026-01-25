{
  lib,
  pkgs,
  config,
  pkgs-master,
  ...
}: let
  cfg = {
    domain = "netbird.icylair.com";
    clientID = "netbird";
    backendID = "netbird-backend";
    keycloakDomain = "sso.icylair.com";
    keycloakRealmName = "master";
    coturnPasswordPath = "/var/lib/coturnpass.key";
    coturnSalt = "/var/lib/netbird-mgmt/netbird-oidc-secret.key";
    clientSecretPath = "/var/lib/netbird-mgmt/netbird-oidc-secret.key";
    dataStoreEncryptionKeyPath = "/var/lib/netbird-mgmt/storekey.key"; #openssl rand -base64 32
  };
  ingress = {
    stun_port = 3478;
    https = 8443;
  };
in {

  services.nginx = {
    enable = lib.mkDefault true;
    # virtualHosts.${cfg.domain} = {
    #   forceSSL = true;
    #   # onlySSL = true;
    #   sslCertificate = "/cert/tls.crt";
    #   sslCertificateKey = "/cert/tls.key";
    #   # add client_header_timeout
    #   listen = [
    #     {
    #       addr = "127.0.0.1";
    #       ssl = true;

    #       # http2 = true; # TODO
    #       # port = ingress.https;
    #       port = 443;

    #     }
    #     # {
    #     #   addr = "127.0.0.1";
    #     #   ssl = false;
    #     #   # port = ingress.https;
    #     #   port = 80;
    #     # }
    #   ];
    # };
    # upstreams = {
    #   netbird_dashboard = {
    #     servers = {
    #       "127.0.0.1:8080" = {};
    #     };
    #     extraConfig = ''
    #       keepalive 10;
    #     '';
    #   };
    #   netbird_signal.servers = {"127.0.0.1:10000" = {};};
    #   netbird_signal_ws.servers = {"127.0.0.1:8083" = {};};
    #   netbird_managment.servers = {"127.0.0.1:8081" = {};};
    #   netbird_relay.servers = {"127.0.0.1:8084" = {};};
    # };

    # httpConfig = ''
    config = ''
      # daemon off;
      # user nginx;
      worker_processes auto;
      pcre_jit on;
      # error_log /proc/self/fd/2 warn;
      # include /etc/nginx/modules/*.conf;
      events {
     	worker_connections 1024;
                multi_accept on;
            }
            http {
     	# include /etc/nginx/mime.types;
     	default_type application/octet-stream;
     	#resolver 1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001;
     	server_tokens off;
     	client_max_body_size 1m;
     	sendfile on;
     	tcp_nopush on;
     	ssl_protocols TLSv1.2 TLSv1.3;
     	ssl_prefer_server_ciphers on;
     	ssl_session_cache shared:SSL:2m;
     	ssl_session_timeout 1h;
     	ssl_session_tickets off;
     	gzip on;
     	gzip_vary on;
      gzip_proxied any;
      gzip_comp_level 9;
      gzip_buffers 16 8k;
      gzip_http_version 1.1;
      gzip_disable "msie6";
      gzip_types
      application/atom+xml
      application/javascript
      application/x-javascript
      application/json
      application/ld+json
      application/manifest+json
      application/rss+xml
      application/vnd.geo+json
      application/vnd.ms-fontobject
      application/wasm
      application/x-font-ttf
      application/x-web-app-manifest+json
      application/xhtml+xml
      application/xml
      font/opentype
      image/bmp
      image/svg+xml
      image/x-icon
      text/cache-manifest
      text/css
      text/javascript
      text/plain
      text/vcard
      text/vnd.rim.location.xloc
      text/vtt
      text/x-component
      text/x-cross-domain-policy;
     	map $http_upgrade $connection_upgrade {
      		default upgrade;
      		''' close;
     	}
     	log_format main '$remote_addr - $remote_user [$time_local] "$request" '
     			'$status $body_bytes_sent "$http_referer" '
     			'"$http_user_agent" "$http_x_forwarded_for"';
     	# access_log /proc/self/fd/1 main;
     	server {
       	listen 8080 default_server;
        root ${config.services.netbird.server.dashboard.finalDrv};
        location = /netbird.wasm {
            root ${config.services.netbird.server.dashboard.finalDrv};
            default_type application/wasm;
        }
        location = /ironrdp-pkg/ironrdp_web_bg.wasm {
            root ${config.services.netbird.server.dashboard.finalDrv};
            default_type application/wasm;
        }
        location / {
          try_files $uri $uri.html $uri/ =404;
          add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
          expires off;
        }
        error_page 404 /404.html;
        location = /404.html {
            internal;
            add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";
            expires off;
        }
      }

      }

    '';
    # root ${config.services.netbird.server.dashboard.finalDrv};
  };

  # services.nginx.virtualHosts.${cfg.domain}= {
  #   listen = [
  #     {
  #       addr = "0.0.0.0";
  #       port = 8080;
  #     }
  #   ];
  # };
}
