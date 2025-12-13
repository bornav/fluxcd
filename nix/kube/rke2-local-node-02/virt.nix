{pkgs, ...}: {
  ## in virtualization, find out how to import at the top
  # users.users.${host.vars.user}.extraGroups = [ "libvirtd" ];
  virtualisation.libvirtd.enable = true;
  services.qemuGuest.enable = true;
  programs.dconf.enable = true; # virt-manager requires dconf to remember settings
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    qemu
    spice
    libgcc
    # docker
    runc
  ];
  # virtualisation.docker.logDriver = "json-file";
  # virtualisation.docker = {
  #   enable = true;
  # };
  # virtualisation.podman.enable = true;
}
