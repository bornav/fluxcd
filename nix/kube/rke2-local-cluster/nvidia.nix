{ config, lib, host, inputs, pkgs, pkgs-unstable, ... }:
{
  nixpkgs.config.allowUnfree = true;
  hardware = {
    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;
      nvidiaPersistenced = true;
      package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.latest;
      # package = lib.mkForce config.boot.kernelPackages.nvidiaPackages.legacy_390;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
    };
    graphics.enable32Bit = true;
    graphics.enable = true;
  };

  nixpkgs.config.nvidia.acceptLicense = true;
  services.xserver.enable = false;
  services.xserver.videoDrivers = ["nvidia"]; # this is important

  # hardware.nvidia.datacenter.enable = true;

  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.docker = {
    enableNvidia = true; # still needed as of 10.08.2025
  };

  # this creates /var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl file with contents in the << EOF >, which during runtime rke2 reads, and populates condif.toml file in the same dir(puts at the bottom)
  systemd.services.k3s-containerd-setup = {
    # `virtualisation.containerd.settings` has no effect on k3s' bundled containerd.
    serviceConfig.Type = "oneshot";
    requiredBy = ["rke2-server.service"];
    before = ["rke2-server.service"];
    script = ''
      containerd_root=/var/lib/rancher/rke2/agent/etc/containerd/
      mkdir -p $containerd_root

      cat << EOF > $containerd_root/config.toml.tmpl
      {{ template "base" . }}

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
        privileged_without_host_devices = false
        runtime_engine = ""
        runtime_root = ""
        runtime_type = "io.containerd.runc.v2"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
        BinaryName = "${lib.getOutput "tools" config.hardware.nvidia-container-toolkit.package}/bin/nvidia-container-runtime"
      EOF
    '';
  };



  systemd.services.nvidia-gpu-powerlimit = {
    description = "Set NVIDIA GPU power limit";
    wantedBy = [ "multi-user.target" ];
    after = [
      "nvidia-persistenced.service"
      "systemd-udev-settle.service"
    ];
    requires = [ "nvidia-persistenced.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 125"
      ];
    };
  };
}
