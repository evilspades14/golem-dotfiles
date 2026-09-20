alias reboot-windows="systemctl reboot --boot-loader-entry='auto-windows'"
alias ls="eza -l --icons -a"
if [ "$TERM" = "xterm-kitty" ]; then
    alias ssh='kitty +kitten ssh'
fi

alias edit-caddy="dockhand-edit container caddy /etc/caddy/Caddyfile --env catapult-dragon"
alias reload-caddy="ssh evilspades@catapult-dragon.local 'docker exec caddy caddy -c /etc/caddy/Caddyfile reload'"
