{ config, lib, inputs, vars, ... }:
let
  system = "aarch64-linux";
  pkgs = import inputs.nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  
in
{
  imports = [
   
  ];
  networking.wg-quick.interfaces = {
    wg10 = {
      address = [ "10.10.2.4/32" ];
      # dns = [ "10.1.1.1" ];
      privateKeyFile = "/root/wg_vxlan";
      
      peers = [
        {
          publicKey = "aLbiFFBc+ejLFy8oVy8JFPbEjcfk4hII5Ns5jrIKY1s=";
          allowedIPs = [ "10.1.0.0/16"
                         "10.2.0.0/16"];
          # allowedIPs = [ "10.0.0.0/8"];
          endpoint = "home.local.icylair.com:51820";
          persistentKeepalive = 25;
        }
      ];
    };
    
  };
}