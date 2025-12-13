{ config, lib, host, inputs, pkgs, pkgs-unstable, ... }:
{
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
  services.xserver = {
    enable = false;
    videoDrivers = [ "nvidia" ];
  };
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "nvidia-x11"
    "nvidia-settings"
  ];
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia-container-toolkit.mount-nvidia-executables = true;
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
  ];
}
