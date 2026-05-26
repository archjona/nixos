{ config, pkgs, ... }:
let
  nix-search-script = pkgs.writeShellApplication {
    name = "ns";
    runtimeInputs = with pkgs; [
      fzf
      nix-search-tv
    ];
    text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
  };

  vesktop-fixed = pkgs.writeShellScriptBin "vesktop-fixed" ''
    if [[ "$*" != *"--disable-gpu"* ]]; then
      exec ${pkgs.vesktop}/bin/vesktop \
        --disable-gpu \
        --disable-accelerated-2d-canvas \
        --disable-gpu-compositing \
        --disable-gpu-rasterization \
        --ozone-platform-hint=wayland \
        "$@"
    else
      exec ${pkgs.vesktop}/bin/vesktop "$@"
    fi
  '';

  vesktop-desktop = pkgs.makeDesktopItem {
    name = "vesktop-fixed";
    desktopName = "Vesktop (GPU-Fix)";
    exec = "vesktop-fixed %U";
    icon = "vesktop";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    mimeTypes = [ "x-scheme-handler/discord" ];
    startupWMClass = "Vesktop";
  };

  # HIERHER verschoben - eigene let-Binding, nicht mehr in makeDesktopItem
  phinger-gruvbox = pkgs.stdenvNoCC.mkDerivation {
    pname = "phinger-cursors-gruvbox-material";
    version = "3328966123";

    src = pkgs.fetchurl {
      url = "https://github.com/rehanzo/phinger-cursors-gruvbox-material/releases/download/3328966123/phinger-cursors-variants.tar.bz2";
      hash = "sha256-qAEGY3B0tphEwYGfhkJ555yLgAu1nflCjqCOfZ8vjIE=";
    };

    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/icons
      cp -r phinger-cursors* $out/share/icons/
      runHook postInstall
    '';

    meta.description = "Phinger cursors, Gruvbox Material recolor";
  };

in

{
  home.username = "jona";
  home.homeDirectory = "/home/jona";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    zoxide
    nix-search-tv
    fzf
    nix-search-script
    pkgs.vesktop
    vesktop-fixed
    vesktop-desktop
  ];

  home.sessionVariables = {
    ELECTRON_USE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  gtk = {
    enable = true;
    theme = {
      name = "Gruvbox-Dark";
      package = pkgs.gruvbox-gtk-theme;
    };
    iconTheme = {
      name = "Gruvbox-Plus-Dark";
      package = pkgs.gruvbox-plus-icons;
    };
  };

  home.pointerCursor = {
    name = "phinger-cursors-gruvbox-material";
    package = phinger-gruvbox;
    size = 32;
    gtk.enable = true;
    x11.enable = true;
  };

  xdg.desktopEntries = {
    "vesktop" = {
      name = "Vesktop";
      exec = "vesktop";
      noDisplay = true;
    };
    "xterm" = {
      name = "XTerm";
      exec = "kitty";
      noDisplay = true;
      terminal = false;
    };
    "org.gnome.ColorProfileViewer" = {
      name = "Color Profile Viewer";
      exec = "org.gnome.ColorProfileViewer";
      noDisplay = true;
    };
    "org.freedesktop.IBus.Setup" = {
      name = "IBus Setup";
      exec = "ibus-setup";
      noDisplay = true;
    };
    "org.freedesktop.IBus.Panel.Emojier" = {
      name = "IBus Emojier";
      exec = "ibus-setup";
      noDisplay = true;
    };
    "org.freedesktop.IBus.Panel.Extension.Gtk3" = {
      name = "IBus Extension";
      exec = "ibus-setup";
      noDisplay = true;
    };
    "org.freedesktop.IBus.Panel.Wayland.Gtk3" = {
      name = "IBus Wayland";
      exec = "ibus-setup";
      noDisplay = true;
    };
    "rygel" = {
      name = "Rygel";
      exec = "rygel";
      noDisplay = true;
    };
    "rygel-preferences" = {
      name = "Rygel Preferences";
      exec = "rygel-preferences";
      noDisplay = true;
    };
    "rofi" = {
      name = "Rofi";
      exec = "rofi";
      noDisplay = true;
    };
    "rofi-theme-selector" = {
      name = "Rofi Theme Selector";
      exec = "rofi-theme-selector";
      noDisplay = true;
    };
    "nvidia-settings" = {
      name = "NVIDIA Settings";
      exec = "nvidia-settings";
      noDisplay = true;
    };
    "gcm-calibrate" = {
      name = "Color Calibrate";
      exec = "gcm-calibrate";
      noDisplay = true;
    };
    "gcm-import" = {
      name = "Color Import";
      exec = "gcm-import";
      noDisplay = true;
    };
    "gcm-picker" = {
      name = "Color Picker";
      exec = "gcm-picker";
      noDisplay = true;
    };
    "gnome-color-panel" = {
      name = "Color Panel";
      exec = "gnome-color-panel";
      noDisplay = true;
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(zoxide init bash --cmd cd)"
      alias discord='vesktop-fixed'
    '';
  };

  home.activation.hideAllUnwanted =
    let
      desktopUtils = "${pkgs.desktop-file-utils}/bin";
    in
    ''
      echo "Stelle Verzeichnisberechtigungen sicher..."

      if [ ! -w "/home/jona/.local/share/applications" ]; then
        echo "WARNUNG: /home/jona/.local/share/applications ist nicht beschreibbar!"
        echo "Bitte führe manuell aus:"
        echo "  mkdir -p /home/jona/.local/share/applications"
        exit 1
      fi

      echo "Verstecke unerwünschte Desktop-Einträge mit exakten Namen..."

      unwanted=(
        "xterm"
        "org.gnome.ColorProfileViewer"
        "org.freedesktop.IBus.Setup"
        "org.freedesktop.IBus.Panel.Emojier"
        "org.freedesktop.IBus.Panel.Extension.Gtk3"
        "org.freedesktop.IBus.Panel.Wayland.Gtk3"
        "rygel"
        "rygel-preferences"
        "rofi"
        "rofi-theme-selector"
        "nvidia-settings"
        "gcm-calibrate"
        "gcm-import"
        "gcm-picker"
        "gnome-color-panel"
      )

      for app in "''${unwanted[@]}"; do
        if [ -f "/run/current-system/sw/share/applications/$app.desktop" ]; then
          echo "  Verstecke: $app.desktop"
          install -m 644 "/run/current-system/sw/share/applications/$app.desktop" "/home/jona/.local/share/applications/$app.desktop"
          echo "NoDisplay=true" >> "/home/jona/.local/share/applications/$app.desktop"
          echo "Hidden=true" >> "/home/jona/.local/share/applications/$app.desktop"
        fi
      done

      if [ -f "${pkgs.vesktop}/share/applications/vesktop.desktop" ]; then
        echo "  Verstecke: original Vesktop"
        install -m 644 "${pkgs.vesktop}/share/applications/vesktop.desktop" "/home/jona/.local/share/applications/vesktop.desktop"
        echo "NoDisplay=true" >> "/home/jona/.local/share/applications/vesktop.desktop"
        echo "Hidden=true" >> "/home/jona/.local/share/applications/vesktop.desktop"
      fi

      ${desktopUtils}/update-desktop-database /home/jona/.local/share/applications || true

      echo "Fertig! Alle unerwünschten Einträge sollten jetzt verschwunden sein."
    '';

  home.file = {
    ".config/hypr" = {
      source = ./config/hypr;
      recursive = true;
      force = true;
    };
    ".config/waybar" = {
      source = ./config/waybar;
      recursive = true;
      force = true;
    };
    ".config/ghostty" = {
      source = ./config/ghostty;
      recursive = true;
      force = true;
    };
    ".config/rofi" = {
      source = ./config/rofi;
      recursive = true;
      force = true;
    };
    ".config/kitty" = {
      source = ./config/kitty;
      recursive = true;
      force = true;
    };
    ".config/zathura" = {
      source = ./config/zathura;
      recursive = true;
      force = true;
    };
    ".config/btop" = {
      source = ./config/btop;
      recursive = true;
      force = true;
    };
    ".config/mango" = {
      source = ./config/mango;
      recursive = true;
      force = true;
    };
  };

  programs.home-manager.enable = true;
}
