{ config, inputs, system, host, vars, lib, pkgs, ... }:
let
  # rootDomain = "netbird.icylair.com";
  cfg = {
    domain = "netbird.icylair.com";
    clientID = "netbird";
    backendID = "netbird-backend";
    keycloakDomain = "sso.icylair.com";
    keycloakURL = "https://sso.icylair.com";
    keycloak_openid_url = "https://sso.icylair.com/realms/master/.well-known/openid-configuration";
    keycloakRealmName = "master";
    # clientSecret = "";
    clientSecret = "";
    coturnPasswordPath = "/coturnpass.key";
    clientSecretPath = "/netbird-oidc-secret.key";
    coturnSalt = "/netbird-oidc-secret.key";
    dataStoreEncryptionKeyPath = "/netbird-oidc-secret.key";
  };

in
{

  services.nginx.virtualHosts."netbird.icylair.com" = lib.mkMerge [ {
      forceSSL = true;
      sslCertificate = "/var/certs/tls.cert";
      sslCertificateKey = "/var/certs/tls.key";
      listen =[
      {
        addr = "0.0.0.0";
        ssl = true;
        port = 443;
      }
      ];
      # locations."/" = lib.mkForce {
      #   root = config.services.netbird.server.dashboard.finalDrv;
      #   tryFiles = "$uri $uri.html $uri/ =404";
      # };
      # forceSSL = false;
    }
  ];

    services.netbird.server = {
      domain = cfg.domain;
      enable = true;
      enableNginx = true;
      signal.metricsPort = 9092;
      coturn = {
        enable = true;
        passwordFile = cfg.coturnPasswordPath;
      };

      dashboard = {
        settings = {
          AUTH_AUTHORITY = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}";
          AUTH_AUDIENCE = cfg.clientID;
          AUTH_CLIENT_ID = cfg.clientID;
          AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
          USE_AUTH0 = false;
        };
      };

      management = {
        oidcConfigEndpoint = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}/.well-known/openid-configuration";
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
            AuthIssuer = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}";
            AuthKeysLocation = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}/openid-connect/certs";
            IdpSignKeyRefreshEnabled = false;
          };

          IdpManagerConfig = {
            ManagerType = "keycloak";

            ClientConfig = {
              Issuer = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}";
              TokenEndpoint = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
              ClientID = cfg.backendID;
              ClientSecret._secret = cfg.clientSecretPath;
            };

            ExtraConfig = {
              AdminEndpoint = "${cfg.keycloakURL}/admin/realms/${cfg.keycloakRealmName}";
            };
          };

          DeviceAuthorizationFlow = {
            Provider = "hosted";

            ProviderConfig = {
              ClientID = cfg.clientID;
              Audience = cfg.clientID;
              Domain = cfg.keycloakDomain;
              TokenEndpoint = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
              DeviceAuthEndpoint = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/auth/device";
              Scope = "openid";
              UseIDToken = false;
            };
          };

          PKCEAuthorizationFlow = {
            ProviderConfig = {
              ClientID = cfg.clientID;
              Audience = cfg.clientID;
              # ClientSecret = cfg.clientSecret;
              TokenEndpoint = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/token";
              AuthorizationEndpoint = "${cfg.keycloakURL}/realms/${cfg.keycloakRealmName}/protocol/openid-connect/auth";
            };
          };
        };
      };
    };




  # services.netbird.server = {
  #   enable = true;
  #   domain = rootDomain;
  #   # staticConfigFile = "/etc/traefik/traefik.yaml";
  #   management = {
  #     enable = false;
  #     oidcConfigEndpoint = "https://sso.icylair.com/realms/master/.well-known/openid-configuration";
  #     turnDomain = rootDomain;
  #   };
  #   dashboard = {
  #     enable = true;
  #     settings = {
  #         AUTH_AUDIENCE = "netbird";
  #         AUTH_CLIENT_ID = "netbird";
  #         AUTH_SUPPORTED_SCOPES = "openid profile email";
  #         NETBIRD_TOKEN_SOURCE = "";
  #         USE_AUTH0 = false;
  #         AUTH_AUTHORITY = "https://sso.icylair.com/realms/master/.well-known/openid-configuration";
  #       };
  #   };
  # };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8011 8012 8013 8014 9091];
    allowedUDPPorts = [ 8011 8012 8013 8014 9091];
    # allowedUDPPortRanges = [
    #   { from = 1000; to = 6550; }
    # ];
  };


  # environment.etc."traefik/traefik.yaml".text = lib.mkForce ''
  # log:
  #   level: DEBUG
  # api:
  #   # dashboard: true #when these 2 uncommented dashboard avaiable on http://159.69.206.117:9000/dashboard/
  #   # insecure: true
  # entryPoints:
  #   traefik:
  #     address: ":9000"
  #   web:
  #     address: ':8088' # http
  #     # http:
  #     #   redirections:
  #     #     entryPoint:
  #     #       to: web-secure
  #     #       scheme: https
  #   web-secure:
  #     address: ':9443' # https
  #   udp9987:
  #     address: ':9987/udp'
  # providers:
  #   file:
  #     filename: /etc/traefik/traefik_dynamic.yaml
  #     watch: true
  # tracing:
  #   serviceName: traefik-lighthouse
  #   otlp:
  #     http:
  #       tls:
  #         insecureSkipVerify: true
  #       endpoint: http://10.129.16.102:4318/v1/traces
  # '';
  # # This one can be modified without svc restart
  # environment.etc."traefik/traefik_dynamic.yaml".text = lib.mkForce  ''
  # http:
  #   routers:
  #     api:
  #       rule: "Host(`lb.cloud.icylair.com`)"
  #       entrypoints:
  #         - "web-secure"
  #       service: "api@internal"
  # udp:
  #   routers:
  #     ts:
  #       entryPoints:
  #         - "udp9987"
  #       service: "ts"
  #   services:
  #     ts:
  #       loadBalancer:
  #         servers:
  #           - address: "10.129.16.101:9987"
  # tls:
  #   stores:
  #     default:
  #       defaultCertificate:
  #         certFile: /certs/tls.crt
  #         keyFile: /certs/tls.key
  # '';
}
