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
  # # restic backup /var/lib/netbird-server
  source_path = "/var/lib/.restic_netbird";
  netbird = {
    data_path = "/var/lib/netbird-server";
    # https://hub.docker.com/u/netbirdio?page=1&search=
    server = "0.71.3";
    dashboard = "2.38.1";
  };
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
      if [ -d "${netbird.data_path}" ]; then
          echo "restore exists, exiting..."
          exit 0
      fi
      source ${source_path}
      ${pkgs.restic}/bin/restic restore latest --target /  # the / as during backup it creates a full path to the folder
    '';
  };
  # systemd.services.netbird-compose-start = {
  #   # serviceConfig.Type = "oneshot";
  #   requiredBy = [
  #     "netbird-restore-data.service"
  #   ];
  #   before = [
  #     "netbird-restore-data.service"
  #   ];
  #   # preStart = ''
  #   #   until [ -f ${source_path} ]; do sleep 1; done
  #   # '';
  #   script = ''
  #     podman compose --file /etc/netbird_compose.yaml up
  #   '';
  #   # ${pkgs.podman-compose}/bin/restic restore latest --target /  # the / as during backup it creates a full path to the folder
  # };

  environment.systemPackages = with pkgs; [
    podman-compose
    # docker-compose # if check that adds the one depending on which is enabled
  ];

  virtualisation.podman = {
    enable = lib.mkDefault true;
  };

  environment.etc."netbird_compose.yaml" = {
    text = builtins.readFile ./netbird-compose.yaml;
    mode = "0644";
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
        image = "docker.io/netbirdio/dashboard:v${netbird.dashboard}";
        autoStart = true;
        # ports = [
        #   "127.0.0.1:18080:80"
        # ];
        environmentFiles = ["${netbird.data_path}/dashboard.env"];
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
        image = "docker.io/netbirdio/netbird-server:${netbird.server}";
        autoStart = true;
        ports = [
          "3478:3478/udp"
        ];
        volumes = [
          "${netbird.data_path}/data:/var/lib/netbird"
          "${netbird.data_path}/config.yaml:/etc/netbird/config.yaml"
        ];
        cmd = ["--config" "/etc/netbird/config.yaml"];
        extraOptions = [
          "--network=netbird"
          "--label=traefik.enable=true"
          # gRPC router (needs h2c backend for HTTP/2 cleartext)
          "--label=traefik.http.routers.netbird-grpc.rule=Host(`netbird.icylair.com`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`))"
          "--label=traefik.http.routers.netbird-grpc.entrypoints=websecure"
          "--label=traefik.http.routers.netbird-grpc.tls=true"
          "--label=traefik.http.routers.netbird-grpc.service=netbird-server-h2c"
          "--label=traefik.http.routers.netbird-grpc.priority=100"
          # Backend router (relay, WebSocket, API, OAuth2)
          "--label=traefik.http.routers.netbird-backend.rule=Host(`netbird.icylair.com`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`))"
          "--label=traefik.http.routers.netbird-backend.entrypoints=websecure"
          "--label=traefik.http.routers.netbird-backend.tls=true"
          "--label=traefik.http.routers.netbird-backend.service=netbird-server"
          "--label=traefik.http.routers.netbird-backend.priority=100"
          # Services
          "--label=traefik.http.services.netbird-server.loadbalancer.server.port=80"
          "--label=traefik.http.services.netbird-server-h2c.loadbalancer.server.port=80"
          "--label=traefik.http.services.netbird-server-h2c.loadbalancer.server.scheme=h2c"

          # logging
          "--log-driver=json-file"
          "--log-opt=max-size=500m"
          "--log-opt=max-file=2"
        ];
      };
      netbird-proxy = {
        image = "docker.io/netbirdio/reverse-proxy:${netbird.server}";
        autoStart = true;
        dependsOn = ["netbird-server"];
        environmentFiles = ["${netbird.data_path}/proxy.env"];
        ports = [
          # "51820:51820/udp"
          "127.0.0.1:8443:8443"
        ];
        environment = {
          PIONS_LOG_DEBUG = "all";
          NB_LOG_LEVEL = "debug";
        };
        volumes = [
          "/cert:/cert"
        ];
        log-driver = "json-file";
        extraOptions = [
          "--network=netbird"
          "--label=traefik.enable=true"
          "--label=traefik.tcp.routers.proxy-passthrough.entrypoints=websecure"
          "--label=traefik.tcp.routers.proxy-passthrough.rule=HostSNI(`*`)"
          "--label=traefik.tcp.routers.proxy-passthrough.tls.passthrough=true"
          "--label=traefik.tcp.routers.proxy-passthrough.service=proxy-tls"
          "--label=traefik.tcp.routers.proxy-passthrough.priority=1"
          "--label=traefik.tcp.services.proxy-tls.loadbalancer.server.port=8443"
          # "--label=traefik.tcp.services.proxy-tls.loadbalancer.serverstransport=pp-v2@file"
          "--log-driver=json-file"
          "--log-opt=max-size=500m"
          "--log-opt=max-file=2"
        ];
      };
    };
  };
  systemd.services.podman-netbird-dashboard.after = ["podman-network-netbird.service"];
  systemd.services.podman-netbird-server.after = ["podman-network-netbird.service"];
  systemd.services.podman-netbird-proxy.after = ["podman-network-netbird.service"];
  services.netbird.enable = true; # client install

  services.traefik.dynamicConfigOptions = {
    tcp.serversTransports.pp-v2.proxyProtocol.version = 2; # netbird proxy requirement
  };
}
