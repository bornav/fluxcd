{lib, pkgs-bornav-test, ...}: let
  # docker_socket = "unix:///var/run/docker.sock";
  docker_socket = "unix:///var/run/podman/podman.sock";
  prometheus_ingest = "http://10.129.16.104:9090/api/v1/write";
  loki_ingest = "http://10.129.16.103:3100/loki/api/v1/push";
  otel_ingest = "10.129.16.102:4317";
  pytoscope_ingest = "http://10.129.16.105:4100";
in {
  ####################### all required in order for alloy to have perm access to docker/podman socket
  users.groups.alloy = {};
  users.users.alloy.isSystemUser = true;
  users.users.alloy.group = "alloy";
  users.users.alloy.extraGroups = ["docker" "podman"];
  ####################################################
  services.alloy.enable = true;
  services.alloy.extraFlags = ["--disable-reporting"]; # this removes the anon usage statistics
  environment.etc."alloy/config.alloy".text = lib.mkForce ''
    prometheus.remote_write "local" {
      endpoint {
        url = "${prometheus_ingest}"
      }
    }
    loki.write "local" {
      endpoint {
        url = "${loki_ingest}"
      }
    }
    otelcol.exporter.otlp "local" {
      client {
        endpoint = "${otel_ingest}"
      }
    }
    pyroscope.write "local" {
      endpoint {
        url = "${pytoscope_ingest}"
      }
    }
    prometheus.scrape "linux_node" {
      targets = prometheus.exporter.unix.node.targets
      forward_to = [
        prometheus.remote_write.local.receiver,
      ]
    }
    prometheus.exporter.unix "node" {}
    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal__boot_id"]
        target_label  = "boot_id"
      }
      rule {
        source_labels = ["__journal__transport"]
        target_label  = "transport"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }
      rule {
        source_labels = ["__journal__hostname"]
        target_label  = "instance"
      }
    }
    loki.source.journal "read" {
      forward_to = [
        loki.write.local.receiver,
      ]
      relabel_rules = loki.relabel.journal.rules
      labels = {
        "job" = "integrations/node_exporter",
      }
    }
    discovery.docker "linux" {
      host = "${docker_socket}"
    }
    discovery.relabel "logs_integrations_docker" {
        targets = []
        rule {
            target_label = "job"
            replacement  = "integrations/docker"
        }
        rule {
            target_label = "instance"
            replacement  = constants.hostname
        }
        rule {
            source_labels = ["__meta_docker_container_name"]
            regex         = "/(.*)"
            target_label  = "container"
        }
        rule {
            source_labels = ["__meta_docker_container_log_stream"]
            target_label  = "stream"
        }
    }
    loki.source.docker "default" {
      host = "${docker_socket}"
      targets = discovery.docker.linux.targets
      relabel_rules = discovery.relabel.logs_integrations_docker.rules
      labels = {}
      forward_to = [
        loki.write.local.receiver,
      ]
    }

  '';

  systemd.services.beyla = {
    after = [ "network.target"];
    # environment = { BEYLA_NETWORK_PRINT_FLOWS = "true";};
    serviceConfig = {
      ExecStart = "${pkgs-bornav-test.beyla}/bin/beyla -config /etc/beyla/config.yaml";
      Restart = "on-failure";
      RestartSec = "5s";
      RemainAfterExit = true;
    };
    wantedBy = [ "multi-user.target" ];
  };
  environment.systemPackages = [pkgs-bornav-test.beyla];
  environment.etc."beyla/config.yaml".text = lib.mkForce ''
    network:
      enable: true
    # log_level: DEBUG
    discovery:
      instrument:
        - open_ports: 443
        - open_ports: 9443
    otel_metrics_export:
      endpoint: http://localhost:4318
    otel_traces_export:
      endpoint: http://localhost:4318
    ebpf:
      context_propagation: all
      track_request_headers: true
  '';
}
