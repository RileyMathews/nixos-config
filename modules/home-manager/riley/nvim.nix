{ pkgs, config, lib, inputs, ... }:
{
  imports = [ inputs.nvf.homeManagerModules.default ];

  programs.nvf = {
    enable = true;
    settings = {
      vim.viAlias = false;
      vim.vimAlias = false;
    };
  };
}
