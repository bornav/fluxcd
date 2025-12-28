{
  config,
  lib,
  pkgs,
  ...
}: let
  format = pkgs.formats.yaml {};

  # A workaround generate a valid Headscale config accepted by Headplane when `config_strict == true`.
  settings = lib.recursiveUpdate config.services.headscale.settings {
    # acme_email = "/dev/null";
    tls_cert_path = "/cert/tls.crt";
    tls_key_path = "/cert/tls.key";
    policy.path = "/dev/null";
    oidc.client_secret_path = "/headscale_key";
  };
  headscaleConfig = format.generate "headscale.yml" settings;

  # source_path file content example
  # export AWS_ACCESS_KEY_ID=<token_id>
  # export AWS_SECRET_ACCESS_KEY=<token>
  # export RESTIC_PASSWORD=<restic_pass>
  # export RESTIC_REPOSITORY=s3:http://<s3_endpoint>/restic-host-bucket/cloud/headscale
  # # restic backup /var/lib/headscale
  source_path = "/var/lib/.restic_headscale";
  cert_path = "/cert";
in {
  environment.etc."headscale_config.yaml" = {
    text = builtins.readFile ./headscale_config.yaml;
    mode = "0644";
  };
  systemd.services.headscale-restore-data = {
    serviceConfig.Type = "oneshot";
    requiredBy = [
      "headscale.service"
    ];
    before = [
      "headscale.service"
    ];
    preStart = ''
      until [ -f ${source_path} ]; do sleep 1; done
      until [ -f ${cert_path}/tls.crt ] && [ -f ${cert_path}/tls.key ]; do sleep 1; done
    '';
    script = ''
      source ${source_path}
      ${pkgs.restic}/bin/restic restore latest --target /  # the / as during backup it creates a full path to the folder
    '';
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [8080 10023];
  };

  services.headscale = {
    enable = true;
    configPath = "/etc/headscale_config.yaml";
    address = "0.0.0.0";
    port = 10023;
    # user = "nix";
    # group = "users";
    settings = {
      log.level = "debug";
      server_url = "https://headscale.icylair.com:8080";
      dns.base_domain = "icylair-local.com";
      dns.nameserver.global = "icylair-local.com";
      tls_cert_path = "${cert_path}/tls.crt";
      tls_key_path = "${cert_path}/tls.key";
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
