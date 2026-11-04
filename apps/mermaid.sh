# Mermaid Live Editor: text-to-diagram editor. Built from the develop branch, since
# the project has no releases.
TITLE="Mermaid Live Editor"
ABOUT="Diagrams from text (flowcharts, sequences)"
REPO_URL=https://github.com/mermaid-js/mermaid-live-editor.git
DOMAIN=flow
SOURCE=develop
STORAGE=
# Scripts are skipped: postinstall would run husky and edit .git/config.
# The env var turns off the Mermaid Chart (paid) promo links; it must be set in the
# environment, since svelte.config.js loads .env over any .env.local.
build() {
    pm install --frozen-lockfile --ignore-scripts
    npx svelte-kit sync
    MERMAID_IS_ENABLED_MERMAID_CHART_LINKS=false pm build
    rm -rf "$1" && mv docs "$1"
}
