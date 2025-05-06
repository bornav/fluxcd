## in prog how was deployed

### Test before deployment
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/.flake#dockeropen --vm-test` # to test before deploymend
some weird fuckerry happened in the grub part of the configuration making it not work, problem with not mounting the volumed since it did not exist

### To deploy | wipes all disk data, on each call
`nix run github:nix-community/nixos-anywhere -- --flake /home/bocmo/.flake#lighthouse root@159.69.206.117` #had to use password based auth since on nix first reboot(into installer) it would no longer work, constantly ask for password


### rebuilds the flake with the new configuration
`nixos-rebuild switch --flake ~/.flake#lighthouse --target-host lighthouse` #how i updated the config on the remote system
aditional note, on update, seems local ip addres always switches
