{ config, lib, system, inputs, host, vars, pkgs, pkgs-unstable, ... }:
{
services.tailscale.enable = true;
  networking.firewall = {
    # checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}