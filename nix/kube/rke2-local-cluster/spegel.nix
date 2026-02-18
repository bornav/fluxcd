{config, ...}: {
  # this creates /var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl file with contents in the << EOF >, which during runtime rke2 reads, and populates condif.toml file in the same dir(puts at the bottom)
  systemd.services.rke2-spegel-setup = {
    serviceConfig.Type = "oneshot";
    requiredBy = ["rke2-${config.rke2.type}.service"];
    before = ["rke2-${config.rke2.type}.service"];
    script = ''
      containerd_root=/var/lib/rancher/rke2/agent/etc/containerd/
      mkdir -p $containerd_root
      cat << EOF > $containerd_root/config.toml.tmpl
      {{ template "base" . }}
      [plugins."io.containerd.grpc.v1.cri".containerd]
         discard_unpacked_layers = false
      EOF
    '';
  };
}
