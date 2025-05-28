{ config, inputs, system, host, vars, lib, pkgs, ... }:
let
  format = pkgs.formats.yaml {};

  # A workaround generate a valid Headscale config accepted by Headplane when `config_strict == true`.
  settings = lib.recursiveUpdate config.services.headscale.settings {
    # acme_email = "/dev/null";
    tls_cert_path = "/certs/tls.crt";
    tls_key_path = "/certs/tls.key";
    policy.path = "/dev/null";
    oidc.client_secret_path = "/headscale_key";
  };
  headscaleConfig = format.generate "headscale.yml" settings;
in
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8080 10023];
  };

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 10023;
    settings = {
      log.level = "debug";
      server_url = "https://headscale.icylair.com:8080";
      dns.base_domain = "icylair-local.com";
      tls_cert_path = "/certs/tls.crt";
      tls_key_path = "/certs/tls.key";
      oidc = {
        issuer = "https://sso.icylair.com/realms/master";
        client_id = "headscale";
        client_secret_path = "/headscale_key";
      };
    };
  };
  # networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];
  # services.headplane = {
  #   enable = true;
  #   agent = {
  #     # As an example only.
  #     # Headplane Agent hasn't yet been ready at the moment of writing the doc.
  #     enable = false;
  #     settings = {
  #       HEADPLANE_AGENT_DEBUG = true;
  #       HEADPLANE_AGENT_HOSTNAME = "localhost";
  #       HEADPLANE_AGENT_TS_SERVER = "https://example.com";
  #       HEADPLANE_AGENT_TS_AUTHKEY = "xxxxxxxxxxxxxx";
  #       HEADPLANE_AGENT_HP_SERVER = "https://example.com/admin/dns";
  #       HEADPLANE_AGENT_HP_AUTHKEY = "xxxxxxxxxxxxxx";
  #     };
  #   };
  #   settings = {
  #     server = {
  #       host = "127.0.0.1";
  #       port = 3000;
  #       cookie_secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  #       cookie_secure = false;
  #     };
  #     headscale = {
  #       url = "https://headscale.icylair.com";
  #       config_path = "${headscaleConfig}";
  #       config_strict = true;
  #     };
  #     integration.proc.enabled = true;
  #     # oidc = {
  #     #   issuer = "https://oidc.example.com";
  #     #   client_id = "headplane";
  #     #   client_secret = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  #     #   disable_api_key_login = true;
  #     #   # Might needed when integrating with Authelia.
  #     #   token_endpoint_auth_method = "client_secret_basic";
  #     #   headscale_api_key = "xxxxxxxxxx.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  #     #   redirect_uri = "https://oidc.example.com/admin/oidc/callback";
  #     # };
  #   };
  # };  
}