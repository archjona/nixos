{ config, pkgs, lib, ... }:

{
  vim = {
    theme = {
      enable = true;
      name = "gruvbox";
      style = "dark";
    };

    statusline.lualine.enable = true;
    telescope.enable = true;
    autocomplete.nvim-cmp.enable = true;
    terminal.toggleterm.lazygit.enable = true;
    lsp.enable = true;

    # Plugins laut NVF Doku
    extraPlugins = {
      vimtex = {
        package = pkgs.vimPlugins.vimtex;
      };
    };

    # Konfiguration mit Hotkeys
    luaConfigRC.vimtex = ''
      -- Leader auf Leertaste setzen
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- Vimtex Einstellungen
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_view_method = "zathura"
      
      -- Optional: Zathura automatisch öffnen nach dem ersten Compile
      vim.g.vimtex_view_automatic = 1
    '';

    navigation.harpoon = {
      enable = true;
      mappings = {
        markFile = "<leader>a";
        listMarks = "<C-e>";
        file1 = "<leader>1";
        file2 = "<leader>2";
        file3 = "<leader>3";
        file4 = "<leader>4";
      };
    };

    languages = {
      enableTreesitter = true;
      nix.enable = true;
      clang.enable = true;
      clang.lsp.enable = true;
      lua.enable = true;
    };
  };
}
