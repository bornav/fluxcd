{ config, lib, system, inputs, host, node_config, vars, ... }:
let
  # inherit host;
  pkgs = import inputs.nixpkgs-stable {
    system = host.system;
    config.allowUnfree = true;
  };
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = host.system;
    config.allowUnfree = true;
  };
in
{
  options = {
    rke2 = {
      server = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      agent = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };
  # {inherit inputs vars config lib host system;node_config = master1_rke;})
  config = lib.mkMerge [
    (lib.mkIf (config.rke2.server) {
      services.rke2 = {
        # package = pkgs.rke2;
        package = pkgs-unstable.rke2;
        # package = (pkgs.callPackage ../../modules/custom_pkg/rke2_custom.nix {
        #   rke2Version = "1.32.0+rke2r1";
        #   rke2Commit = "1182e7eb91b27b1686e69306eb2e227928a27a38";
        #   rke2TarballHash = "sha256-mmHQxiNcfgZTTdYPJPO7WTIlaCRM4CWsWwfRUcAR8ho=";
        #   rke2VendorHash = "sha256-6Y3paEQJ8yHzONqalzoe15TjWhF3zGsM92LS1AcJ2GM=";
        #   # k8sVersion = "v1.32.0";
        #   k8sImageTag = "v1.32.0-rke2r1-build20241212";
        #   etcdVersion = "v3.5.16-k3s1-build20241106";
        #   pauseVersion = "3.6";
        #   ccmVersion = "v1.32.0-rc3.0.20241220224140-68fbd1a6b543-build20250101";
        #   dockerizedVersion = "v1.32.0-rke2r1";
        #   # golangVersion = "go1.23.3";
        #   # eol = "2026-02-28";
        #   });
        # clusterInit=true;
        role="server";
        tokenFile ="/var/token";
        enable = true;
        # cni = "cilium";
        cni = "none";
        extraFlags = [ # space at the start important ! :|
          # " --disable rke2-kube-proxy"
          " --kube-apiserver-arg default-not-ready-toleration-seconds=30"
          " --kube-apiserver-arg default-unreachable-toleration-seconds=30" 
          " --kube-controller-manager-arg node-monitor-period=20s"
          " --kube-controller-manager-arg node-monitor-grace-period=20s" 
          " --kubelet-arg node-status-update-frequency=5s"
        ];
        # extraFlags = toString ([
        #   "--write-kubeconfig-mode \"0644\""
        #   "--disable rke2-kube-proxy"
        #   "--disable rke2-canal"
        #   "--disable rke2-coredns"
        #   "--disable rke2-ingress-nginx"
        #   "--disable rke2-metrics-server"
        #   "--disable rke2-service-lb"
        #   "--disable rke2-traefik"
        # ] ++ (if meta.hostname == "homelab-0" then [] else [
        #     "--server https://homelab-0:6443"
        # ]));
      };
      environment.variables = {
        KUBECONFIG="/etc/rancher/rke2/rke2.yaml";
      };
      # systemd.services.copy-kubernetes-config = {
      #   description = "Copy kubernetes config to root config";
      #   wantedBy = [ "multi-user.target" ];
      #   after = [ "local-fs.target" ];
      #   serviceConfig = {
      #     Type = "oneshot";
      #     RemainAfterExit = true;
      #     ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir /root/.kube/;${pkgs.coreutils}/bin/cat /etc/rancher/rke2/rke2.yaml > /root/.kube/config'";
      #   };
      # };
    })
    (lib.mkIf (config.rke2.agent) {
      services.rke2 = {
        package = pkgs-unstable.rke2;
        role="agent";
        tokenFile ="/var/token";
        enable = true;
        serverAddr = https://10.99.10.11:9345;
        # configPath = "/etc/rancher/rke2/config.yaml";
        extraFlags = [ # space at the start important ! :|
          # " --disable rke2-kube-proxy"
          " --kube-apiserver-arg default-not-ready-toleration-seconds=30"
          " --kube-apiserver-arg default-unreachable-toleration-seconds=30" 
          " --kube-controller-manager-arg node-monitor-period=20s"
          " --kube-controller-manager-arg node-monitor-grace-period=20s" 
          " --kubelet-arg node-status-update-frequency=5s"
        ];
      };
    })
  ]; 
}
