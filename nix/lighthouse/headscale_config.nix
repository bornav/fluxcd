# this file depends on mutability.nix file to be imported from home-manager user level, it adds force and mutable fields
{inputs, config, pkgs, ... }:
{
# imports = [
#     import ../mutability.nix
#     # possibly other imports
#   ];
# home.file."asdasd.sh".source = 
# let
#   script = pkgs.writeShellScriptBin "asdasd.sh" ''
#     asd
#   '';
# in
#   "${script}/bin/testscript.sh" ;
home.file."headscale_config.yaml" = {
  text = builtins.readFile ./headscale_config.yaml;
  force = true;
  mutable = true;
  };
}