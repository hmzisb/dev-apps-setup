# Contributing

Thanks for helping. Issues and pull requests are welcome.

## Ground rules

- **Keep it small.** Plain bash 3.2 (the macOS `/bin/bash`), no new dependencies
  beyond Homebrew, gum, git and Herd.
- **Re-runs must be safe.** Every command has to detect finished steps and skip them.
- **Lint before you push:** `shellcheck synk-mac-apps lib/*.sh apps/*.sh`
  and `php -l lib/LocalValetDriver.php`. CI runs the same checks.
- **Test on a real Mac with Herd:** `synk-mac-apps --install <app>`, then `--doctor`
  and `--status`.

## Adding an app

Most apps are static single-page apps that build from a public Git repository.
Create `apps/<app>.sh`:

```bash
TITLE="Name"                       # shown in the wizard
ABOUT="One line"
REPO_URL=https://github.com/o/r.git
DOMAIN=name                        # default domain, .test is added
SOURCE=tags                        # newest vX.Y.Z tag, or a branch name
STORAGE=src/db/                    # paths whose change may alter stored data ("" = none)
NODE=22                            # optional; only if the repo's .nvmrc is wrong
ROOT_REDIRECT=/editor              # optional; where / redirects
build() {                          # runs in src/; build into "$1"
    npm ci --ignore-scripts --no-audit --no-fund
    npx vite build --outDir "$1"
}
```

- `pm` runs the package manager pinned in `package.json`'s `packageManager` field
  (yarn or pnpm). Use it instead of corepack, which Node 25 and newer no longer ship.
- The build must produce `index.html`, and no `.html` page may contain `<?` (Herd
  runs pages through PHP).
- Turn off telemetry and paid-service promos where the app allows it, and say in a
  comment what still talks to the internet.

### A server app (PM2)

For an npm package that runs its own server, like n8n. See `apps/n8n.sh`:

```bash
TITLE="Name"
ABOUT="One line"
TYPE=pm2
PACKAGE=name                        # npm package; --update installs its newest version
SCRIPT=node_modules/name/bin/name   # what PM2 runs, inside the npm install folder
DOMAIN=name
PORT=5678                           # the app listens on 127.0.0.1:PORT
NODE=24
SQLITE=.name/database.sqlite        # optional; in $DATA, copied before each update
app_env() {                         # the app's environment, KEY=value lines; $1 is the domain
    echo "PORT=$PORT"
    echo "DATA_DIR=$DATA"           # keep data in $DATA so an uninstall leaves it
}
```

A server that is a single binary rather than an npm package leaves out `PACKAGE` and
`NODE` and defines two functions instead. See `apps/mailpit.sh`:

```bash
SCRIPT=name                         # the binary, inside the release folder
latest_version() { ...; }           # prints the newest version, like 1.2.3
install_version() { ...; }          # $1 version, $2 folder: puts the release there
EXTRA_PORTS=1025                    # optional; other ports it listens on
IDLE=3600                           # optional; stop after this many seconds without
                                    # connections to its ports or changes in $DATA
```

The app must bind to `127.0.0.1` only. Herd's proxy adds HTTPS and forwards
websockets.

## How the driver serves files

`lib/LocalValetDriver.php` serves the files in `dist`. A route without a file
extension gets `<route>.html` if the build has it, otherwise `404.html` (SvelteKit's
fallback) if present, otherwise `index.html`. A missing file under `/assets/` or
`/_app/`, or any missing path with an extension, gets a real 404.

## Licensing

By contributing you agree to release your contribution under
[CC0-1.0](LICENSE), like the rest of this repository.
