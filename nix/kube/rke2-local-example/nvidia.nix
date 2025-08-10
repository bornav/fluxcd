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

  ## in virtualization, find out how to import at the top
  # users.users.${host.vars.user}.extraGroups = [ "libvirtd" ];
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true; # virt-manager requires dconf to remember settings
  environment.systemPackages = with pkgs; [ 
      virt-manager
      virt-viewer
      qemu
      spice
      libgcc
      docker
      runc
      # nvidia-container-toolkit
  ];
  # programs.appimage.binfmt = true;

  # hardware.nvidia.datacenter.enable = true;

  boot.kernelParams = [ "nvidia_drm.fbdev=1" ];
  # virtualisation.cri-o.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };



  
  # virtualisation.docker.enable = true;
  # virtualisation.docker.extraOptions = "--default-runtime=nvidia";
  # virtualisation.docker.enableNvidia = true;
  # virtualisation.docker.logDriver = lib.mkDefault "journald";
  # virtualisation.containerd.enable = true;
  # virtualisation.containerd.configFile = "/etc/containerd/config.toml";
  # virtualisation.cri-o.enable = true;
  # virtualisation.containerd = {
  #    settings = {
  #     version = 2;
  #     plugins."io.containerd.grpc.v1.cri" = {
  #       default_runtime_name = "nvidia";
  #       containerd = {
  #         default_runtime_name = "nvidia";
  #         runtimes.nvidia = {
  #           runtime_type = "io.containerd.runc.v2";
  #           privileged_without_host_devices = false;
  #           options = {
  #             BinaryName = "${lib.getOutput "tools" config.hardware.nvidia-container-toolkit.package}/bin/nvidia-container-runtime";
  #           };
  #         };
  #       };
  #     };
  #   };
  # };
  # virtualisation.containerd = {
  #   enable = true;
  #   settings = {
  #       plugins."io.containerd.grpc.v1.cri" = {
  #         enable_cdi = true;
  #         cdi_spec_dirs = [ "/var/run/cdi" ];
  #       };
  #     };
  # };
  # systemd.services.nvidia-container-toolkit-cdi-generator = {
  #     environment.LD_LIBRARY_PATH = "${config.hardware.nvidia.package}/lib";
  #   };

  # systemd.services.k3s-containerd-setup = {
  #     # `virtualisation.containerd.settings` has no effect on k3s' bundled containerd.
  #     serviceConfig.Type = "oneshot";
  #     requiredBy = ["rke2-server.service"];
  #     before = ["rke2-server.service"];
  #     script = ''
  #       containerd_root=/var/lib/rancher/rke2/agent/etc/containerd/
  #       mkdir -p $containerd_root

  #       cat << EOF > $containerd_root/config.toml.tmpl
  #       {{ template "base" . }}
  #       [plugins]
  #       "io.containerd.grpc.v1.cri".enable_cdi = true
  #       EOF
  #     '';
  #   };
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
    # BinaryName = "${lib.getOutput "tools" config.hardware.nvidia-container-toolkit.package}/bin/nvidia-container-runtime"
}
