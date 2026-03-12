{ config, pkgs, lib, inputs, ... }:

{
  imports =
    [ 
      /etc/nixos/hardware-configuration.nix
      ./nvf-configuration.nix
    ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  # 👇 GRUB mit Theme und korrekter Auflösung
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      
      # Gruvbox-Theme
      theme = pkgs.fetchFromGitHub {
        owner = "Atif-Mahmud";
        repo = "nix-gruv-grub";
        rev = "269507de98ecd4fd9c57aa06bf5d8132d6949a06";
        sha256 = "sha256-UEPZxyT09Z0PiOka/Dh4m8VvqF4l+01eZVbRkPJduDk=";
      } + "/tartarus";
      
      # 👇 DAS IST DER RICHTIGE WEG - DIREKTE OPTIONEN
      gfxmodeEfi = "1024x768";        # Für EFI-Systeme (dein Laptop)
      gfxpayloadEfi = "keep";          # Beibehaltung für Kernel
      
      # Optional: Auch für BIOS fallback
      gfxmodeBios = "1024x768";
      gfxpayloadBios = "keep";
      
      # extraConfig kann dann leer bleiben oder für andere Dinge
      extraConfig = ''
        # Hier nichts zur Auflösung - das ist jetzt oben geregelt
      '';
    };
  };
  networking.hostName = "nixos";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Berlin";
  nixpkgs.config.allowUnfree = true;

  services.xserver = {
    enable = true;
    displayManager.sessionCommands = ''
      export XCURSOR_THEME=Adwaita
      export XCURSOR_SIZE=24
    '';
  };

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  
  environment.gnome.excludePackages = with pkgs; [
    xterm gnome-terminal gnome-console
    epiphany geary gnome-software gnome-tour
    gnome-connections gnome-contacts gnome-characters
    gnome-font-viewer simple-scan evince gnome-calculator
    gnome-calendar gnome-clocks cheese baobab
    gnome-disk-utility seahorse eog totem
  ];
  
  services.printing.enable = false;
  
  environment.variables = {
    TERMINAL = "kitty";
  }; 
  
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  # Virtualisierung mit QEMU/KVM - BASIS-Konfiguration
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
    docker.enable = true;
    podman.enable = true;
  };

  users.users.jona = {
    isNormalUser = true;
    description = "Jona-Elia";
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      "docker" 
      "dialout" 
      "tty" 
      "libvirtd"
      "audio"
    ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "jona" = import ./home.nix;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  programs.nvf = {
    enable = true;
    defaultEditor = true;
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # Optimierung für minimale Latenz
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.min-quantum" = 32;
      };
    };
  };

  console.keyMap = "de";

  environment.systemPackages = with pkgs; [
    wget git hyprpaper waybar kitty ghostty swww pywal
    gcc cmake clang python3 nerd-fonts.jetbrains-mono
    tmux lazygit hyprshot hyprlock hypridle alsa-utils
    rofi btop librewolf spotify vesktop flatpak zoxide
    fzf zathura texlivePackages.latexmk texliveFull
    docker lazydocker distrobox fastfetch adwaita-icon-theme
    pavucontrol nautilus loupe celluloid wineWow64Packages.waylandFull winetricks 
    
    # QEMU/KVM Tools
    virt-manager
    virt-viewer
    qemu
    spice
    spice-gtk
    virtio-win
    swtpm
  ];

  programs.hyprland.enable = true;
  programs.hyprland.package = inputs.hyprland.packages."${pkgs.system}".hyprland;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  programs.mango.enable = true;

  system.stateVersion = "24.11";
}
