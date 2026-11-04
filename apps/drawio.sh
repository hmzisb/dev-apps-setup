# draw.io: general-purpose diagram editor (flowcharts, UML, network, BPMN, ER).
TITLE=draw.io
ABOUT="Flowcharts, UML, network and other diagrams"
REPO_URL=https://github.com/jgraph/drawio.git
DOMAIN=drawio
SOURCE=tags
STORAGE=""                         # saves to files you choose, or the browser
# No build step: the repo commits its minified app in src/main/webapp. WEB-INF and
# META-INF belong to the optional Java servlets (server export, cloud logins) and
# are left out. On a domain that isn't draw.io's, the app loads js/PreConfig.js,
# whose defaults suit a self-hosted copy: PDF export uses the print dialog.
build() {
    cp -R src/main/webapp/. "$1"
    rm -rf "$1/WEB-INF" "$1/META-INF"
}
