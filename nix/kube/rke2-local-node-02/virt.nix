{ config, lib, host, inputs, pkgs, pkgs-unstable, ... }:
{
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
  ];
  virtualisation.docker = {
    enable = true;
  };
  # virtualisation.podman.enable = true;
}
