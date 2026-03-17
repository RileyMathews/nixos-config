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
