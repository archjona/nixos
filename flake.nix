{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    nvf.url = "github:notashelf/nvf";
    mangowc = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
     zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nvf, home-manager, mangowc, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      # --- DEIN SYSTEM ---
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          { nixpkgs.hostPlatform = system; }
          ./configuration.nix
          ./tmux.nix
          home-manager.nixosModules.default
          nvf.nixosModules.default
          mangowc.nixosModules.mango
          
          # Ermöglicht das Ausführen von Binaries aus der "Außenwelt"
          {
            programs.nix-ld.enable = true;
            programs.nix-ld.libraries = with pkgs; [
              stdenv.cc.cc
              zlib
              libusb1
              libgcrypt
              ncurses
              expat
            ];
          }
        ];
      };

      # --- ENTWICKLUNGS-UMGEBUNGEN (SHELLS) ---
      devShells.${system} = {
        # ESP-IDF Shell: Aufruf mit 'nix develop' oder 'nix develop .#esp'
        esp = pkgs.mkShell {
          name = "esp-idf-env";
          buildInputs = with pkgs; [
            cmake
            ninja
            python3
            git
            wget
            flex
            bison
            gperf
            pkg-config
            libusb1
          ];

          shellHook = ''
            # Dynamic Linker Pfad setzen, damit xtensa-tools starten können
            export NIX_LD=$(nix eval --raw nixpkgs#stdenv.cc.bintools.dynamicLinker)
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc pkgs.zlib pkgs.libusb1 ]}"
            
            echo "--- ESP-IDF Umgebung bereit ---"
            echo "1. ./install.sh (nur beim ersten Mal)"
            echo "2. . ./export.sh"
          '';
        };
        
      yocto = pkgs.mkShell {
  name = "yocto-env";
  buildInputs = with pkgs; [
    # --- Basis Build Tools ---
    gcc
    gnumake
    cmake
    ninja
    pkg-config
    binutils
    patch
    patchelf

    # --- Python ---
    python3
    python3Packages.pip
    python3Packages.pexpect
    python3Packages.jinja2
    python3Packages.gitpython

    # --- SCM ---
    git
    git-lfs
    subversion
    mercurial

    # --- Compression & Archiving ---
    lz4
    zstd
    lzop
    gzip
    bzip2
    xz
    unzip
    zip
    zlib
    cpio

    # --- Shell & Scripting ---
    bash
    gawk
    gnused
    gnugrep
    findutils
    diffutils
    coreutils
    util-linux

    # --- Netzwerk & Download ---
    wget
    curl
    socat

    # --- Filesystem & Device Tools ---
    e2fsprogs
    dosfstools
    mtdutils
    squashfsTools
    parted

    # --- Cross-Compile Support ---
    bc
    flex
    bison
    openssl
    openssl.dev

    # --- Dokumentation & Text ---
    texinfo
    diffstat
    chrpath
    file
    which
    tree

    # --- RPC / Misc ---
    rpcsvc-proto
    rsync
    ncurses
    ncurses.dev

    # --- Locale ---
    glibcLocales
  ];

  shellHook = ''
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"

    # Yocto mag keine Pseudo-Terminals von manchen Tools
    export PSEUDO_DISABLED=0

    # Verhindert Probleme mit Python-Buffering in BitBake
    export PYTHONUNBUFFERED=1

    # Stellt sicher dass temporäre Dateien nicht im RAM laufen
    # (wichtig bei großen Builds)
    export TMPDIR="/tmp"

    echo "--- Yocto/BitBake Umgebung bereit ---"
    echo "Denk dran: source oe-init-build-env <build-dir>"
  '';
};        
        web = pkgs.mkShell {
         name = "web-env";
          buildInputs = with pkgs; [
            nodejs_22
            nodePackages.npm
           python3
           python3Packages.requests
           python3Packages.beautifulsoup4
           python3Packages.fastapi
           python3Packages.uvicorn
         ];
         shellHook = ''
            echo "--- Web Umgebung bereit ---"
            echo "API:     uvicorn api:app --reload"
           echo "Next.js: npm run dev"
         '';
        };        


        /* # Beispiel für weitere Shells:
        web = pkgs.mkShell {
          name = "web-dev";
          buildInputs = with pkgs; [ nodejs yarn ];
          shellHook = "echo 'Web-Development aktiv!'";
        };
        */

        # Setzt die ESP-Shell als Standard, wenn du nur 'nix develop' tippst
        default = self.devShells.${system}.esp;
      };
    };
}
