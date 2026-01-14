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
  systemd.services.netbird-restore-data = {
    serviceConfig.Type = "oneshot";
    requiredBy = [
      "netbird-management.service"
      "netbird-signal.service"
      "coturn.service"
      "nginx.service"
    ];
    before = [
      "netbird-management.service"
      "netbird-signal.service"
      "coturn.service"
      "nginx.service"
    ];
    preStart = ''
      until [ -f ${source_path} ]; do sleep 1; done
    '';
    script = ''
      if [ -d "/var/lib/netbird-mgmt" ]; then
          echo "restore exists, exiting..."
          exit 0
      fi
      source ${source_path}
      ${pkgs.restic}/bin/restic restore latest --target /  # the / as during backup it creates a full path to the folder
      cp /var/lib/netbird-mgmt/coturnpass.key /var/lib/coturnpass.key
    '';
  };
  systemd.services.nginx-wait-for-cert = {
    serviceConfig.Type = "oneshot";
    requiredBy = [
      "nginx.service"
      "netbird-management.service"
      "netbird-signal.service"
    ];
    before = [
      "nginx.service"
      "netbird-management.service"
      "netbird-signal.service"
    ];
    script = ''
      until [ -f ${cert_path}/tls.crt ] && [ -f ${cert_path}/tls.key ]; do sleep 1; done
    '';
  };
  services.nginx.virtualHosts.${cfg.domain} = {
    # forceSSL = true;
    onlySSL = true;
    sslCertificate = "/cert/tls.crt";
    sslCertificateKey = "/cert/tls.key";
    listen = [
      {
        addr = "127.0.0.202";
        # addr = "0.0.0.0";
        ssl = true;
        port = ingress.https;
      }
    ];
  };
  # ];

  services.netbird.server = {
    domain = cfg.domain;
    enable = true;
    enableNginx = true;
    signal = {
      package = pkgs-master.netbird-signal;
      metricsPort = 9092;
    };
    coturn = {
      enable = true;
      passwordFile = cfg.coturnPasswordPath;
    };
    dashboard = {
      package = pkgs-master.netbird-dashboard;
      settings = {
        AUTH_AUTHORITY = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}";
        AUTH_AUDIENCE = cfg.clientID;
        AUTH_CLIENT_ID = cfg.clientID;
        AUTH_SUPPORTED_SCOPES = "openid profile email offline_access netbird-api";
        USE_AUTH0 = false;
      };
    };

    management = {
      package = pkgs-master.netbird-management;
      oidcConfigEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/.well-known/openid-configuration";
      metricsPort = 9093;
      # port = 9093;
      settings = {
        DataStoreEncryptionKey._secret = cfg.dataStoreEncryptionKeyPath;

        TURNConfig = {
          Secret._secret = cfg.coturnSalt;

          Turns = [
            {
              Proto = "udp";
              URI = "turn:${cfg.domain}:3478";
              Username = "netbird";
              Password._secret = cfg.coturnPasswordPath;
            }
          ];
        };

        HttpConfig = {
          AuthAudience = cfg.clientID;
          AuthIssuer = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}";
          AuthKeysLocation = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/openid-connect/certs";
          IdpSignKeyRefreshEnabled = false;
        };

        IdpManagerConfig = {
          ManagerType = "keycloak";

          ClientConfig = {
            Issuer = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}";
            TokenEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
            ClientID = cfg.backendID;
            ClientSecret._secret = cfg.clientSecretPath;
          };

          ExtraConfig = {
            AdminEndpoint = "https://${cfg.keycloakDomain}/admin/realms/${cfg.keycloakRealmName}";
          };
        };

        DeviceAuthorizationFlow = {
          # Provider = "hosted";
          Provider = "none";

          ProviderConfig = {
            ClientID = cfg.clientID;
            Audience = cfg.clientID;
            Domain = cfg.keycloakDomain;
            TokenEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
            DeviceAuthEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/auth/device";
            Scope = "openid";
            UseIDToken = false;
          };
        };

        PKCEAuthorizationFlow = {
          ProviderConfig = {
            ClientID = cfg.clientID;
            Audience = cfg.clientID;
            TokenEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
            AuthorizationEndpoint = "https://${cfg.keycloakDomain}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/auth";
          };
        };
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ingress.https 8011 8012 8013 8014 9091 9092 9093];
    allowedUDPPorts = [ingress.https 8011 8012 8013 8014 9091 9092 9093];
    # allowedUDPPortRanges = [
    #   { from = 1000; to = 6550; }
    # ];
  };
}
