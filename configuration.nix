# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Audio
      <musnix>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #boot.kernelPackages = pkgs.linuxPackages-rt_latest;

  musnix.enable = true;
  ## NO LONGER IN MUSNIX APPARENTLY musnix.kernel.optimize = true;
  musnix.kernel.realtime = true;
  musnix.kernel.packages = pkgs.linuxPackages_5_15_rt;
  #musnix.kernel.packages = pkgs.linuxPackages-rt_latest;
  musnix.das_watchdog.enable = true;

  # CONFIG THIS LATER--NO IDEA IF THIS IS CORRECT
  # #############################################
  musnix.rtirq = {
    resetAll = 1;
    prioLow = 0;
    prioHigh = 95;
    enable = true;
    nameList = "hpet rtc0 snd snd_hdsp usb";
    highList = "timer snd_hdsp";
  };

  musnix.soundcardPciId = "01:00.0";

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  networking.hostName = "flynix";

  time.timeZone = "America/Chicago";

  users.users.gwohl = {
    isNormalUser = true;
    home = "/home/gwohl";
    description = "Andrew A. Grathwohl";
    shell = pkgs.zsh;
    extraGroups = [ "jackaudio" "networkmanager" "audio" "wheel" "fuse"
    "media" "dialout" "realtime" ];
  };

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s25.useDHCP = true;
  networking.interfaces.enp4s0.useDHCP = true;
  networking.interfaces.enp5s0.useDHCP = true;

  # iOS Tethering
  services.usbmuxd.enable = true;

  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      x11.enable = true;
      wall.enable = true;
    };
  };

  # Configure keymap in X11
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.windowManager.i3 = {
  	enable = true;
    extraPackages = with pkgs; [
		dmenu #application launcher most people use
		i3status # gives you the default i3 status bar
		i3lock #default i3 screen locker
		i3blocks #if you are planning on using i3blocks over i3status
	];
  };
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true;
  services.xserver.autorun = false;
  services.xserver.enableCtrlAltBackspace = true;

  services.xserver.displayManager = {
    defaultSession = "none+i3";
    autoLogin = {
      enable = true;
      user = "gwohl";
    };
  };

  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
  };

  services.fstrim.enable = true;
  services.fwupd.enable = true;

#############################################

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };


  # Enable the X11 windowing system.
  #services.xserver.enable = true;
  #hardware.nvidia.powerManagement.enable = true;
  #hardware.nvidia.open = true;
  # Enable sound.
  sound.enable = true;

  hardware.video.hidpi.enable = true;

  services.jack = {
    jackd = {
      enable = true;
      extraOptions = [ "-P95" "-R" "-u" "-dalsa" "-dhw:HDSPMx0a922c,0" "-r48000" "-p64" "-n2" ];
    };
    # support ALSA only programs via ALSA JACK PCM plugin
    alsa.enable = true;
    alsa.support32Bit = true;
    # support ALSA only programs via loopback device (supports programs like Steam)
    loopback = {
      enable = false;
      # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
      #dmixConfig = ''
      #  period_size 2048
      #'';
    };
  };

  #services.thermald.enable = true;


  services.fail2ban = {
    enable = true;

    jails.DEFAULT =
    ''
      bantime  = 3600
    '';

    jails.sshd =
    ''
      filter = sshd
      maxretry = 4
      action   = iptables[name=ssh, port=ssh, protocol=tcp]
      enabled  = true
    '';

    jails.sshd-ddos =
    ''
      filter = sshd-ddos
      maxretry = 2
      action   = iptables[name=ssh, port=ssh, protocol=tcp]
      enabled  = true
    '';

    jails.postfix =
    ''
      filter   = postfix
      maxretry = 3
      action   = iptables[name=postfix, port=smtp, protocol=tcp]
      enabled  = true
    '';

    jails.postfix-sasl =
    ''
      filter   = postfix-sasl
      maxretry = 3
      action   = iptables[name=postfix, port=smtp, protocol=tcp]
      enabled  = true
    '';

    jails.postfix-ddos =
    ''
      filter   = postfix-ddos
      maxretry = 3
      action   = iptables[name=postfix, port=submission, protocol=tcp]
      bantime  = 7200
      enabled  = true
    '';
  };

  environment.etc."fail2ban/filter.d/postfix-ddos.conf".text =
  ''
    [Definition]
    failregex = lost connection after EHLO from \S+\[<HOST>\]
  '';

  # Limit stack size to reduce memory usage
  systemd.services.fail2ban.serviceConfig.LimitSTACK = 256 * 1024;

  programs.mosh.enable = true;

  # services.xserver.xkbOptions = "eurosign:e";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  #   firefox
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.mtr.enable = true;
  programs.iftop.enable = true;
  programs.iotop.enable = true;
  programs.gnupg = {
    agent = {
      enable = true;
      enableBrowserSocket = true;
      enableSSHSupport = true;
    };
    dirmngr = {
      enable = true;
    };
  };
  programs.dconf.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch";
      upgrade = "sudo nixos-rebuild switch --upgrade";
    };
    ohMyZsh = {
      enable = true;
      plugins = [ "themes" "tmux" "vault" "vi-mode" "taskwarrior" "rsync" "npm"
      "pip" "cp" "git" "colored-man-pages" "command-not-found" "extract" "aws" ];
      theme = "fletcherm"; # "ys" "robbyrussell"
    };
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #programs.wireshark.enable = true;

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

  environment.systemPackages = with pkgs; [
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    arandr               # simple GUI for xrandr
    asciinema            # record the terminal
    alacritty
    atop
    awscli2
    betterlockscreen
    blugon
    bpytop
    dunst
    feh
    filelight
    firefox
    fuse
    gcc
    gimp
    git
    glow
    htop
    imagemagick
    libnfs
    libnotify
    libreoffice
    libsodium
    lsof
    jq
    mosh
    nfs-ganesha
    nfs-utils
    nfstrace
    nodejs
    ntfs3g
    openvpn
    pandoc
    pass
    pdf2svg
    python
    python3
    pyright
    ranger
    readline
    rofi
    signal-desktop
    simple-scan
    speedtest-cli
    taskwarrior
    taskwarrior-tui
    tickrs
    unclutter
    unzip
    usbutils
    wget
    whois
    xorg.xwininfo
    xorg.xorgproto
    zbar
    ####AUDIO
    alsaLib
    alsaPlugins
    alsaTools
    alsaUtils
    ardour
    audiowaveform
    bitmeter
    ebumeter
    fftwFloat
    libopus
    libsamplerate
    libshout
    libvorbis
    jack2
    jack_capture
    mimic
    ncmpcpp
    pavucontrol
    pkg-config
    r128gain
    reaper
    shntool
    sndpeek
    sox
    soxr
    timemachine
    yabridge
    yabridgectl
    zita-ajbridge
    zita-at1
    zita-njbridge
    ####MEDIA
    ffmpeg-full
    ffms
    freetype
    gst_all_1.gstreamer
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-devtools
    gst_all_1.gst-rtsp-server
    #gst_all_1.gstreamermm
    gst_all_1.gst-vaapi
    libass
    libarchive
    libpng
    libdrm
    libcaca
    libcdio
    libcdio-paranoia
    libuchardet
    libvdpau-va-gl
    xorg.libXext
    libva1
    libva-utils
    mpv
    #mpv-with-scripts
    #mpvScripts.autoload
    nv-codec-headers
    vaapiVdpau
    vapoursynth
    shotcut
    ####MISC
    neomutt
    thunderbird
    ####NUR
    nur.repos.dan4ik605743.bitmap-fonts
    ###libsodium stuff
    #### from cabal-desktop nix-shell
    #clang
    gnumake
    libtool
    autoconf
    automake
    m4
    libgpgerror
    libuuid
    libcap
    glib
    glibc
    ##newer tools
    rofi-pass
    rofi-systemd
    rofi-mpd
    newsboat
    abook
    dua
    vim
  ];
	environment.variables = {
	    EDITOR = "nvim";
	    FREETYPE_PROPERTIES = "truetype:interpreter-version=38";
	    HISTCONTROL = "ignoredups:erasedups";
	    QT_LOGGING_RULES = "*=false";
	};

  # Enable Redshift.
  services.redshift = {
    enable = true;
    brightness = {
      day = "1";
      night = "0.85";
    };
    temperature = {
      day = 6500;
      night = 3500;
    };
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };


  programs.chromium = {
    enable = true;
    extensions = [
      "chlffgpmiacpedhhbkiomidkjlcfhogd" # pushbullet
      "mbniclmhobmnbdlbpiphghaielnnpgdp" # lightshot
      "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
    ];
    extraOpts = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
      "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [ "en-US" ];
    };
    defaultSearchProviderSuggestURL = "https://encrypted.google.com/complete/search?output=chrome&q={searchTerms}";
    defaultSearchProviderSearchURL = "https://encrypted.google.com/search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}{google:instantExtendedEnabledParameter}ie={inputEncoding}";
  };

  fonts = {
    fontconfig.enable = true;
    fontconfig.defaultFonts = {
      monospace = [
        "Victor Mono"
        "Iosevka"
      ];
      sansSerif = [
        "DejaVu Sans"
        "IPAPGothic"
      ];
      serif = [
        "DejaVu Serif"
        "IPAPMincho"
      ];
    };
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
    	corefonts
      nerdfonts
      google-fonts
      liberation_ttf
      fira-code
      fira-code-symbols
      dina-font
      proggyfonts
      font-awesome
      siji
      victor-mono
      ipafont
      dejavu_fonts
    ];
  };

  environment.sessionVariables = rec {
    XDG_CACHE_HOME  = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_BIN_HOME    = "\${HOME}/.local/bin";
    XDG_DATA_HOME   = "\${HOME}/.local/share";

    NODE_PATH       = "\${HOME}/.npm-global/lib/node_modules";
    PATH = [
      "\${XDG_BIN_HOME}"
      "\${HOME}/.npm-global/bin"
    ];
    JACK_NO_START_SERVER = "1";
    JACK_NO_AUDIO_RESERVATION = "1";

    BROWSER = "firefox";
  };
  environment.shellAliases = {
    ytdl = "yt-dlp -N 10 -w --yes-playlist --download-archive 'archive.log' -i --embed-thumbnail --embed-subs --embed-metadata --embed-chapters --write-subs --write-auto-subs -f best --merge-output-format mkv";
  };

  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.extraConfig = ''
    load-module module-jack-sink channels=2 connect=true
    load-module module-jack-source channels=2 connect=true
    load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1
  '';
  hardware.pulseaudio.daemon.config = {realtime-scheduling = "yes";};
  systemd.user.services.pulseaudio.after = [ "jack.service" ];
  systemd.user.services.pulseaudio.environment = {
    JACK_PROMISCUOUS_SERVER = "jackaudio";
  };

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 7d";
  };

  # Enable all the firmware
  hardware.enableAllFirmware = true;
  # Enable all the firmware with a license allowing redistribution. (i.e. free firmware and firmware-linux-nonfree)
  hardware.enableRedistributableFirmware = true;

  boot.cleanTmpDir = true;

  # Enable microcode updates for Intel CPU
  hardware.cpu.intel.updateMicrocode = true;

  boot.blacklistedKernelModules = [ "snd_hda_codec_realtek" "snd_hda_codec_hdmi" "snd_hda_intel" ];

  security.sudo.wheelNeedsPassword = false;

  location = {
    latitude = 35.9356;
    longitude = -87.2177;
    provider = "geoclue2";
  };

  services.mpd.enable = true;
  services.mpd.musicDirectory = "/mnt/datadaddy/Music";
  services.mpd.extraConfig = ''
    audio_output {
      type "pulse"
      name "Pulseaudio"
      server "127.0.0.1"
    }
    input_cache {
      size "1 GB"
    }
  '';

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  nixpkgs.config.permittedInsecurePackages = [
    "python-2.7.18.6"
  ];

}
