{inputs, config, system, host, pkgs, pkgs-stable, pkgs-unstable, pkgs-master, ... }:
let
  # pkgs = import inputs.nixpkgs-unstable {
  #   inherit system;
  #   config.allowUnfree = true;
  # };
  # pkgs-unstable = import inputs.nixpkgs-unstable {
  #   inherit system;
  #   config.allowUnfree = true;
  # };
in
{
  home-manager.users.${host.vars.user} = {       # Home-Manager Settings
    home.stateVersion = "${host.vars.stateVersion}";
    programs.home-manager.enable = true;
    xdg.enable= true;
    # xdg.desktopEntries = {
    #   thoooor = {
    #     name = "thoooor";
    #     genericName = "Web Browser";
    #     exec = "thorium ";
    #     terminal = false;
    #     categories = [ "Application" "Network" "WebBrowser" ];
    #     mimeType = [ "text/html" "text/xml" ];
    #   };
    # };
  };
}
