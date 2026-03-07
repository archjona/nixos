#!/usr/bin/env bash

# Skript zum Ausführen von nixos-rebuild im aktuellen Ordner

echo "🚀 Starte nixos-rebuild im Ordner: $(pwd)"
echo "----------------------------------------"

# Prüfen ob wir im richtigen Ordner sind (wo flake.nix liegt)
if [ ! -f "flake.nix" ]; then
    echo "❌ Fehler: Keine flake.nix im aktuellen Ordner gefunden!"
    echo "Bitte führe das Skript aus dem Verzeichnis mit deiner flake.nix aus."
    exit 1
fi

# Prüfen ob wir sudo Rechte haben
if ! sudo -v; then
    echo "❌ Fehler: Keine sudo Rechte verfügbar!"
    exit 1
fi

echo "✅ flake.nix gefunden, starte rebuild..."

# Ausführen des rebuilds
sudo nixos-rebuild switch --flake . --impure

# Prüfen ob es geklappt hat
if [ $? -eq 0 ]; then
    echo "✅ Rebuild erfolgreich!"
else
    echo "❌ Rebuild fehlgeschlagen!"
    exit 1
fi
