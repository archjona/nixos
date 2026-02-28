{
  description = "A very basic flake with Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";  # Oder der passende System-Typ für dein System

      modules = [
        ./configuration.nix  # Deine NixOS-Konfiguration
      ];
    };

    # Home Manager Konfiguration
    homeConfigurations = {
      myUser = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;  # Anpassen je nach System-Architektur
        modules = [
          # Hier kannst du deine Home Manager Module einfügen
          ./home.nix  # Beispiel für eine separate Home Manager Konfigurationsdatei
        ];
        home.directory = "/home/jona";  # Dein Home-Verzeichnis (anpassen)
        home.stateVersion = "22.05";  # Version von Home Manager (anpassen)
      };
    };
  };
}
