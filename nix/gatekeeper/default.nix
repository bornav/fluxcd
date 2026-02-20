{
  lib,
  host,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    }
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disk-config.nix
    ./traefik.nix
    ./netbird.nix
    {_module.args.disks = ["/dev/sda"];}
    {
      disabledModules = ["services/networking/headscale.nix"];
      imports = ["${inputs.nixpkgs-bornav}/nixos/modules/services/networking/headscale.nix"];
    }

    inputs.sops-nix.nixosModules.sops
  ];

  # #sops
  # sops.age.keyFile = "/home/user/.sops/nix-key.txt";
  # sops.secrets."home-assistant-secrets.yaml" = {
  #   owner = "hass";
  #   path = "/var/lib/.restic_netbird";
  # };
  # #
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs-unstable.linuxKernel.packages.linux_6_8;
  # boot.kernelPackages = pkgs-master.linuxPackages_testing;
  boot.kernelModules = ["rbd" "br_netfilter"];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.loader = {
    timeout = 1;
    grub.enable = true;
    grub.efiSupport = true;
    grub.efiInstallAsRemovable = true;
  };

  networking.hostName = host.hostName; # Define your hostname.
  programs.nh.enable = true;
  services = {
    openssh = {
      # SSH
      enable = true;
      allowSFTP = true; # SFTP
      extraConfig = ''
        HostKeyAlgorithms +ssh-rsa
      '';
      # settings.PasswordAuthentication = true;
      settings.KbdInteractiveAuthentication = true;
      settings.PermitRootLogin = "yes";
    };
    xserver = {
      xkb.layout = "us";
      xkb.variant = "";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEGiVyNsVCk2KAGfCGosJUFig6PyCUwCaEp08p/0IDI7"];
  # users.users.root.initialPassword = "nixos";
  users.users.${host.vars.user} = {
    isNormalUser = true;
    # initialPassword = "nixos";
    description = "${host.vars.user}";
    extraGroups = ["networkmanager" "wheel" "docker"];
    # packages = with pkgs; [];
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEGiVyNsVCk2KAGfCGosJUFig6PyCUwCaEp08p/0IDI7"];
  };
  time.timeZone = "Europe/Vienna";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "de_AT.UTF-8";
      LC_IDENTIFICATION = "de_AT.UTF-8";
      LC_MEASUREMENT = "de_AT.UTF-8";
      LC_MONETARY = "de_AT.UTF-8";
      LC_NAME = "de_AT.UTF-8";
      LC_NUMERIC = "de_AT.UTF-8";
      LC_PAPER = "de_AT.UTF-8";
      LC_TELEPHONE = "de_AT.UTF-8";
      LC_TIME = "de_AT.UTF-8";
    };
  };
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    jq
    gparted
    pciutils # lspci
    zip
    p7zip
    unzip
    unrar
    gnutar
    ser2net
    par2cmdline
    rsync
    vim
    nfs-utils
    wireguard-tools
    python3
    cilium-cli
    cni-plugins
    cifs-utils
    git
    kubectl
    vim
    nano
    inetutils
    nettools
    util-linux
    restic
  ];
  system.stateVersion = "${host.vars.stateVersion}";
  # systemd.extraConfig = '' # TODO find replacment, and make sure you test it for both user level and root level services
  #   DefaultTimeoutStopSec=5s
  # ''; # sets the systemd stopjob timeout to somethng else than 90 seconds
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      # Garbage Collection
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes";
    settings.max-jobs = 4;
  };
  networking.useDHCP = lib.mkForce false; # forcing dissable cus of systemd network
  systemd.network.enable = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "enp1s0";
    networkConfig = {
      # start a DHCP Client for IPv4 Addressing/Routing
      DHCP = "ipv4";
      # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
      IPv6AcceptRA = true;
    };
    # make routing on this interface a dependency for network-online.target
    linkConfig.RequiredForOnline = "routable";
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
  };
}
