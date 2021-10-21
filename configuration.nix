# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Audio
      /home/gwohl/nix/musnix
      # Web and cloud stuff
      #/home/gwohl/nix/nixcloud-webservices
    ];

  environment.systemPackages = with pkgs; [
  clang
  gnumake
  libtool
  autoconf
  automake
  m4
  alacritty
  bitmeter
  carla
  cmake
  ffmpeg-full
  fftwFloat
  fuse
  gcc
  glow
  libuuid
  libcap
  libjack2
  jack2 
  jack2Full
  jack_capture
  jackmix
  jackmeter
  jq
  libgpgerror
  libnotify
  libsodium
  meterbridge
  pango
  python
  qjackctl # jack
  readline
  sox
  soxr
  supercollider
  timemachine
  unzip
  usbutils # lsusb
  xjadeo # video sync for jack
  wine-staging
  winetricks

  nur.repos.dan4ik605743.bitmap-fonts
  nur.repos.crazazy.firefox-addons.old-reddit-redirect
  nur.repos.crazazy.firefox-addons.soundcloud-mp3-downloader
  nur.repos.crazazy.firefox-addons.ublock-origin
  nur.repos.crazazy.firefox-addons.tabliss
  nur.repos.crazazy.js.parcel
  ];

environment.variables = {
    EDITOR = "nvim";
    FREETYPE_PROPERTIES = "truetype:interpreter-version=38";
    HISTCONTROL = "ignoredups:erasedups";
    QT_LOGGING_RULES = "*=false";
};
  

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
    }))
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  musnix.enable = true;
  musnix.kernel.optimize = true;
  musnix.kernel.realtime = true;
  musnix.das_watchdog.enable = true;


  musnix.rtirq = {
      resetAll = 1;
      prioLow = 0;
      enable = true;
      nameList = "rtc0 snd";
    };

  services.jack = {
    jackd.enable = true;
    # support ALSA only programs via ALSA JACK PCM plugin
    alsa.enable = true;
    # support ALSA only programs via loopback device (supports programs like Steam)
    loopback = {
      enable = false;
      # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
      #dmixConfig = ''
      #  period_size 2048
      #'';
    };
  };
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp3s0.useDHCP = true;
  networking.interfaces.enp4s0.useDHCP = true;

security.acme.email = "andrew@multipli.city";
security.acme.acceptTerms = true;

services.nginx.enable = true;
services.nginx.virtualHosts."sociosonics.org" = {
    #addSSL = true;
    #enableACME = true;
    root = "/var/www/";
};
services.mpd.enable = true;
services.mpd.extraConfig = ''
  audio_output {
    type "alsa"
    name "alsa"
    device "hw:1"
  }
'';
services.mpd.musicDirectory = "/mnt/Music";
services.mpd.network.listenAddress = "any"; # allow to control from any host


  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.autorun = true;

  hardware.opengl.driSupport32Bit = true;


  # Enable the GNOME Desktop Environment.
  #services.xserver.displayManager.gdm.enable = true;
  #services.xserver.desktopManager.gnome.enable = true;
  services.xserver.windowManager.i3.enable = true;

hardware.pulseaudio.enable = false;

  # Configure keymap in X11
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  #   firefox
  # ];
  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  programs.fish.enable = true;

  programs.dconf.enable = true;
  # List services that you want to enable:

  programs.neovim = {
    defaultEditor = true;
    enable       = true;
    viAlias      = true;
    vimAlias     = true;
  };


  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

users.users.gwohl = {
  isNormalUser = true;
  home = "/home/gwohl";
  shell = pkgs.fish;
  description = "Andrew Grathwohl";
  extraGroups = [ "wheel" "networkmanager" "audio" ];
};



  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts
      nerdfonts
      google-fonts
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts
      dina-font
      proggyfonts
    ];
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  nix.trustedUsers = [ "root" "gwohl" ];
}

