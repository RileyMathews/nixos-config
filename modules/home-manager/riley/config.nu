$env.config.keybindings ++= [{
    name: completion_menu
    modifier: control
    keycode: char_f
    mode: emacs
    event: { edit: InsertString value: completion_menu }
}]
