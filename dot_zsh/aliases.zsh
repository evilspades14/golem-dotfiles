alias reboot-windows="systemctl reboot --boot-loader-entry='auto-windows'"
alias ls="eza -l --icons -a"
if [ "$TERM" = "xterm-kitty" ]; then
    alias ssh='kitty +kitten ssh'
fi

alias caddy-reload="ssh evilspades@catapult-dragon.local 'docker exec caddy caddy -c /etc/caddy/Caddyfile reload'"
alias caddy-edit="dockhand-edit container caddy /etc/caddy/Caddyfile --env catapult-dragon; caddy-reload"

