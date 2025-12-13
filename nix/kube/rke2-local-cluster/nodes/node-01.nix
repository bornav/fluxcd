{
  config,
  lib,
  system,
  inputs,
  host,
  vars,
  pkgs,
  ...
}:
# TODO remove system, only when from all modules it is removed
let
  token = ''
    this-is-temp-token
  '';
  master_rke = ''
    write-kubeconfig-mode: "0644"
    cluster-cidr: "10.32.0.0/16"
    service-cidr: "10.33.0.0/16"
    disable-kube-proxy: true
    disable-cloud-controller: true
    disable:
      - rke2-canal
      - rke2-ingress-nginx
      - rke2-service-lb
      - rke2-snapshot-controller
      - rke2-snapshot-controller-crd
      - rke2-snapshot-validation-webhook
    node-label:
      - "node-location=local"
      - "node-arch=amd64"
      - "nixos-nvidia-cdi=enabled"
      - "nvidia.com/gpu.present=true"
      - "storage/ceph=false"
      - "storage/longhorn=true"
    # node-taint:
    #   - "node-role.kubernetes.io/control-plane=true:NoSchedule"
    kube-apiserver-arg:
      - "oidc-issuer-url=https://sso.icylair.com/realms/master"
      - "oidc-client-id=kubernetes"
      - "oidc-username-claim=email"
      - "oidc-groups-claim=groups"
    node-ip: 10.99.10.52
    # node-ip: 10.2.11.42
  '';
  # runtime-image: "index.docker.io/rancher/rke2-runtime:v1.30.1-rke2r1"
in {
  imports = [
    ../nvidia.nix
    (import ../../rke2-server.nix {
      inherit
        inputs
        vars
        config
        lib
        host
        system
        pkgs
        ;
      node_config = master_rke;
    })
  ];
  # "server" or "agent"
  rke2.type = "agent";
  rke2.server_lb_address = "https://rke2-local-cp-01.local.icylair.com:9345";

  environment.etc."rancher/rke2/token".source = pkgs.writeText "token" token;
}
