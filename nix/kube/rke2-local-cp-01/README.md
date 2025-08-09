## in prog how was deployed

### Test before deployment
`nix run github:nix-community/nixos-anywhere -- --flake ~/git/kubernetes/fluxcd/nix/local_flake#rke2-local-cp-01 --vm-test` # to test before deploymend
some weird fuckerry happened in the grub part of the configuration making it not work, problem with not mounting the volumed since it did not exist

### To deploy | wipes all disk data, on each call
`nix run github:nix-community/nixos-anywhere -- --flake ~/git/kubernetes/fluxcd/nix/local_flake#rke2-local-cp-01 root@10.2.11.41 -i ~/.ssh/id_local` #had to use password based auth since on nix first reboot(into installer) it would no longer work, constantly ask for password
`nix run github:nix-community/nixos-anywhere -- --flake ~/git/kubernetes/fluxcd/nix/local_flake#rke2-local-cp-01 ubuntu@10.2.11.41 -i ~/.ssh/id_local`


### rebuilds the flake with the new configuration
`nixos-rebuild switch --flake ~/git/kubernetes/fluxcd/nix/local_flake#rke2-local-cp-01 --use-substitutes --target-host rke2-local-cp-01` #how i updated the config on the remote system
`nh os switch ~/git/kubernetes/fluxcd/nix/local_flake -H rke2-local-cp-01 --ask --target-host rke2-local-cp-01`
### custom flake.lock file
`nixos-rebuild switch --flake ~/git/kubernetes/fluxcd/nix/local_flake#rke2-local-cp-01 --use-substitutes --target-host root@10.2.11.41`
`nh os switch ~/git/kubernetes/fluxcd/nix/local_flake -H rke2-local-cp-01 --ask --target-host rke2-local-cp-01`
aditional note, on update, seems local ip addres always switches
