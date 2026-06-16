{
  config,
  pkgs,
  inputs,
  ...
}:
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
  imports = [
    inputs.noctalia.homeModules.default
  ];
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

  programs.noctalia-shell = {
    enable = true;
    settings = {
      settingsVersion = 59;

      bar = {
        barType = "framed";
        position = "left";
        monitors = [ ];
        density = "spacious";
        showOutline = false;
        showCapsule = true;
        capsuleOpacity = 1;
        capsuleColorKey = "none";
        widgetSpacing = 6;
        contentPadding = 2;
        fontScale = 1;
        enableExclusionZoneInset = true;
        backgroundOpacity = 0.93;
        useSeparateOpacity = false;
        marginVertical = 4;
        marginHorizontal = 4;
        frameThickness = 10;
        frameRadius = 12;
        outerCorners = true;
        hideOnOverview = false;
        displayMode = "always_visible";
        autoHideDelay = 500;
        autoShowDelay = 150;
        showOnWorkspaceSwitch = true;
        widgets = {
          left = [
            {
              clockColor = "primary";
              customFont = "";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
              tooltipFormat = "HH:mm ddd, MMM dd";
              useCustomFont = false;
            }
            {
              compactMode = true;
              diskPath = "/";
              iconColor = "secondary";
              id = "SystemMonitor";
              showCpuCores = false;
              showCpuFreq = false;
              showCpuTemp = true;
              showCpuUsage = true;
              showDiskAvailable = false;
              showDiskUsage = false;
              showDiskUsageAsPercent = false;
              showGpuTemp = false;
              showLoadAverage = false;
              showMemoryAsPercent = false;
              showMemoryUsage = true;
              showNetworkStats = false;
              showSwapUsage = false;
              textColor = "none";
              useMonospaceFont = true;
              usePadding = false;
            }
            {
              colorizeIcons = false;
              hideMode = "hidden";
              id = "ActiveWindow";
              maxWidth = 145;
              scrollingMode = "hover";
              showIcon = true;
              showText = true;
              textColor = "none";
              useFixedWidth = false;
            }
            {
              compactMode = false;
              hideMode = "hidden";
              hideWhenIdle = false;
              id = "MediaMini";
              maxWidth = 145;
              panelShowAlbumArt = true;
              scrollingMode = "hover";
              showAlbumArt = true;
              showArtistFirst = true;
              showProgressRing = true;
              showVisualizer = false;
              textColor = "none";
              useFixedWidth = false;
              visualizerType = "linear";
            }
          ];
          center = [
            {
              characterCount = 2;
              colorizeIcons = false;
              emptyColor = "secondary";
              enableScrollWheel = true;
              focusedColor = "tertiary";
              followFocusedScreen = false;
              fontWeight = "bold";
              groupedBorderOpacity = 1;
              hideUnoccupied = false;
              iconScale = 0.8;
              id = "Workspace";
              labelMode = "index";
              occupiedColor = "primary";
              pillSize = 0.6;
              showApplications = false;
              showApplicationsHover = false;
              showBadge = true;
              showLabelsOnlyWhenOccupied = true;
              unfocusedIconsOpacity = 1;
            }
          ];
          right = [
            {
              deviceNativePath = "__default__";
              displayMode = "graphic-clean";
              hideIfIdle = false;
              hideIfNotDetected = true;
              id = "Battery";
              showNoctaliaPerformance = false;
              showPowerProfiles = false;
            }
            {
              blacklist = [ ];
              chevronColor = "none";
              colorizeIcons = false;
              drawerEnabled = false;
              hidePassive = false;
              id = "Tray";
              pinned = [ ];
            }
            {
              displayMode = "onhover";
              iconColor = "error";
              id = "Volume";
              middleClickCommand = "pwvucontrol || pavucontrol";
              textColor = "none";
            }
            {
              colorizeDistroLogo = false;
              colorizeSystemIcon = "tertiary";
              colorizeSystemText = "none";
              customIconPath = "";
              enableColorization = true;
              icon = "noctalia";
              id = "ControlCenter";
              useDistroLogo = true;
            }
          ];
        };
        mouseWheelAction = "none";
        reverseScroll = false;
        mouseWheelWrap = true;
        middleClickAction = "none";
        middleClickFollowMouse = false;
        middleClickCommand = "";
        rightClickAction = "controlCenter";
        rightClickFollowMouse = true;
        rightClickCommand = "";
        screenOverrides = [ ];
      };

      general = {
        avatarImage = "/home/jona/.face";
        dimmerOpacity = 0.2;
        showScreenCorners = false;
        forceBlackScreenCorners = false;
        scaleRatio = 1;
        radiusRatio = 1;
        iRadiusRatio = 1;
        boxRadiusRatio = 1;
        screenRadiusRatio = 1;
        animationSpeed = 1;
        animationDisabled = false;
        compactLockScreen = false;
        lockScreenAnimations = false;
        lockOnSuspend = true;
        showSessionButtonsOnLockScreen = true;
        showHibernateOnLockScreen = false;
        enableLockScreenMediaControls = false;
        enableShadows = true;
        enableBlurBehind = true;
        shadowDirection = "bottom_right";
        shadowOffsetX = 2;
        shadowOffsetY = 3;
        language = "";
        allowPanelsOnScreenWithoutBar = true;
        showChangelogOnStartup = true;
        telemetryEnabled = false;
        enableLockScreenCountdown = true;
        lockScreenCountdownDuration = 10000;
        autoStartAuth = false;
        allowPasswordWithFprintd = false;
        clockStyle = "custom";
        clockFormat = "hh\nmm";
        passwordChars = false;
        lockScreenMonitors = [ ];
        lockScreenBlur = 0;
        lockScreenTint = 0;
        keybinds = {
          keyUp = [ "Up" ];
          keyDown = [ "Down" ];
          keyLeft = [ "Left" ];
          keyRight = [ "Right" ];
          keyEnter = [
            "Return"
            "Enter"
          ];
          keyEscape = [ "Esc" ];
          keyRemove = [ "Del" ];
        };
        reverseScroll = false;
        smoothScrollEnabled = true;
      };

      ui = {
        fontDefault = "Sans Serif";
        fontFixed = "monospace";
        fontDefaultScale = 1;
        fontFixedScale = 1;
        tooltipsEnabled = true;
        scrollbarAlwaysVisible = true;
        boxBorderEnabled = false;
        panelBackgroundOpacity = 0.93;
        translucentWidgets = false;
        panelsAttachedToBar = true;
        settingsPanelMode = "attached";
        settingsPanelSideBarCardStyle = false;
      };

      location = {
        name = "";
        weatherEnabled = true;
        weatherShowEffects = true;
        weatherTaliaMascotAlways = false;
        useFahrenheit = false;
        use12hourFormat = false;
        showWeekNumberInCalendar = false;
        showCalendarEvents = true;
        showCalendarWeather = true;
        analogClockInCalendar = false;
        firstDayOfWeek = -1;
        hideWeatherTimezone = false;
        hideWeatherCityName = false;
        autoLocate = false;
      };

      calendar = {
        cards = [
          {
            enabled = true;
            id = "calendar-header-card";
          }
          {
            enabled = true;
            id = "calendar-month-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
        ];
      };

      wallpaper = {
        enabled = true;
        overviewEnabled = false;
        directory = "/home/jona/Pictures/Wallpapers";
        monitorDirectories = [ ];
        enableMultiMonitorDirectories = false;
        showHiddenFiles = false;
        viewMode = "single";
        setWallpaperOnAllMonitors = true;
        linkLightAndDarkWallpapers = true;
        fillMode = "crop";
        fillColor = "#000000";
        useSolidColor = false;
        solidColor = "#1a1a2e";
        automationEnabled = true;
        wallpaperChangeMode = "random";
        randomIntervalSec = 300;
        transitionDuration = 1500;
        transitionType = [
          "fade"
          "disc"
          "stripes"
          "wipe"
          "pixelate"
          "honeycomb"
        ];
        skipStartupTransition = false;
        transitionEdgeSmoothness = 0.05;
        panelPosition = "follow_bar";
        hideWallpaperFilenames = false;
        useOriginalImages = false;
        overviewBlur = 0.4;
        overviewTint = 0.6;
        useWallhaven = false;
        wallhavenQuery = "";
        wallhavenSorting = "relevance";
        wallhavenOrder = "desc";
        wallhavenCategories = "111";
        wallhavenPurity = "100";
        wallhavenRatios = "";
        wallhavenApiKey = "";
        wallhavenResolutionMode = "atleast";
        wallhavenResolutionWidth = "";
        wallhavenResolutionHeight = "";
        sortOrder = "name";
        favorites = [ ];
      };

      appLauncher = {
        enableClipboardHistory = false;
        autoPasteClipboard = false;
        enableClipPreview = true;
        clipboardWrapText = true;
        enableClipboardSmartIcons = true;
        enableClipboardChips = true;
        clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
        clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
        position = "center";
        pinnedApps = [ ];
        sortByMostUsed = true;
        terminalCommand = "alacritty -e";
        customLaunchPrefixEnabled = false;
        customLaunchPrefix = "";
        viewMode = "list";
        showCategories = true;
        iconMode = "tabler";
        showIconBackground = false;
        enableSettingsSearch = true;
        enableWindowsSearch = true;
        enableSessionSearch = true;
        ignoreMouseInput = false;
        screenshotAnnotationTool = "";
        overviewLayer = false;
        density = "default";
      };

      controlCenter = {
        position = "close_to_bar_button";
        diskPath = "/";
        shortcuts = {
          left = [
            { id = "Network"; }
            { id = "WallpaperSelector"; }
          ];
          right = [
            {
              enableOnStateLogic = false;
              generalTooltipText = "";
              icon = "heart";
              id = "CustomButton";
              onClicked = "";
              onMiddleClicked = "";
              onRightClicked = "";
              showExecTooltip = true;
              stateChecksJson = "[]";
            }
            { id = "NightLight"; }
          ];
        };
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = false;
            id = "brightness-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
      };

      systemMonitor = {
        cpuWarningThreshold = 80;
        cpuCriticalThreshold = 90;
        tempWarningThreshold = 80;
        tempCriticalThreshold = 90;
        gpuWarningThreshold = 80;
        gpuCriticalThreshold = 90;
        memWarningThreshold = 80;
        memCriticalThreshold = 90;
        swapWarningThreshold = 80;
        swapCriticalThreshold = 90;
        diskWarningThreshold = 80;
        diskCriticalThreshold = 90;
        diskAvailWarningThreshold = 20;
        diskAvailCriticalThreshold = 10;
        batteryWarningThreshold = 20;
        batteryCriticalThreshold = 5;
        enableDgpuMonitoring = false;
        useCustomColors = false;
        warningColor = "";
        criticalColor = "";
        externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
      };

      noctaliaPerformance = {
        disableWallpaper = true;
        disableDesktopWidgets = true;
      };

      dock = {
        enabled = false;
        position = "bottom";
        displayMode = "auto_hide";
        dockType = "floating";
        backgroundOpacity = 1;
        floatingRatio = 1;
        size = 1;
        onlySameOutput = true;
        monitors = [ ];
        pinnedApps = [ ];
        colorizeIcons = false;
        showLauncherIcon = false;
        launcherPosition = "end";
        launcherUseDistroLogo = false;
        launcherIcon = "";
        launcherIconColor = "none";
        pinnedStatic = false;
        inactiveIndicators = false;
        groupApps = false;
        groupContextMenuMode = "extended";
        groupClickAction = "cycle";
        groupIndicatorStyle = "dots";
        deadOpacity = 0.6;
        animationSpeed = 1;
        sitOnFrame = false;
        showDockIndicator = false;
        indicatorThickness = 3;
        indicatorColor = "primary";
        indicatorOpacity = 0.6;
      };

      network = {
        bluetoothRssiPollingEnabled = false;
        bluetoothRssiPollIntervalMs = 60000;
        networkPanelView = "wifi";
        wifiDetailsViewMode = "grid";
        bluetoothDetailsViewMode = "grid";
        bluetoothHideUnnamedDevices = false;
        disableDiscoverability = false;
        bluetoothAutoConnect = true;
      };

      sessionMenu = {
        enableCountdown = true;
        countdownDuration = 0;
        position = "center";
        showHeader = true;
        showKeybinds = true;
        largeButtonsStyle = true;
        largeButtonsLayout = "single-row";
        powerOptions = [
          {
            action = "lock";
            command = "";
            countdownEnabled = false;
            enabled = true;
            keybind = "1";
          }
          {
            action = "suspend";
            command = "";
            countdownEnabled = false;
            enabled = false;
            keybind = "";
          }
          {
            action = "hibernate";
            command = "";
            countdownEnabled = false;
            enabled = false;
            keybind = "";
          }
          {
            action = "reboot";
            command = "";
            countdownEnabled = false;
            enabled = true;
            keybind = "2";
          }
          {
            action = "logout";
            command = "";
            countdownEnabled = false;
            enabled = true;
            keybind = "3";
          }
          {
            action = "shutdown";
            command = "";
            countdownEnabled = false;
            enabled = true;
            keybind = "4";
          }
          {
            action = "rebootToUefi";
            command = "";
            countdownEnabled = false;
            enabled = false;
            keybind = "";
          }
          {
            action = "userspaceReboot";
            command = "";
            countdownEnabled = false;
            enabled = false;
            keybind = "";
          }
        ];
      };

      notifications = {
        enabled = true;
        enableMarkdown = false;
        density = "default";
        monitors = [ ];
        location = "top_right";
        overlayLayer = true;
        backgroundOpacity = 1;
        respectExpireTimeout = false;
        lowUrgencyDuration = 3;
        normalUrgencyDuration = 8;
        criticalUrgencyDuration = 15;
        clearDismissed = true;
        saveToHistory = {
          low = true;
          normal = true;
          critical = true;
        };
        sounds = {
          enabled = false;
          volume = 0.5;
          separateSounds = false;
          criticalSoundFile = "";
          normalSoundFile = "";
          lowSoundFile = "";
          excludedApps = "discord,firefox,chrome,chromium,edge";
        };
        enableMediaToast = false;
        enableKeyboardLayoutToast = true;
        enableBatteryToast = true;
      };

      osd = {
        enabled = true;
        location = "top_right";
        autoHideMs = 2000;
        overlayLayer = true;
        backgroundOpacity = 1;
        enabledTypes = [
          0
          1
          2
        ];
        monitors = [ ];
      };

      audio = {
        volumeStep = 5;
        volumeOverdrive = true;
        spectrumFrameRate = 30;
        visualizerType = "linear";
        spectrumMirrored = true;
        mprisBlacklist = [ ];
        preferredPlayer = "";
        volumeFeedback = false;
        volumeFeedbackSoundFile = "";
      };

      brightness = {
        brightnessStep = 5;
        enforceMinimum = true;
        enableDdcSupport = false;
        backlightDeviceMappings = [ ];
      };

      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Gruvbox";
        darkMode = true;
        schedulingMode = "off";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        generationMethod = "tonal-spot";
        monitorForColors = "";
        syncGsettings = true;
      };

      templates = {
        activeTemplates = [ ];
        enableUserTheming = false;
      };

      nightLight = {
        enabled = false;
        forced = false;
        autoSchedule = true;
        nightTemp = "4000";
        dayTemp = "6500";
        manualSunrise = "06:30";
        manualSunset = "18:30";
      };

      hooks = {
        enabled = false;
        wallpaperChange = "";
        darkModeChange = "";
        screenLock = "";
        screenUnlock = "";
        performanceModeEnabled = "";
        performanceModeDisabled = "";
        startup = "";
        session = "";
        colorGeneration = "";
      };

      plugins = {
        autoUpdate = false;
        notifyUpdates = true;
      };

      idle = {
        enabled = false;
        screenOffTimeout = 600;
        lockTimeout = 660;
        suspendTimeout = 1800;
        fadeDuration = 5;
        screenOffCommand = "";
        lockCommand = "";
        suspendCommand = "";
        resumeScreenOffCommand = "";
        resumeLockCommand = "";
        resumeSuspendCommand = "";
        customCommands = "[]";
      };

      desktopWidgets = {
        enabled = false;
        overviewEnabled = true;
        gridSnap = false;
        gridSnapScale = false;
        monitorWidgets = [ ];
      };
    };
  };
  programs.home-manager.enable = true;
}
