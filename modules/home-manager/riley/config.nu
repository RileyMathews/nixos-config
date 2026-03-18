$env.config.keybindings ++= [
{
    name: completion_menu
    modifier: control
    keycode: char_f
    mode: emacs
    event: [{ edit: InsertString value: zellij-sessionizer  } { send: Enter }]
}
{
    name: accept_suggestion
    modifier: control
    keycode: char_y
    mode: emacs
    event: [{ send: historyhintcomplete }]
}
{
    name: open_neovim
    modifier: control
    keycode: char_e
    mode: emacs
    event: [{ send: openeditor }]
}
]

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.config.buffer_editor = "nvim"
$env.config.show_banner = false

alias mpr = python manage.py runserver
alias mpmm = python manage.py makemigrations
alias mpm = python manage.py migrate
alias mp = python manage.py

alias be = bundle exec
alias ber = bundle exec rails
alias bers = bundle exec rails s

alias dcb = docker compose build
alias dcud = docker compose up -d
alias dcd = docker compose down
alias dclf = docker compose logs -f

alias gst = git status
alias gaa = git add .
alias gcmsg = git commit -m
alias gp = git push
alias gpsup = git push --set-upstream origin (git branch --show-current | str trim)
alias gl = git pull
alias gco = git checkout
alias gcb = git checkout -b
alias gcm = git checkout (git_main_branch | str trim)

alias l = ls -a
alias ll = ls -al

alias k = kubectl
alias ka = kubectl apply -f
alias kar = kubectl apply --recursive -f

alias n = nvim

alias upd = update-arch

alias ap = ansible-playbook

alias s7 = system76-power

alias tss = sudo tailscale switch

alias ghd = gh-dash

alias oc = opencode
alias ocp = opencode --agent plan
alias och = opencode --agent haskell-dev --prompt This project has some compile errors. Please help me fix them.

alias ndr = nix-direnv-reload
