# JSON Crack: turns JSON, YAML, CSV and XML into an interactive graph.
TITLE="JSON Crack"
ABOUT="JSON, YAML, CSV and XML as interactive graphs"
REPO_URL=https://github.com/AykutSarac/jsoncrack.com.git
DOMAIN=jsoncrack
SOURCE=tags
STORAGE=""                         # the editor keeps its content in sessionStorage only
NODE=24                            # engines: node >= 24
# The landing page at / is marketing; go straight to the editor.
ROOT_REDIRECT=/editor
# A pnpm monorepo: build only the website and the graph library it uses (www...),
# not the VS Code or Chrome extensions. Google Analytics loads only when
# NEXT_PUBLIC_GA_MEASUREMENT_ID is set, which it isn't; the second flag hides the
# prompt to try the paid ToDiagram editor. The text editor (Monaco) still loads its
# code from unpkg.com; your data stays in the browser.
build() {
    pm install --frozen-lockfile --filter 'www...'
    NEXT_PUBLIC_DISABLE_EXTERNAL_MODE=true pm --filter 'www...' run build
    cp -R apps/www/out/. "$1"
    # next build rewrites this tracked file; a dirty checkout would block the next update.
    git checkout -- apps/www/next-env.d.ts
}
