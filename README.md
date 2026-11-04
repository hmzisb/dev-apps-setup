# dev-apps-setup

Local copies of open-source web apps, built from source and served by
[Laravel Herd](https://herd.laravel.com) at `https://<name>.test`. No Docker and no
background processes. Each app updates itself weekly, the next time you open it.

| App | Default URL | Source |
|---|---|---|
| ChartDB, database schema diagrams | https://chartdb.test | newest release tag |
| drawDB, database diagrams | https://drawdb.test | newest release tag |
| Excalidraw, whiteboard | https://draw.test | newest release tag |
| Mermaid Live Editor, diagrams from text | https://flow.test | `develop` branch (no releases) |

## New Mac

```bash
git clone https://github.com/hmzisb/dev-apps-setup.git ~/Desktop/Apps/dev-apps-setup
~/Desktop/Apps/dev-apps-setup/synk-mac-apps --setup
```

The wizard installs what is missing: Homebrew, gum and git, then Herd. For Herd you
finish its first-run window yourself and turn on Node in Herd > Settings > Node.
It then links the `synk-mac-apps` command into Homebrew's `bin`. Finally it goes
through each app and asks whether to install it and on which domain.

## Commands

```
synk-mac-apps --setup                 wizard; re-run it any time to add, move, update or remove apps
synk-mac-apps --status                versions, last update, last check, HTTP status
synk-mac-apps --doctor                checks everything, exits 1 on a problem
synk-mac-apps --update [app|all]      check for and build new versions now
synk-mac-apps --install [app] [--domain name]   install, move, or repair an app
synk-mac-apps --uninstall [app] [-y]  remove an app
synk-mac-apps --list                  known apps
```

Every command is safe to re-run. Finished steps (clone, build, Herd link,
certificate) are detected and skipped, and `--install` on an installed app repairs
whatever drifted.

## Layout

```
synk-mac-apps            the CLI
apps/<app>.sh            one manifest per app (what to clone, how to build it)
lib/site-update.sh       builds and deploys a new version of one app
lib/LocalValetDriver.php Herd driver shared by every app
active-setup/            git-ignored; everything generated lives here
  sites/<app>/
    src/                 git clone of the app
    builds/<version>/    the live build and the previous one
    dist -> builds/...   what Herd serves; swapped atomically
    domain               the installed domain (without .test)
    .auto-update/        update.log, last-check, last-updated
```

## How updates work

The first page load after 7 days runs `lib/site-update.sh <app>` in the background:

1. It asks GitHub for the newest stable `vX.Y.Z` tag, or for the newest commit on
   the branch.
2. It builds that version into `builds/<version>` with the Node version the app
   needs, installed through Herd's nvm.
3. It swaps `dist` to the new build. The site never goes down, and a failed build
   leaves the old one live and is retried the next day.
4. Files from the previous build are carried forward one release, so tabs that were
   already open keep working.
5. The live build and the previous one are kept. Roll back with:
   `ln -sfn builds/<old> dist.tmp && mv -fh dist.tmp dist` inside the app's site
   folder. The rollback lasts until the next check (a week, or `--update`), which
   builds the newest version again.

Only one run per app at a time, and each is stopped after 30 minutes. The log is at
`active-setup/sites/<app>/.auto-update/update.log`.

## Your data

These apps keep diagrams in the browser (IndexedDB and localStorage) under the
site's domain. So:

- **Keep the domain to keep the data.** If you change an app's domain, the browser
  shows it as empty. Moving it back brings the data back.
- **Uninstalling** removes the build, but the data stays in the browser. Reinstall
  on the same domain to get it back.
- **Back up** with each app's own export: ChartDB and drawDB export to JSON or SQL,
  Excalidraw saves `.excalidraw` files, and Mermaid copies the diagram text.
  Clearing site data in the browser deletes the data.

## Adding an app

Create `apps/<app>.sh`:

```bash
TITLE="Name"                       # shown in the wizard
ABOUT="One line"
REPO_URL=https://github.com/o/r.git
DOMAIN=name                        # default domain, .test is added
SOURCE=tags                        # or a branch name
STORAGE=src/db/                    # paths whose change may alter stored data ("" = none)
NODE=22                            # optional; only if the repo's .nvmrc is wrong
ROOT_REDIRECT=/editor              # optional; where / redirects
build() {                          # runs in src/; build into "$1"
    npm ci --ignore-scripts --no-audit --no-fund
    npx vite build --outDir "$1"
}
```

The `pm` helper runs the package manager set in `package.json`'s `packageManager`
field (yarn or pnpm). Use it in place of corepack, which Node 25 and newer no longer
include.

The driver serves the files in `dist`. For any route without a file extension it
serves `<route>.html` if the build has that file, otherwise `404.html` (SvelteKit's
fallback page) if it has one, and `index.html` otherwise. A missing file under
`/assets/` or `/_app/`, or any missing path with an extension, gets a real 404.

Only static single-page apps are supported for now. Apps that run their own server,
such as n8n under PM2, are next.
