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
in {
  virtualisation.podman = {
    enable = true;
    # dockerCompat = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";

    containers.netbird-dashboard = {
      image = "netbirdio/dashboard:latest";
      autoStart = true;

      ports = [
        "127.0.0.1:8080:80"
      ];
      environment = {
        NETBIRD_MGMT_API_ENDPOINT = "https://netbird.icylair.com";
        NETBIRD_MGMT_GRPC_API_ENDPOINT = "https://netbird.icylair.com";
        # OIDC - using embedded IdP
        AUTH_AUDIENCE = "netbird-dashboard";
        AUTH_CLIENT_ID = "netbird-dashboard";
        AUTH_CLIENT_SECRET = "";
        AUTH_AUTHORITY = "https://netbird.icylair.com/oauth2";
        USE_AUTH0 = "false";
        AUTH_SUPPORTED_SCOPES = "openid profile email groups";
        AUTH_REDIRECT_URI = "/nb-auth";
        AUTH_SILENT_REDIRECT_URI = "/nb-silent-auth";
        # SSL
        NGINX_SSL_PORT = "443";
        # Letsencrypt
        LETSENCRYPT_DOMAIN = "none";
      };
    };
  };
}
