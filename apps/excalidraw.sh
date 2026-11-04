# Excalidraw: hand-drawn style whiteboard.
TITLE=Excalidraw
ABOUT="Whiteboard sketches and diagrams"
REPO_URL=https://github.com/excalidraw/excalidraw.git
DOMAIN=draw
SOURCE=tags
STORAGE=excalidraw-app/data/
# .nvmrc says 18, but v0.18.1's locked deps (marked 16) need >= 20; 22 is the top of
# its engines range.
NODE=22
# Sentry and tracking off; share links, libraries and live collaboration still
# use excalidraw.com's free services (set in .env.production).
build() {
    pm install --frozen-lockfile --ignore-scripts --non-interactive
    (cd excalidraw-app && VITE_APP_DISABLE_SENTRY=true VITE_APP_ENABLE_TRACKING=false \
        npx vite build --outDir "$1")
}
