## in prog how was deployed

### Test before deployment
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/.flake#contabo-01-4v-8m-800g --vm-test` # to test before deploymend
some weird fuckerry happened in the grub part of the configuration making it not work, problem with not mounting the volumed since it did not exist

### To deploy | wipes all disk data, on each call
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/.flake#contabo-01-4v-8m-800g root@207.180.245.148`  #had to use password based auth since on nix first reboot(into installer) it would no longer work, constantly ask for password


### rebuilds the flake with the new configuration
`nixos-rebuild switch --flake ~/.flake#contabo-01-4v-8m-800g --use-substitutes --target-host contabo-01-4v-8m-800g` #how i updated the config on the remote system
aditional note, on update, seems local ip addres always switches
