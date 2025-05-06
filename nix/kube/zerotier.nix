{ config, lib, system, inputs, host, vars, pkgs, pkgs-unstable, ... }:
{
  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "ebe7fbd44549ab73"
    ];
  };
}