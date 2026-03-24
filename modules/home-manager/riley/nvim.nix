{ pkgs, config, lib, inputs, ... }:
{
  imports = [ inputs.nvf.homeManagerModules.default ];

  programs.nvf = {
    enable = false;
    settings = {
      vim.viAlias = false;
      vim.vimAlias = false;
    };
  };
}
