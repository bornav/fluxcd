{ config, lib, system, inputs, host, vars, pkgs, pkgs-unstable, ... }:
{
  imports = [
    ./kernel-confs.nix
    ./network.nix
    ./tailscale.nix
  ];
  programs.nh.enable = true;
  services = {
    openssh = {                             # SSH
      enable = true;
      allowSFTP = true;                     # SFTP
      extraConfig = ''
        HostKeyAlgorithms +ssh-rsa
      '';
      settings.PasswordAuthentication = true;
      settings.KbdInteractiveAuthentication = true;
      settings.PermitRootLogin = "yes";
    };
    xserver = {
      xkb.layout = "us";
      xkb.variant = "";
    };
  };
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEGiVyNsVCk2KAGfCGosJUFig6PyCUwCaEp08p/0IDI7"];
  users.users.root.initialPassword = "nixos";
  users.users.${host.vars.user} = {
    isNormalUser = true;
    hashedPassword = "!"; # https://discourse.nixos.org/t/how-to-disable-root-user-account-in-configuration-nix/13235
    # initialPassword = "nixos";
    description = "${host.vars.user}";
    extraGroups = [ "networkmanager" "wheel" "docker"];
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
  ####
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
    dnsutils
    nettools

    htop
    btop
  ];
  system = {                                # NixOS Settings
    # autoUpgrade = {                        # Allow Auto Update (not useful in flakes)
    #  enable = true;
    #  flake = inputs.self.outPath;
    #  flags = [
    #    "--update-input"
    #    "nixpkgs"
    #    "-L"
    #  ];
    # };
    stateVersion = "${host.vars.stateVersion}";
  };
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=20s
  ''; # sets the systemd stopjob timeout to somethng else than 90 seconds
  nix = {
    settings.auto-optimise-store = true;
    gc = {                                  # Garbage Collection
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes";
    settings.max-jobs = 4;
  };
  environment.variables = {
    TZ="Europe/Vienna";
    # LD_LIBRARY_PATH=lib.mkForce "$NIX_LD_LIBRARY_PATH"; ## may break stuff
  };
  # programs.nix-ld = {
  #   enable = true;
  #   libraries = with pkgs; [
  #     alsa-lib
  #     at-spi2-atk
  #     at-spi2-core
  #     atk
  #     cairo
  #     cups
  #     curl
  #     dbus
  #     expat
  #     fontconfig
  #     freetype
  #     fuse3
  #     gdk-pixbuf
  #     glib
  #     gtk3
  #     icu
  #     libGL
  #     libappindicator-gtk3
  #     libdrm
  #     libglvnd
  #     libnotify
  #     libpulseaudio
  #     libunwind
  #     libusb1
  #     libuuid
  #     libxkbcommon
  #     libxml2
  #     mesa
  #     nspr
  #     nss
  #     openssl
  #     pango
  #     pipewire
  #     stdenv.cc.cc
  #     systemd
  #     vulkan-loader
  #     xorg.libX11
  #     xorg.libXScrnSaver
  #     xorg.libXcomposite
  #     xorg.libXcursor
  #     xorg.libXdamage
  #     xorg.libXext
  #     xorg.libXfixes
  #     xorg.libXi
  #     xorg.libXrandr
  #     xorg.libXrender
  #     xorg.libXtst
  #     xorg.libxcb
  #     xorg.libxkbfile
  #     xorg.libxshmfence
  #     zlib
  #     # add any missing dynamic libraries for unpacked programs here, not in the environment.systemPackages
  #   ];
  # };
}
