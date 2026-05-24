{
  config,
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
  compose_path = "stacks/netbird";
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
    requiredBy = ["netbird-compose-start.service"];
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
  systemd.services.netbird-compose-start = {
    enable = true;
    path = [pkgs.podman pkgs.podman-compose];
    serviceConfig.Type = "simple";
    serviceConfig.WorkingDirectory = "/var/lib/netbird-server";
    requires = ["netbird-restore-data.service"];
    after = ["netbird-restore-data.service"];
    restartTriggers = [config.environment.etc."${compose_path}/compose.yaml".source];
    wantedBy = ["multi-user.target"];
    preStart = ''cp /etc/${compose_path}/compose.yaml ${netbird.data_path}/compose.yaml'';
    script = ''/run/current-system/sw/bin/podman-compose up'';
    postStop = ''/run/current-system/sw/bin/podman-compose down'';
  };

  environment.systemPackages = with pkgs; [
    podman-compose
    # docker-compose # if check that adds the one depending on which is enabled
  ];

  virtualisation.podman = {
    enable = lib.mkDefault true;
  };

  environment.etc."${compose_path}/compose.yaml" = {
    text = builtins.readFile ./netbird-compose.yaml;
    mode = "0644";
  };

  services.netbird.enable = true; # client install

  services.traefik.dynamicConfigOptions = {
    tcp.serversTransports.pp-v2.proxyProtocol.version = 2; # netbird proxy requirement
  };
}
