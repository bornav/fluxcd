## in prog how was deployed

### Test before deployment
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/git/kubernetes/fluxcd#oracle-km1-1 --vm-test` # to test before deploymend
some weird fuckerry happened in the grub part of the configuration making it not work, problem with not mounting the volumed since it did not exist

### To deploy | wipes all disk data, on each call
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/git/kubernetes/fluxcd#oracle-km1-1 root@141.144.255.9` #had to use password based auth since on nix first reboot(into installer) it would no longer work, constantly ask for password
!!!!!!!!!!!!!!!!!!!!!!!!!!oracle-km1-1-init!!!!!!!!!!!!!! 
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/git/kubernetes/fluxcd#oracle-km1-1-init root@141.144.255.9`try for first init to use the one here, this one will not have server specified

### rebuilds the flake with the new configuration
`nixos-rebuild switch --flake ~/git/kubernetes/fluxcd#oracle-km1-1 --use-substitutes --target-host oracle-km1-1` #how i updated the config on the remote system
aditional note, on update, seems local ip addres always switches
