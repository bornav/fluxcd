{lib, ...}: {
  services.alloy.enable = true;
  environment.etc."alloy/config.alloy".text = lib.mkForce ''
    prometheus.remote_write "local" {
      endpoint {
        url = "http://10.129.16.104:9090/api/v1/write"
      }
    }
    loki.write "local" {
      endpoint {
        url = "http://10.129.16.103:3100/loki/api/v1/push"
      }
    }
    otelcol.exporter.otlp "local" {
      client {
        endpoint = "10.129.16.102:4317"
      }
    }
    pyroscope.write "local" {
      endpoint {
        url = "http://10.129.16.105:4100"
      }
    }
    prometheus.scrape "linux_node" {
      targets = prometheus.exporter.unix.node.targets
      forward_to = [
        prometheus.remote_write.local.receiver,
      ]
    }
    prometheus.exporter.unix "node" {
    }
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
  '';
  # discovery.docker "linux" {
  #   host = "/var/run/docker.sock"
  # }
  # discovery.relabel "logs_integrations_docker" {
  #     targets = []
  #     rule {
  #         target_label = "job"
  #         replacement  = "integrations/docker"
  #     }
  #     rule {
  #         target_label = "instance"
  #         replacement  = constants.hostname
  #     }
  #     rule {
  #         source_labels = ["__meta_docker_container_name"]
  #         regex         = "/(.*)"
  #         target_label  = "container"
  #     }
  #     rule {
  #         source_labels = ["__meta_docker_container_log_stream"]
  #         target_label  = "stream"
  #     }
  # }
  # loki.source.docker "default" {
  #   host = "/var/run/docker.sock"
  #   targets = discovery.docker.linux.targets
  #   relabel_rules = discovery.relabel.logs_integrations_docker.rules
  #   labels = {
  #   }
  #   forward_to = [
  #     loki.write.local.receiver,
  #   ]
  # }
}
