{
  lib,
  pkgs,
  ...
}: let
  # source_path file content example
  # export AWS_ACCESS_KEY_ID=<token_id>
  # export AWS_SECRET_ACCESS_KEY=<token>
  # export RESTIC_PASSWORD=<restic_pass>
  # export RESTIC_REPOSITORY=s3:http://<s3_endpoint>/restic-host-bucket/cloud/netbird
  # # restic backup /var/lib/netbird
  source_path = "/var/lib/.restic_netbird";
in {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443];
    allowedUDPPorts = [80 443 3478];
  };
  systemd.services.netbird-restore-data = {
    serviceConfig.Type = "oneshot";
    requiredBy = [
      "podman-netbird-dashboard.service"
      "podman-netbird-server.service"
    ];
    before = [
      "podman-netbird-dashboard.service"
      "podman-netbird-server.service"
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
    '';
  };

  virtualisation.podman = {
    enable = lib.mkDefault true;
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
        image = "docker.io/netbirdio/dashboard:v2.32.4";
        autoStart = true;
        # ports = [
        #   "127.0.0.1:18080:80"
        # ];
        environmentFiles = [/var/lib/netbird/dashboard.env];
        log-driver = "json-file";
        extraOptions = [
          "--network=netbird"
          "--label=traefik.enable=true"
          "--label=traefik.http.routers.netbird-dashboard.rule=Host(`netbird.icylair.com`)"
          "--label=traefik.http.routers.netbird-dashboard.entrypoints=websecure"
          "--label=traefik.http.routers.netbird-dashboard.tls=true"
          "--label=traefik.http.routers.netbird-dashboard.priority=1"
          "--label=traefik.http.services.netbird-dashboard.loadbalancer.server.port=80"
          "--log-driver=json-file"
          "--log-opt=max-size=500m"
          "--log-opt=max-file=2"
        ];
      };
      netbird-server = {
        image = "docker.io/netbirdio/netbird-server:0.65.3";
        autoStart = true;
        # ports = [
        #   "127.0.0.1:8081:80"
        # ];
        volumes = [
          "/var/lib/netbird/data:/var/lib/netbird"
          "/var/lib/netbird/config.yaml:/etc/netbird/config.yaml"
        ];
        cmd = ["--config" "/etc/netbird/config.yaml"];
        extraOptions = [
          "--network=netbird"
          "--label=traefik.enable=true"
          # gRPC router
          "--label=traefik.http.routers.netbird-grpc.rule=Host(`netbird.icylair.com`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`))"
          "--label=traefik.http.routers.netbird-grpc.entrypoints=websecure"
          "--label=traefik.http.routers.netbird-grpc.tls=true"
          "--label=traefik.http.routers.netbird-grpc.service=netbird-server-h2c"
          # Backend router
          "--label=traefik.http.routers.netbird-backend.rule=Host(`netbird.icylair.com`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`))"
          "--label=traefik.http.routers.netbird-backend.entrypoints=websecure"
          "--label=traefik.http.routers.netbird-backend.tls=true"
          "--label=traefik.http.routers.netbird-backend.service=netbird-server"
          # Services
          "--label=traefik.http.services.netbird-server.loadbalancer.server.port=80"
          "--label=traefik.http.services.netbird-server-h2c.loadbalancer.server.port=80"
          "--label=traefik.http.services.netbird-server-h2c.loadbalancer.server.scheme=h2c"
          "--log-driver=json-file"
          "--log-opt=max-size=500m"
          "--log-opt=max-file=2"
        ];
      };
    };
  };
  systemd.services.podman-netbird-dashboard.after = ["podman-network-netbird.service"];
  systemd.services.podman-netbird-server.after = ["podman-network-netbird.service"];
}
