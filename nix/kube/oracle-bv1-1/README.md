## in prog how was deployed

### Test before deployment
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/git/kubernetes/fluxcd#oracle-bv1-1 --vm-test` # to test before deploymend
some weird fuckerry happened in the grub part of the configuration making it not work, problem with not mounting the volumed since it did not exist

### To deploy | wipes all disk data, on each call
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/git/kubernetes/fluxcd#oracle-bv1-1 root@138.3.244.139` #had to use password based auth since on nix first reboot(into installer) it would no longer work, constantly ask for password


### rebuilds the flake with the new configuration
`nixos-rebuild switch --flake ~/git/kubernetes/fluxcd#oracle-bv1-1 --use-substitutes --target-host oracle-bv1-1` #how i updated the config on the remote system
`nh os switch ~/git/kubernetes/fluxcd -H oracle-bv1-1 --ask --target-host oracle-bv1-1`
aditional note, on update, seems local ip addres always switches
