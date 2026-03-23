{ config, lib, pkgs, ... }:
let
  aliases = {
    gst = "git status";
    gaa = "git add .";
    gcmsg = "git commit -m";
    gp = "git push";
    gpsup = "git push --set-upstream origin $(git branch --show-current)";
    gl = "git pull";
    gco = "git checkout";
    gcm = "git checkout $(git_main_branch)";
    l = "ls -al";
    tss = "sudo tailscale switch";
    oc = "opencode";

    mpr = "python manage.py runserver";
    mpmm = "python manage.py makemigrations";
    mpm = "python manage.py migrate";
    mp = "python manage.py";
    vim = "/run/current-system/sw/bin/nvim";
  };

  binds = {
    "ctrl-y" = "accept-autosuggestion";
    "ctrl-s" = "tv start-code";
  };

  aliasLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "alias ${name} ${lib.escapeShellArg value}") aliases
  );

  bindLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (key: command: "bind ${key} ${lib.escapeShellArg command}") binds
  );

  purePlugin = pkgs.fishPlugins.pure;
  pureFunctionPath = "${purePlugin}/share/fish/vendor_functions.d";
  pureConfPath = "${purePlugin}/share/fish/vendor_conf.d";

  colorLines = lib.concatStringsSep "\n" [
    "set -g fish_color_autosuggestion 6c7086"
    "set -g fish_color_cancel -r"
    "set -g fish_color_command green"
    "set -g fish_color_comment 6c7086"
    "set -g fish_color_cwd green"
    "set -g fish_color_cwd_root red"
    "set -g fish_color_end brblack"
    "set -g fish_color_error red"
    "set -g fish_color_escape yellow"
    "set -g fish_color_history_current --bold"
    "set -g fish_color_host normal"
    "set -g fish_color_match --background=brblue"
    "set -g fish_color_normal normal"
    "set -g fish_color_operator blue"
    "set -g fish_color_param a6adc8"
    "set -g fish_color_quote yellow"
    "set -g fish_color_redirection cyan"
    "set -g fish_color_search_match bryellow --background=45475a"
    "set -g fish_color_selection white --bold --background=45475a"
    "set -g fish_color_status red"
    "set -g fish_color_user brgreen"
    "set -g fish_color_valid_path --underline"
    "set -g fish_pager_color_completion normal"
    "set -g fish_pager_color_description yellow --dim"
    "set -g fish_pager_color_prefix white --bold"
    "set -g fish_pager_color_progress brwhite --background=cyan"
  ];

  pureLines = lib.concatStringsSep "\n" [
    "set -g pure_begin_prompt_with_current_directory true"
    "set -g pure_check_for_new_release false"
    "set -g pure_convert_exit_status_to_signal false"
    "set -g pure_enable_aws_profile true"
    "set -g pure_enable_container_detection true"
    "set -g pure_enable_git true"
    "set -g pure_enable_k8s false"
    "set -g pure_enable_nixdevshell false"
    "set -g pure_enable_single_line_prompt false"
    "set -g pure_enable_virtualenv true"
    "set -g pure_reverse_prompt_symbol_in_vimode true"
    "set -g pure_separate_prompt_on_error false"
    "set -g pure_show_exit_status false"
    "set -g pure_show_jobs false"
    "set -g pure_show_numbered_git_indicator false"
    "set -g pure_show_prefix_root_prompt false"
    "set -g pure_show_subsecond_command_duration false"
    "set -g pure_show_system_time false"
    "set -g pure_threshold_command_duration 5"
    "set -g pure_truncate_prompt_current_directory_keeps -1"
    "set -g pure_truncate_window_title_current_directory_keeps -1"
  ];
in
{
  options.riley.fish.package.enable = lib.mkEnableOption "install fish from Home Manager" // {
    default = true;
  };

  config = {
    home.packages = lib.optional config.riley.fish.package.enable pkgs.fish;

    xdg.configFile."fish/config.fish".text = ''
      # ~/.config/fish/config.fish: DO NOT EDIT -- this file has been generated
      # automatically by home-manager.

      set -q __riley_fish_config_sourced; and exit
      set -g __riley_fish_config_sourced 1

      set -g fish_function_path "${pureFunctionPath}" $fish_function_path

      source "${pureConfPath}/_pure_init.fish"
      source "${pureConfPath}/pure.fish"

      ${colorLines}
      ${pureLines}

      status is-interactive; and begin
        ${aliasLines}

        ${builtins.readFile ./custom.fish}
      end
    '';

    xdg.configFile."fish/functions/fish_user_key_bindings.fish".text = ''
      function fish_user_key_bindings
        ${bindLines}
      end
    '';
  };
}
