# n8n: workflow automation. A server app: installed from npm, run by PM2, reached
# through a Herd proxy. Sustainable Use License (free for your own use).
TITLE=n8n
ABOUT="Workflow automation (runs as a server under PM2)"
TYPE=pm2
PACKAGE=n8n
SCRIPT=node_modules/n8n/bin/n8n    # in the npm install folder
DOMAIN=n8n
PORT=5678
NODE=24                            # n8n 2.x needs Node >= 24
# Stop after an hour with no open editor tab, no webhook call and no workflow run (a
# run writes to the database). The task runner's own link is on 5679, not watched.
# While stopped, schedule triggers don't fire and webhooks get 502.
IDLE=3600
SQLITE=.n8n/database.sqlite        # in $DATA; copied before every update
# The app's environment, one KEY=value per line; $1 is the domain. Workflows,
# credentials and the key that encrypts them live in $DATA/.n8n.
# Telemetry and version checks are off; templates and community nodes still use
# n8n's servers when you open them. NODE_EXTRA_CA_CERTS lets workflows call other
# https://*.test sites, whose certificates Herd's own authority signs.
app_env() {
    cat <<EOF
N8N_USER_FOLDER=$DATA
N8N_LISTEN_ADDRESS=127.0.0.1
N8N_PORT=$PORT
N8N_HOST=$1.test
N8N_PROTOCOL=https
N8N_EDITOR_BASE_URL=https://$1.test/
WEBHOOK_URL=https://$1.test/
N8N_PROXY_HOPS=1
N8N_DIAGNOSTICS_ENABLED=false
N8N_VERSION_NOTIFICATIONS_ENABLED=false
NODE_EXTRA_CA_CERTS=$HOME/Library/Application Support/Herd/config/valet/CA/LaravelValetCASelfSigned.pem
GENERIC_TIMEZONE=$(readlink /etc/localtime | sed 's#.*/zoneinfo/##')
EOF
}
