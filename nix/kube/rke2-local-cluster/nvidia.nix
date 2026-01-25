{
  config,
  lib,
  host,
  inputs,
  pkgs,
  pkgs-unstable,
  ...
}: {
  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = true;
  };

  services.xserver = {
    enable = false;
    videoDrivers = ["nvidia"];
  };

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
    ];
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia-container-toolkit.mount-nvidia-executables = true;

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
  ];
  boot.kernelParams = ["nvidia_drm.fbdev=1"];
  # hardware.nvidia.datacenter.enable = true;

  # hardware.nvidia-container-toolkit.enable = true;

  # virtualisation.docker = {
  #   enableNvidia = true; # still needed as of 10.08.2025
  # };

  # # this creates /var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl file with contents in the << EOF >, which during runtime rke2 reads, and populates condif.toml file in the same dir(puts at the bottom)
  # systemd.services.rke2-containerd-setup = {
  #   # `virtualisation.containerd.settings` has no effect on k3s' bundled containerd.
  #   serviceConfig.Type = "oneshot";
  #   requiredBy = ["rke2-${config.rke2.type}.service"];
  #   before = ["rke2-${config.rke2.type}.service"];
  #   script = ''
  #     containerd_root=/var/lib/rancher/rke2/agent/etc/containerd/
  #     mkdir -p $containerd_root

  #     cat << EOF > $containerd_root/config.toml.tmpl
  #     {{ template "base" . }}

  #     [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
  #       privileged_without_host_devices = false
  #       runtime_engine = ""
  #       runtime_root = ""
  #       runtime_type = "io.containerd.runc.v2"
  #     EOF
  #   '';
  # };

  # systemd.services.nvidia-gpu-powerlimit = {
  #   description = "Set NVIDIA GPU power limit";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [
  #     "nvidia-persistenced.service"
  #     "systemd-udev-settle.service"
  #   ];
  #   requires = [ "nvidia-persistenced.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = [
  #       "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 125"
  #     ];
  #   };
  # };
}
