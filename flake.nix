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
                 git
                 gcc
                 gnumake
                 python3
                 diffstat
                 chrpath
                 gawk
                 file
                 wget
                 cpio
                 unzip
                 rsync
                 bc
                 lz4
                 zstd
                 # Yocto-spezifisch
                 rpcsvc-proto
                 texinfo
         ];
        shellHook = ''
          export LANG=en_US.UTF-8
          echo "--- Yocto/BitBake Umgebung bereit ---"
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
