# Contributing

Thanks for helping. Issues and pull requests are welcome.

## Ground rules

- **Keep it small.** Plain bash 3.2 (the macOS `/bin/bash`), no new dependencies
  beyond Homebrew, gum, git and Herd.
- **Re-runs must be safe.** Every command has to detect finished steps and skip them.
- **Lint before you push:** `shellcheck synk-mac-apps lib/site-update.sh apps/*.sh`
  and `php -l lib/LocalValetDriver.php`. CI runs the same checks.
- **Test on a real Mac with Herd:** `synk-mac-apps --install <app>`, then `--doctor`
  and `--status`.

## Adding an app

An app must be a static single-page app that builds from a public Git repository.
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

## How the driver serves files

`lib/LocalValetDriver.php` serves the files in `dist`. A route without a file
extension gets `<route>.html` if the build has it, otherwise `404.html` (SvelteKit's
fallback) if present, otherwise `index.html`. A missing file under `/assets/` or
`/_app/`, or any missing path with an extension, gets a real 404.

## Licensing

By contributing you agree to release your contribution under
[CC0-1.0](LICENSE), like the rest of this repository.
