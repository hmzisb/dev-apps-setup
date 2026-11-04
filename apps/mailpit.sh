# Mailpit: catches the mail your local apps send and shows it in a web inbox. A server
# app: one binary from its GitHub releases, run by PM2, reached through a Herd proxy.
# Point apps at SMTP 127.0.0.1:1025 (Laravel: MAIL_MAILER=smtp MAIL_HOST=127.0.0.1
# MAIL_PORT=1025). MIT.
TITLE=Mailpit
ABOUT="Catches mail from local apps (SMTP 127.0.0.1:1025); stops after an idle hour"
TYPE=pm2
SCRIPT=mailpit                     # in the release folder
DOMAIN=mailpit
PORT=8025
EXTRA_PORTS=1025                   # SMTP
IDLE=3600                          # stop after an hour with no mail and no open inbox
SQLITE=mailpit.db                  # in $DATA; copied before every update
latest_version() {
    curl -fsSIL -o /dev/null -w '%{url_effective}' https://github.com/axllent/mailpit/releases/latest |
        sed -n 's#.*/tag/v##p'
}
install_version() { # $1 version, $2 folder
    local arch; arch=$(uname -m); [ "$arch" = x86_64 ] && arch=amd64
    curl -fsSL "https://github.com/axllent/mailpit/releases/download/v$1/mailpit-darwin-$arch.tar.gz" |
        tar -xzf - -C "$2" mailpit
}
app_env() {
    cat <<EOF
MP_UI_BIND_ADDR=127.0.0.1:$PORT
MP_SMTP_BIND_ADDR=127.0.0.1:$EXTRA_PORTS
MP_DATABASE=$DATA/$SQLITE
MP_DISABLE_VERSION_CHECK=true
EOF
}
