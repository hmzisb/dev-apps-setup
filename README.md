# 🧰 Dev Apps Setup

**Run useful developer tools on your Mac.**

Set up diagram editors, database design tools, workflow automation and a local email inbox.
[Laravel Herd](https://herd.laravel.com) gives each app an address such as `https://draw.test`.

- 📦 **Choose your apps:** Excalidraw, Mermaid, drawDB, ChartDB, draw.io, JSON Crack, n8n and Mailpit.
- 🧭 **Follow one setup wizard:** install prerequisites and choose local addresses.
- 🔄 **Manage them together:** install, check, update or remove apps with one command.

Uses macOS and Laravel Herd. Docker is not required.
On a new Mac, finish Herd's first-run setup and enable Node when prompted.

[![lint](https://github.com/hmzisb/dev-apps-setup/actions/workflows/lint.yml/badge.svg)](https://github.com/hmzisb/dev-apps-setup/actions/workflows/lint.yml)
[![License: CC0-1.0](https://img.shields.io/badge/license-CC0--1.0-blue.svg)](LICENSE)
![macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Bash 3.2](https://img.shields.io/badge/bash-3.2-4EAA25.svg)

```bash
git clone https://github.com/hmzisb/dev-apps-setup.git ~/dev-apps-setup
~/dev-apps-setup/synk-mac-apps --setup
```

## 💡 Why use it?

Keep setup steps in one place so you can repeat them when an app changes or you move to a new Mac.

- **Stable addresses:** each app keeps a bookmarkable local address. Browser data remains tied to the same domain and browser profile.
- **Different update methods:** static apps check for updates on a visit after seven days. Update n8n and Mailpit with `synk-mac-apps --update <app>`.
- **Local hosting:** the tools run on your Mac. Sharing features and connected services may still use the internet; see [Your data](#-your-data).
- **Repeatable setup:** run the wizard again to manage or repair an installation.

## 📦 Apps

| App | Default URL | What it's for | Upstream license |
|---|---|---|---|
| [ChartDB](https://github.com/chartdb/chartdb) | `https://chartdb.test` | Database schema diagrams from a SQL query | AGPL-3.0 |
| [draw.io](https://github.com/jgraph/drawio) | `https://drawio.test` | Flowcharts, UML, network and other diagrams | Apache-2.0 |
| [drawDB](https://github.com/drawdb-io/drawdb) | `https://drawdb.test` | Drag-and-drop database diagrams | AGPL-3.0 |
| [Excalidraw](https://github.com/excalidraw/excalidraw) | `https://draw.test` | Hand-drawn style whiteboard | MIT |
| [JSON Crack](https://github.com/AykutSarac/jsoncrack.com) | `https://jsoncrack.test` | JSON, YAML, CSV and XML as interactive graphs | Apache-2.0 |
| [Mailpit](https://github.com/axllent/mailpit) | `https://mailpit.test` | Catches mail from local apps (a server, see below) | MIT |
| [Mermaid Live Editor](https://github.com/mermaid-js/mermaid-live-editor) | `https://flow.test` | Diagrams from text | MIT |
| [n8n](https://github.com/n8n-io/n8n) | `https://n8n.test` | Workflow automation (a server, see below) | [Sustainable Use](https://docs.n8n.io/sustainable-use-license/) |

You pick which apps to install and choose each domain during setup. This repo has
no copy of their code. Static apps are built from their upstream repositories;
n8n installs from npm, and Mailpit uses an official release binary.

## 🚀 Getting started

**You need:** macOS (Apple Silicon or Intel) and an internet connection for builds.
The setup installs everything else after asking you first:

1. [Homebrew](https://brew.sh), [gum](https://github.com/charmbracelet/gum) (for the
   menus) and git.
2. Laravel Herd (free). Finish its first-run window, then turn on Node in
   **Herd > Settings > Node**.
3. The `synk-mac-apps` command, linked into Homebrew's `bin`.
4. Each app. For every app it asks whether to install it and on which domain.

You can clone the repo anywhere. The command finds its own folder.

## 🧰 Commands

```
synk-mac-apps --setup                          wizard: prerequisites, then add, move, update or remove apps
synk-mac-apps --status                         versions, last update, last check, HTTP status
synk-mac-apps --doctor                         check everything; exits 1 on a problem
synk-mac-apps --update [app|all]               check for and build new versions now
synk-mac-apps --install [app] [--domain name]  install, move or repair an app
synk-mac-apps --uninstall [app] [-y]           remove an app
synk-mac-apps --list                           apps this repo knows about
```

Examples:

```bash
synk-mac-apps --install excalidraw --domain whiteboard   # https://whiteboard.test
synk-mac-apps --update chartdb
synk-mac-apps --uninstall drawdb -y
```

## ⚙️ How it works

The following update process applies to static apps. n8n and Mailpit use the
separate server setup described below.

```mermaid
flowchart LR
    A[apps/*.sh<br>one manifest per app] --> B[synk-mac-apps]
    B -->|git clone + build| C[active-setup/sites/app/builds/version]
    C -->|dist symlink| D[Herd driver]
    D --> E[https://name.test]
    E -.->|first visit after 7 days| F[lib/site-update.sh]
    F -->|new build, atomic swap| C
```

1. **Check.** The first page load after 7 days starts `lib/site-update.sh` in the
   background. It asks GitHub for the newest stable `vX.Y.Z` tag, or the newest
   commit on a branch.
2. **Build.** It builds that version into `builds/<version>` using the Node version
   the app needs, through Herd's nvm.
3. **Validate.** It rejects a build that has no `index.html`.
4. **Swap.** It points `dist` at the new build in one atomic step. Files from the
   previous build are carried over, so tabs that are already open keep working.
5. **Recover.** A failed or stuck run (30 minute limit) leaves the old build live
   and tries again the next day. Only one run per app happens at a time.

Each app's log is at `active-setup/sites/<app>/.auto-update/update.log`.

### Server apps (n8n, Mailpit)

n8n and Mailpit are servers, not sets of files, so they work differently:

- **Install.** n8n comes from npm and runs on Node 24 from Herd's nvm; Mailpit is one
  binary from its GitHub releases. Both go into `~/.synk-mac-apps/sites/<app>` and
  run under a PM2 of their own, separate from any PM2 you already use. Herd forwards
  `https://n8n.test` to port 5678 and `https://mailpit.test` to port 8025.
- **When they run.** A LaunchAgent starts them when Herd starts. Nothing starts them
  at boot: after a restart they come back only when Herd opens (right away if Herd
  opens at login). Quitting Herd doesn't stop them.
  - Each one stops itself after an idle hour and starts again the next time Herd
    starts. To start one sooner, run `synk-mac-apps --install <app>`.
  - **n8n** is idle with no editor tab open, no webhook call and no workflow run.
    While it is stopped, schedule triggers don't fire and webhooks get 502.
  - **Mailpit** is idle with no new mail and no inbox tab open. While it is stopped,
    apps that send mail get "connection refused".
- **Updates.** Only when you run `synk-mac-apps --update <app>`. A new version may
  change its database, so the update first saves a copy of it
  (`<database>.before-<version>`), keeps the previous version, and restarts the app.
- **Logs.** `~/.synk-mac-apps/sites/<app>/logs/<app>.log`, and
  `~/.synk-mac-apps/herd-start.log` for each start that Herd triggers.

To send your apps' mail to Mailpit, point them at SMTP `127.0.0.1:1025`. In Laravel's
`.env`: `MAIL_MAILER=smtp`, `MAIL_HOST=127.0.0.1`, `MAIL_PORT=1025`.

It lives in `~/.synk-mac-apps` rather than `active-setup/` because macOS blocks
background jobs from reading Desktop, Documents and Downloads, where you may have
cloned this repo.

<details>
<summary><b>Roll back to the previous version</b></summary>

The live build and the previous one are kept. Inside the app's site folder:

```bash
ln -sfn builds/<old-version> dist.tmp && mv -fh dist.tmp dist
```

The rollback lasts until the next check (a week, or `--update`), which builds the
newest version again.
</details>

## 💾 Your data

Most static apps save work in the browser, separately for each domain. Storage
varies by app; see the exceptions below. n8n and Mailpit keep their data on disk.

- **Keep the domain to keep your data.** After a domain change the app looks empty.
  Moving back to the old domain brings the data back.
- **Uninstalling** removes the build but not your data. Reinstall on the same domain
  to get it back.
- **Back up** with each app's export: ChartDB and drawDB export JSON or SQL,
  Excalidraw saves `.excalidraw` files, and in Mermaid you copy the diagram text.
  Clearing the browser's site data deletes your work.

Excalidraw's share links, libraries and live collaboration still use excalidraw.com's
free services. Its tracking and error reporting are turned off.
**draw.io** saves each diagram as a `.drawio` file on your Mac or in the browser,
whichever you pick when you save. Its Google Drive, OneDrive and similar logins and
its server-side export need draw.io's Java servlets, which aren't installed, so
PDF export goes through the print dialog.
**JSON Crack** keeps what you paste only for the current tab (sessionStorage), so
save anything you need with **File > Export**. Its text editor downloads its code
from unpkg.com, but your data stays in the browser.

**n8n** keeps its workflows, credentials and the key that encrypts them in
`~/.synk-mac-apps/data/n8n/.n8n`, not in the browser. Uninstalling keeps that folder,
and a reinstall picks it up again. Back it up by copying the folder while n8n is
stopped, or with n8n's own export. Its telemetry and update checks are off.
**Mailpit** keeps caught mail (the newest 500) in `~/.synk-mac-apps/data/mailpit`.

## 🗂️ Layout

```
synk-mac-apps              the CLI
apps/<app>.sh              one manifest per app: what to clone, how to build it
lib/site-update.sh         builds and deploys a new version of one app
lib/LocalValetDriver.php   Herd driver shared by every app
lib/idle-exit.sh           stops an idle server app
active-setup/              git-ignored; everything generated lives here
  sites/<app>/
    src/                   git clone of the app
    builds/<version>/      the live build and the previous one
    dist -> builds/...     what Herd serves
    domain                 the installed domain (without .test)
    .auto-update/          update.log, last-check, last-updated
~/.synk-mac-apps/          server apps (n8n, Mailpit), outside the repo
  sites/<app>/             builds/<version>, current -> builds/..., ecosystem.json, logs/
  data/<app>/              the app's data; an uninstall keeps it
  pm2/                     PM2's own home, separate from ~/.pm2
  idle-exit.sh             stops an app with IDLE set after that many quiet seconds
  herd-start.sh            run by ~/Library/LaunchAgents/com.synk-mac-apps.pm2.plist
```

## 🤝 Contributing

To add an app, write one short manifest file. [CONTRIBUTING.md](CONTRIBUTING.md)
explains how, both for static single-page apps and for servers that run under PM2.

Report a security problem privately, as described in [SECURITY.md](SECURITY.md).

## ⚖️ License

[CC0-1.0](LICENSE): this repo's own scripts and docs are in the public domain, so you
can use them for anything. Each app keeps its own upstream license (see the table).
This repo never redistributes their code; it builds them on your machine.
