{ config, lib, host, inputs, pkgs, pkgs-unstable, ... }:
{
  nixpkgs.config.cudaSupport = true;
  services.xserver = {
    enable = false;
    videoDrivers = [ "nvidia" ];
  };
  hardware = {
    nvidia = {
      open = true;
      nvidiaPersistenced = true;
      nvidiaSettings = true;
    };
    nvidia-container-toolkit = {
      enable = true;
      mount-nvidia-executables = true;
    };
  };

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
  #       "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 220"
  #     ];
  #   };
  # };

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
  ];
}
