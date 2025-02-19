{inputs, config, system, vars, ... }:
let
  pkgs = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in
{
  imports = ( import ../modules/shell ++
              import ../modules/terminalEmulators ++
              import ../modules/virtualization ++
              import ../modules/dev ++
              import ../modules/gaming ++
              import ../modules/common ++
              import ../modules/vpn ++
              import ../modules/custom_pkg ++
              import ../modules/devices ++
              import ../modules/storage ++
              import ../modules/nix ++
              import ../modules/de);
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
  environment = {
    variables = {
      TERMINAL = "${vars.terminal}";
      EDITOR = "${vars.editor}";
      VISUAL = "${vars.editor}";
    };
    systemPackages = with pkgs; [
      wget
      bash
      tree
      htop              # Resource Manager
      coreutils         # GNU Utilities
      killall           # Process Killer
      nano              # Text Editor
      vim
      nix-tree          # Browse Nix Store
      tldr              # Helper
      usbutils          # Manage USB
      wget              # Retriever
      curl
      efibootmgr
      ntfs3g
      fastfetch #neofetch
      gnumake
      openssl
      xdg-utils
      ripgrep
      mission-center # windows like task manager
      # nh
      tmux
      # dbus
      # dbus-broker
      iperf3
    ] ++
    (with pkgs-unstable; [

    ]);
    # ]) ++ ([ pkgs.firefox ]);  ## syntax for adding one without pkgs appended
  };
  programs.nh.enable = true;
  services = {
    printing.enable = true;
    pulseaudio.enable = false;
    pipewire = {                            # Sound
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
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
  };
  users.users.root.initialPassword = "nixos";
  users.users.root.openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEGiVyNsVCk2KAGfCGosJUFig6PyCUwCaEp08p/0IDI7"];
  system = {                                # NixOS Settings
    # autoUpgrade = {                        # Allow Auto Update (not useful in flakes)
    #  enable = true;
    #  flake = inputs.self.outPath;
    #  flags = [
    #    "--update-input"
    #    "nixpkgs"
    #    "-L"];};
    stateVersion = "${vars.stateVersion}";
  };
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=5s
  ''; # sets the systemd stopjob timeout to somethng else than 90 seconds
  systemd.watchdog.rebootTime = "3m";
  home-manager.users.${vars.user} = {       # Home-Manager Settings
    home.stateVersion = "${vars.stateVersion}";
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

  # mdns
  services.avahi = {
    nssmdns4 = true;
    enable = true;
    ipv4 = true;
    ipv6 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  #

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
}
