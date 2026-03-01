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

    startPlugins = [
      pkgs.vimPlugins.vimtex
    ];

    # Hier war der Fehler: Innerhalb von "vim = {" darfst du 
    # nicht nochmal "vim." schreiben.
    luaConfigRC.vimtex = ''
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_view_method = "zathura"
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
      clang.lsp.enable = true;
      nix.enable = true;
      clang.enable = true;
      lua.enable = true;
    };
  };
}
