alias reboot-windows="systemctl reboot --boot-loader-entry='auto-windows'"
alias ls="eza -l --icons"
if [ "$TERM" = "xterm-kitty" ]; then
    alias ssh='kitty +kitten ssh'
fi