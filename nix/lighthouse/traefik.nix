{ config, inputs, system, host, vars, lib, pkgs, ... }:
{
  services.traefik = {
    enable = true;
    staticConfigFile = "/etc/traefik/traefik.yaml";
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8088 9000 9443];
    allowedUDPPorts = [ 9987 ];
    # allowedUDPPortRanges = [
    #   { from = 1000; to = 6550; }
    # ];
  };


  environment.etc."traefik/traefik.yaml".text = lib.mkForce ''
  log:
    level: DEBUG
  api:
    # dashboard: true when these 2 uncommented dashboard avaiable on http://159.69.206.117:9000/dashboard/
    # insecure: true
  entryPoints:
    traefik:
      address: ":9000"
    web:
      address: ':8088' # http
      # http:
      #   redirections:
      #     entryPoint:
      #       to: web-secure
      #       scheme: https      
    web-secure:
      address: ':9443' # https
    udp9987:
      address: ':9987/udp'
  providers:
    file:
      filename: /etc/traefik/traefik_dynamic.yaml
      watch: true
  '';
  # This one can be modified without svc restart
  environment.etc."traefik/traefik_dynamic.yaml".text = lib.mkForce  ''
  http:
    routers:
      api:
        rule: "Host(`lb.cloud.icylair.com`)"
        entrypoints:
          - "web-secure"
        service: "api@internal"
  udp:
    routers:
      ts:
        entryPoints:
          - "udp9987"
        service: "ts"
    services:
      ts:
        loadBalancer:
          servers:
            - address: "10.129.16.101:9987"
  tls:
    stores:
      default:
        defaultCertificate:
          certFile: /certs/tls.crt
          keyFile: /certs/tls.key
  '';
}