{ config, ... }:
{
  programs.fish = {
    enable = true;
    binds = {
      "ctrl-y".command = "accept-autosuggestion";
      "ctrl-s".command = "zellij-sessionizer";
    };
    shellAliases = {
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
    interactiveShellInit = ''
      set -gx GITHUB_TOKEN (cat ${config.age.secrets.github-token-file.path})
      set -gx FORGEJO_TOKEN (cat ${config.age.secrets.forgejo-token-file.path})
      set -gx FORGEJO_ACCESS_TOKEN (cat ${config.age.secrets.forgejo-token-file.path})
      set -gx PERSONAL_OPENAI_TOKEN (cat ${config.age.secrets.openai-personal-api-token-file.path})
    '' + builtins.readFile ./custom.fish;
  };
}
