{ ... }:
{
  programs.fish = {
    enable = true;
    binds = {
      "ctrl-y".command = "accept-autosuggestion";
    };
    shellAliases = {
      gst = "git status";
      gaa = "git add .";
      gcmsg = "git commit -m";
      gp = "git push";
      gpsup = "git push --set-upstream origin $(git branch --show-current)";
      gl = "git pull";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcm = "git checkout $(git_main_branch)";
      l = "ls -al";
      tss = "sudo tailscale switch";
      oc = "opencode";

      mpr = "python manage.py runserver";
      mpmm = "python manage.py makemigrations";
      mpm = "python manage.py migrate";
      mp = "python manage.py";
    };
  };
}
