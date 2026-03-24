status is-interactive; and begin
  set -U fish_greeting ""

  alias gst 'git status'
  alias gaa 'git add .'
  alias gcmsg 'git commit -m'
  alias gp 'git push'
  alias gpsup 'git push --set-upstream origin $(git branch --show-current)'
  alias gl 'git pull'
  alias gco 'git checkout'
  alias gcm 'git checkout $(git_main_branch)'
  alias l 'ls -al'
  alias tss 'sudo tailscale switch'
  alias oc 'opencode'

  alias mpr 'python manage.py runserver'
  alias mpmm 'python manage.py makemigrations'
  alias mpm 'python manage.py migrate'
  alias mp 'python manage.py'
  alias vim '/run/current-system/sw/bin/nvim'

  function gcb -a branch_name -d 'make a new branch with worktrunk and zellij'
      wt switch -c $branch_name -x 'zellij -s {{ worktree_name }}'
  end

  function gw -d 'run ghciwatch with additional fields for my local workflow'
      services up
      make ghciwatch | tee .devel-logs/output.txt
  end

  set -l agenix_dir "$XDG_RUNTIME_DIR/agenix"

  if test -r "$agenix_dir/github-token-file"
      set -gx GITHUB_TOKEN (string trim (cat "$agenix_dir/github-token-file"))
  end

  if test -r "$agenix_dir/forgejo-token-file"
      set -gx FORGEJO_TOKEN (string trim (cat "$agenix_dir/forgejo-token-file"))
      set -gx FORGEJO_ACCESS_TOKEN $FORGEJO_TOKEN
  end

  if test -r "$agenix_dir/openai-personal-api-token-file"
      set -gx PERSONAL_OPENAI_TOKEN (string trim (cat "$agenix_dir/openai-personal-api-token-file"))
  end

  zoxide init fish | source
  direnv hook fish | source
  wt config shell init fish | source
  tv init fish | source
  starship init fish | source
end
