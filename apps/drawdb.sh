# drawDB: drag-and-drop database diagram editor.
TITLE=drawDB
ABOUT="Database diagrams, drag and drop"
REPO_URL=https://github.com/drawdb-io/drawdb.git
DOMAIN=drawdb
SOURCE=tags
STORAGE=src/data/db.js
# The landing page at / is marketing; go straight to the editor.
ROOT_REDIRECT=/editor
build() {
    npm ci --ignore-scripts --no-audit --no-fund
    npx vite build --outDir "$1"
}
