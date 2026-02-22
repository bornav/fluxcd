{lib, ...}: let
  cert_path = "/cert";
in {
  virtualisation.podman = {
    enable = lib.mkDefault true;
    dockerSocket.enable = lib.mkDefault true;
    dockerCompat = lib.mkDefault true;
  };
  systemd.services.traefik-wait-for-cert = {
    serviceConfig.Type = "oneshot";
    requiredBy = [
      "traefik.service"
    ];
    before = [
      "traefik.service"
    ];
    script = ''
      until [ -f ${cert_path}/tls.crt ] && [ -f ${cert_path}/tls.key ]; do sleep 1; done
    '';
  };
  users.users.traefik.extraGroups = ["docker" "podman"];
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      # log.level = "DEBUG";
      # api = {
      #   dashboard = true;
      #   insecure = true;
      # };

      entryPoints = {
        traefik.address = ":9000";
        web.address = ":8088"; # http
        web-secure.address = ":9443"; # https
        udp9987.address = ":9987/udp";
      };
      providers = {
        docker = {
          # endpoint = "unix:///var/run/docker.sock";
          endpoint = "unix:///var/run/podman/podman.sock";
          exposedByDefault = false;
        };
      };
      tracing = {
        serviceName = "traefik-gatekeeper";
        otlp.http = {
          tls.insecureSkipVerify = true;
          endpoint = "http://10.129.16.102:4318/v1/traces";
        };
      };
      metrics = {
        otlp.http = {
          # tls.insecureSkipVerify = true;
          endpoint = "http://10.129.16.102:4318/v1/metrics";
        };
      };

    };
    dynamicConfigOptions = {
      http = {
        routers = {
          api = {
            rule = "Host(`lb.cloud.icylair.com`)";
            entrypoints = [ "web-secure" ];
            service = "api@internal";
          };
        };
      };
      udp = {
        routers = {
          ts = {
            entryPoints = [ "udp9987" ];
            service = "ts";
          };
        };
        services = {
          ts = {
            loadBalancer = {
              servers = [
                { address = "10.129.16.101:9987"; }
              ];
            };
          };
        };
      };

      tls.stores.default.defaultCertificate = {
        certFile = "/cert/tls.crt";
        keyFile = "/cert/tls.key";
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [8088 9000 9443];
    allowedUDPPorts = [9987];
    # allowedUDPPortRanges = [
    #   { from = 1000; to = 6550; }
    # ];
  };
}
