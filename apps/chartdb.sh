# ChartDB: database diagram editor (imports schema from a SQL query, exports DDL).
TITLE=ChartDB
ABOUT="Database schema diagrams"
REPO_URL=https://github.com/chartdb/chartdb.git
DOMAIN=chartdb
SOURCE=tags
STORAGE=src/context/storage-context/
build() {
    npm ci --ignore-scripts --no-audit --no-fund
    npx tsc -b
    npx vite build --outDir "$1"
}
