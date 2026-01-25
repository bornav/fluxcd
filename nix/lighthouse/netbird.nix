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
  # source_path file content example
  # export AWS_ACCESS_KEY_ID=<token_id>
  # export AWS_SECRET_ACCESS_KEY=<token>
  # export RESTIC_PASSWORD=<restic_pass>
  # export RESTIC_REPOSITORY=s3:http://<s3_endpoint>/restic-host-bucket/cloud/netbird
  # # restic backup /var/lib/netbird-mgmt
  source_path = "/var/lib/.restic_netbird";
  cert_path = "/cert";
in {
  # systemd.services.netbird-restore-data = {
  #   serviceConfig.Type = "oneshot";
  #   requiredBy = [
  #     "netbird-management.service"
  #     "netbird-signal.service"
  #     "coturn.service"
  #     # "nginx.service"
  #   ];
  #   before = [
  #     "netbird-management.service"
  #     "netbird-signal.service"
  #     "coturn.service"
  #     # "nginx.service"
  #   ];
  #   preStart = ''
  #     until [ -f ${source_path} ]; do sleep 1; done
  #   '';
  #   script = ''
  #     if [ -d "/var/lib/netbird-mgmt" ]; then
  #         echo "restore exists, exiting..."
  #         exit 0
  #     fi
  #     source ${source_path}
  #     ${pkgs.restic}/bin/restic restore latest --target /  # the / as during backup it creates a full path to the folder
  #     # cp /var/lib/netbird-mgmt/coturnpass.key /var/lib/coturnpass.key
  #   '';
  # };

  # systemd.services.nginx-wait-for-cert = {
  #   serviceConfig.Type = "oneshot";
  #   requiredBy = [
  #     # "nginx.service"
  #     "netbird-management.service"
  #     "netbird-signal.service"
  #   ];
  #   before = [
  #     # "nginx.service"
  #     "netbird-management.service"
  #     "netbird-signal.service"
  #   ];
  #   script = ''
  #     until [ -f ${cert_path}/tls.crt ] && [ -f ${cert_path}/tls.key ]; do sleep 1; done
  #   '';
  # };

  # nixpkgs.overlays = [ # working package overlasy as of 24.01.26 just moving to docker for now
  #   (final: prev: {
  #     netbird-dashboard = prev.netbird-dashboard.overrideAttrs (oldAttrs: rec {
  #       # untested
  #       version = "2.28.0";
  #       src = prev.fetchFromGitHub {
  #         owner = "netbirdio";
  #         repo = "dashboard";
  #         rev = "v${version}";
  #         hash = "sha256-GBGfH3YWqdAsQiezCY9oFanoWtU4PcepokgozEgcBiQ=";
  #       };
  #       npmDeps = prev.fetchNpmDeps {
  #         inherit src;
  #         hash = "sha256-e4Uxy1bwR3a+thIkaNWpAwDvIJyTbM5TwVy+YVD0CQQ=";
  #       };
  #     });
  #   })
  #   (final: prev: {
  #     netbird-signal = prev.netbird-signal.overrideAttrs (oldAttrs: rec {
  #       version = "0.64.0";
  #       src = prev.fetchFromGitHub {
  #         owner = "netbirdio";
  #         repo = "netbird";
  #         rev = "v${version}";
  #         hash = "sha256-3E8kdSJLturNxUoG66LxqWudVTGOObLtimmdoKZiKPs";
  #       };
  #       vendorHash = "sha256-LeY6bnn3aZdG+NeVlvzByvump03A6GhGJW4Bld2bGoc=";
  #     });
  #   })
  #   (final: prev: {
  #     netbird-management = prev.netbird-management.overrideAttrs (oldAttrs: rec {
  #       version = "0.64.0";
  #       src = prev.fetchFromGitHub {
  #         owner = "netbirdio";
  #         repo = "netbird";
  #         rev = "v${version}";
  #         hash = "sha256-3E8kdSJLturNxUoG66LxqWudVTGOObLtimmdoKZiKPs";
  #       };
  #       vendorHash = "sha256-LeY6bnn3aZdG+NeVlvzByvump03A6GhGJW4Bld2bGoc=";
  #     });
  #   })
  # ];
  # services.netbird.server = {
  #   domain = cfg.domain;
  #   enable = true;
  #   enableNginx = false;
  #   signal = {
  #     # package = pkgs-master.netbird-signal; # check override on the top
  #     # package = pkgs.netbird-signal.overrideAttrs (oldAttrs: rec {
  #     #   version = "0.64.0";
  #     #   src = pkgs.fetchFromGitHub {
  #     #     owner = "netbirdio";
  #     #     repo = "netbird";
  #     #     tag = "v${version}";
  #     #     hash = "sha256-3E8kdSJLturNxUoG66LxqWudVTGOObLtimmdoKZiKPs";
  #     #   };
  #     #   vendorHash = "sha256-LeY6bnn3aZdG+NeVlvzByvump03A6GhGJW4Bld2bGoc=";
  #     # });
  #     port = 8083;
  #     metricsPort = 9092;
  #   };
  #   dashboard = {
  #     enableNginx = false;
  #     enable = true;
  #     # package = pkgs-master.netbird-dashboard;
  #     # package = pkgs.netbird-dashboard;

  #     settings = {
  #       # Endpoints
  #       NETBIRD_MGMT_API_ENDPOINT = "https://netbird.icylair.com";
  #       NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://netbird.icylair.com";
  #       # OIDC - using embedded IdP
  #       AUTH_AUDIENCE = "netbird-dashboard";
  #       AUTH_CLIENT_ID = "netbird-dashboard";
  #       AUTH_CLIENT_SECRET = "";
  #       AUTH_AUTHORITY = "https://netbird.icylair.com/oauth2";
  #       USE_AUTH0 = "false";
  #       AUTH_SUPPORTED_SCOPES = "openid profile email groups";
  #       AUTH_REDIRECT_URI = "/nb-auth";
  #       AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
  #       # SSL
  #       NGINX_SSL_PORT = "443";
  #       # Letsencrypt
  #       LETSENCRYPT_DOMAIN = "none";
  #     };
  #   };
  #   management = {
  #     #pkgs is overriten on top of the file
  #     oidcConfigEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/.well-known/openid-configuration";
  #     metricsPort = 9093;
  #     port = 8081;
  #     # settings = {
  #     #   DataStoreEncryptionKey._secret = cfg.dataStoreEncryptionKeyPath;
  #     #   TURNConfig = {
  #     #     Secret._secret = cfg.coturnSalt;
  #     #     Turns = [
  #     #       {
  #     #         Proto = "udp";
  #     #         URI = "turn:${cfg.domain}:3478";
  #     #         Username = "netbird";
  #     #         Password._secret = cfg.coturnPasswordPath;
  #     #       }
  #     #     ];
  #     #   };
  #     #   HttpConfig = {
  #     #     AuthAudience = cfg.clientID;
  #     #     AuthIssuer = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}";
  #     #     AuthKeysLocation = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/openid-connect/certs";
  #     #     IdpSignKeyRefreshEnabled = false;
  #     #   };
  #     #   IdpManagerConfig = {
  #     #     ManagerType = "keycloak";
  #     #     ClientConfig = {
  #     #       Issuer = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}";
  #     #       TokenEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
  #     #       ClientID = cfg.backendID;
  #     #       ClientSecret._secret = cfg.clientSecretPath;
  #     #     };
  #     #     ExtraConfig = {
  #     #       AdminEndpoint = "https://${cfg.keycloakDomain}/admin/realms/${cfg.keycloakRealmName}";
  #     #     };
  #     #   };
  #     #   DeviceAuthorizationFlow = {
  #     #     # Provider = "hosted";
  #     #     Provider = "none";
  #     #     ProviderConfig = {
  #     #       ClientID = cfg.clientID;
  #     #       Audience = cfg.clientID;
  #     #       Domain = cfg.keycloakDomain;
  #     #       TokenEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
  #     #       DeviceAuthEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/auth/device";
  #     #       Scope = "openid";
  #     #       UseIDToken = false;
  #     #     };
  #     #   };
  #     #   PKCEAuthorizationFlow = {
  #     #     ProviderConfig = {
  #     #       ClientID = cfg.clientID;
  #     #       Audience = cfg.clientID;
  #     #       TokenEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
  #     #       AuthorizationEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/auth";
  #     #     };
  #     #   };
  #     # };
  #     settings = {
  #       Stuns = [
  #         {
  #           Proto = "udp";
  #           URI = "stun:${cfg.domain}:3478";
  #         }
  #       ];
  #       # Relay = {
  #       #   Addresses = [
  #       #     "rels://${cfg.domain}:443"
  #       #   ];
  #       #   CredentialsTTL = "24h";
  #       #   Secret = ""; # define from path
  #       # };
  #       Signal = {
  #         Proto = "https";
  #         URI = "${cfg.domain}:443";
  #       };
  #       Datadir = "/var/lib/netbird-mgmt";
  #       DataStoreEncryptionKey._secret = cfg.dataStoreEncryptionKeyPath;
  #       EmbeddedIdP = {
  #         Enabled = true;
  #         Issuer = "https://${cfg.domain}/oauth2";
  #         DashboardRedirectURIs = [
  #           "https://${cfg.domain}/nb-auth"
  #           "https://${cfg.domain}/nb-silent-auth"
  #         ];
  #       };
  #     };
  #   };
  #   coturn = {
  #     enable = true;
  #     passwordFile = cfg.coturnPasswordPath;
  #   };
  # };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ingress.https ingress.stun_port 5349 5350 8011 8012 8013 8014 9091 9092 9093];
    allowedUDPPorts = [ingress.https ingress.stun_port 5349 5350 8011 8012 8013 8014 9091 9092 9093];
    # allowedUDPPortRanges = [
    #   { from = 1000; to = 6550; }
    # ];
  };


  # Ensure the /var/lib/netbird directory exists with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/netbird 0755 root root -"
    "L+ /var/lib/netbird/management.json - - - - /etc/netbird/management.json"
  ];
  # virtualisation.docker.enable = true;
  virtualisation.podman = {
    enable = true;
    # dockerCompat = true;
  };
  systemd.services.podman-network-netbird = {
    description = "Create netbird podman network";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.podman}/bin/podman network exists netbird || ${pkgs.podman}/bin/podman network create netbird'";
    };
  };
  virtualisation.oci-containers = {
    backend = "podman";

    containers = {
      netbird-dashboard = {
        image = "docker.io/netbirdio/dashboard:v2.28.0";
        autoStart = true;
        ports = [
          "127.0.0.1:18080:80"
        ];
        # environment = {
        #   NETBIRD_MGMT_API_ENDPOINT = "https:/${cfg.domain}";
        #   NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://${cfg.domain}";
        #   # OIDC - using embedded IdP
        #   AUTH_AUDIENCE = "netbird-dashboard";
        #   AUTH_CLIENT_ID = "netbird-dashboard";
        #   AUTH_CLIENT_SECRET = "";
        #   AUTH_AUTHORITY = "https://${cfg.domain}/oauth2";
        #   USE_AUTH0 = "false";
        #   AUTH_SUPPORTED_SCOPES = "openid profile email groups";
        #   AUTH_REDIRECT_URI = "/nb-auth";
        #   AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
        #   # SSL
        #   NGINX_SSL_PORT = "443";
        #   # Letsencrypt
        #   LETSENCRYPT_DOMAIN = "none";
        # };
        environmentFiles = [/var/lib/netbird-mgmt/dashboard.env];
        log-driver = "json-file";
        extraOptions = [
          "--network=netbird"
          "--log-opt=max-size=500m"
          "--log-opt=max-file=2"
        ];
      };
      netbird-signal = {
        image = "docker.io/netbirdio/signal:0.64.1";
        autoStart = true;
        ports = [
          "127.0.0.1:8083:80"
          "127.0.0.1:10000:10000"
        ];
        extraOptions = [
          "--network=netbird"
          "--log-opt=max-size=500m"
          "--log-opt=max-file=2"
        ];
      };
      netbird-relay = {
        image = "docker.io/netbirdio/relay:0.64.1";
        autoStart = true;
        ports = [
          "127.0.0.1:8084:80"
          "3478:3478/udp"
        ];
        # environment = {
        #   NB_LOG_LEVEL = "info";
        #   NB_LISTEN_ADDRESS = ":80";
        #   NB_EXPOSED_ADDRESS = "rels://${cfg.domain}:443";
        #   NB_AUTH_SECRET = "";
        #   NB_ENABLE_STUN = "true";
        #   NB_STUN_LOG_LEVEL = "info";
        #   NB_STUN_PORTS = "3478";
        # };
        environmentFiles = [/var/lib/netbird-mgmt/relay.env];
        extraOptions = [
          "--network=netbird"
          "--log-opt=max-size=500m"
          "--log-opt=max-file=2"
        ];
      };
      netbird-managment = {
        image = "docker.io/netbirdio/management:0.64.1";
        autoStart = true;
        ports = [
          "127.0.0.1:8081:80"
        ];
        volumes = [
          "/var/lib/netbird-mgmt/data:/var/lib/netbird"
          "/var/lib/netbird-mgmt/management.json:/etc/netbird/management.json"
        ];
        # environmentFiles = [/var/lib/netbird-mgmt/storekey.env];
        cmd = [
          "--port"
          "80"
          "--log-file"
          "console"
          "--log-level"
          "info"
          "--disable-anonymous-metrics=true"
          "--single-account-mode-domain=netbird.selfhosted"
          "--dns-domain=netbird.selfhosted"
          "--idp-sign-key-refresh-enabled"
        ];
        extraOptions = [
          "--network=netbird"
          "--log-opt=max-size=500m"
          "--log-opt=max-file=2"
        ];
      };
    };
  };
  systemd.services.podman-netbird-dashboard.after = ["podman-network-netbird.service"];
  systemd.services.podman-netbird-signal.after = ["podman-network-netbird.service"];
  systemd.services.podman-netbird-relay.after = ["podman-network-netbird.service"];
  systemd.services.podman-netbird-management.after = ["podman-network-netbird.service"];

  services.haproxy.config = lib.mkMerge [
    ''
      ${
        # lib.optionalString config.services.netbird.server.enable
        lib.optionalString (config.systemd.services ? podman-netbird-dashboard.enable)
        ''
          # TCP backend that forwards to local HTTP frontend
          backend https_frontend_backend
              mode tcp
              server local_http 127.0.0.1:8443 send-proxy-v2
          frontend https_frontend
              bind 127.0.0.1:8443 ssl crt /cert/tls.pem alpn h2,http/1.1 accept-proxy
              # bind *:443 ssl crt /cert/tls.pem alpn h2,http/1.1 accept-proxy
              mode http

              # ACLs for routing
              acl is_relay path_beg /relay
              acl is_ws_signal path_beg /ws-proxy/signal
              acl is_grpc_signal path_beg /signalexchange.SignalExchange/
              acl is_api path_beg /api
              acl is_ws_management path_beg /ws-proxy/management
              acl is_grpc_management path_beg /management.ManagementService/
              acl is_oauth path_beg /oauth2
              acl is_websocket hdr(Upgrade) -i websocket

              # Route to appropriate backend
              use_backend relay_backend if is_relay
              use_backend signal_ws_backend if is_ws_signal
              use_backend signal_grpc_backend if is_grpc_signal
              use_backend management_backend if is_api
              use_backend management_ws_backend if is_ws_management
              use_backend management_grpc_backend if is_grpc_management
              use_backend management_backend if is_oauth
              default_backend dashboard_backend

          # Relay backend (HTTP with WebSocket)
          backend relay_backend
              mode http
              option http-server-close
              option forwardfor
              server relay 127.0.0.1:8084 check

          # Signal WebSocket backend
          backend signal_ws_backend
              mode http
              option http-server-close
              option forwardfor
              http-request set-header X-Forwarded-Proto https
              server signal_ws 127.0.0.1:8083 check

          # Signal gRPC backend (requires h2c)
          backend signal_grpc_backend
              mode http
              option http-server-close
              option forwardfor
              http-request set-header X-Forwarded-Proto https
              server signal_grpc 127.0.0.1:10000 proto h2 check

          # Management API backend
          backend management_backend
              mode http
              option http-server-close
              option forwardfor
              http-request set-header X-Forwarded-Proto https
              server management 127.0.0.1:8081 check

          # Management WebSocket backend
          backend management_ws_backend
              mode http
              option http-server-close
              option forwardfor
              http-request set-header X-Forwarded-Proto https
              server management_ws 127.0.0.1:8081 check

          # Management gRPC backend (requires h2c)
          backend management_grpc_backend
              mode http
              option http-server-close
              option forwardfor
              http-request set-header X-Forwarded-Proto https
              server management_grpc 127.0.0.1:8081 proto h2 check

          # Dashboard backend (catch-all)
          backend dashboard_backend
              mode http
              option http-server-close
              option forwardfor
              http-request set-header X-Forwarded-Proto https
              server dashboard 127.0.0.1:18080 check
        ''
      }
    ''
  ];
}
