{ config, inputs, system, host, vars, lib, pkgs, ... }:
{
  services.traefik = {
    enable = true;
    staticConfigFile = "/etc/traefik/traefik.yaml";
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8081 9443];
    # allowedUDPPortRanges = [
    #   { from = 1000; to = 6550; }
    # ];
  };


  environment.etc."traefik/traefik.yaml".text = lib.mkForce ''
log:
  level: INFO
api:
  dashboard: true
  debug: true
  # insecure: true
entryPoints:
  web:
    address: ':8081' # http
    http:
      redirections:
        entryPoint:
          to: web-secure
          scheme: https      
  web-secure:
    address: ':9443' # https
  # dashboard:
  #   address: ':8082'
  '';


  home-manager.users."root" = {
    home.stateVersion = "${vars.stateVersion}";
    home.file.".config/traefik/traefik.yaml".text = ''
log:
 level: INFO
api:
 dashboard: true
 debug: true
 insecure: true
entryPoints:
#  http:
#   address: ":80"
 https:
  address: ":8443"
 tcp:
  address: ":2049"
serversTransport:
 insecureSkipVerify: true
providers:
 file:
  filename: /etc/traefik/config.yaml
  watch: true
    '';
    home.file.".config/traefik/config.yaml".text = ''
    '';
    home.file.".config/traefik/config-static.yaml".text = ''
    '';
  };
}