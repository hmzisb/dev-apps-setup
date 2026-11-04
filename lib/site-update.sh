#!/bin/bash
# Builds and deploys the newest version of one installed app:
#   lib/site-update.sh <app>
# Started weekly in the background by LocalValetDriver.php when the site is opened,
# and by synk-mac-apps for installs and --update. The app's manifest (apps/<app>.sh)
# sets SOURCE, STORAGE, NODE and build(); see README.md.
# Each version builds into builds/<version> and dist is a symlink swapped atomically,
# so the site never goes down and a failed update leaves the old build live.
# Manual rollback: ln -sfn builds/<older version> dist.tmp && mv -fh dist.tmp dist
# -E: the ERR trap must also fire inside build().
set -Eeuo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
APP=${1:?usage: site-update.sh <app>}

SITE="$REPO/active-setup/sites/$APP"
STATE="$SITE/.auto-update"

# One run per app, capped at 30 minutes. perl holds an flock on update.lock (the
# kernel drops it when perl exits, so a lock is never stale), runs the update in its
# own process group, and on timeout kills the whole group, a hung npm or git included.
if [ -z "${CAPPED:-}" ]; then
    [ -d "$SITE" ] || { echo "site-update.sh: $APP is not installed" >&2; exit 1; }
    mkdir -p "$STATE"
    CAPPED=1 exec /usr/bin/perl -MFcntl=:flock -MPOSIX=strftime -e '
        my ($state, @cmd) = @ARGV;
        open(my $lock, ">>", "$state/update.lock") or die "lock: $!";
        unless (flock($lock, LOCK_EX | LOCK_NB)) {
            open(my $log, ">>", "$state/update.log");
            print $log strftime("%F %T", localtime), " another update is running\n";
            exit 75;
        }
        my $pid = fork() // die "fork: $!";
        if (!$pid) { setpgrp(0, 0); exec(@cmd) or die "exec: $!" }
        $SIG{ALRM} = sub { kill("TERM", -$pid); sleep 10; kill("KILL", -$pid) };
        alarm 1800;
        waitpid($pid, 0);
        exit($? & 127 ? 1 : $? >> 8);
    ' "$STATE" /bin/bash "$REPO/lib/site-update.sh" "$@"
fi

source "$REPO/apps/$APP.sh"
cd "$SITE"

log() { echo "$(date '+%F %T') $*"; }
retry_tomorrow() { touch -t "$(date -v-6d +%Y%m%d%H%M)" "$STATE/last-check"; }
fail_run() { log "FAILED: $*, retrying tomorrow"; retry_tomorrow; exit 1; }
trap 'fail_run "error at line $LINENO"' ERR
trap 'fail_run "timed out after 30 minutes"' TERM

if [ -f "$STATE/update.log" ]; then
    tail -n 2000 "$STATE/update.log" > "$STATE/update.log.tmp"
    mv "$STATE/update.log.tmp" "$STATE/update.log"
fi
# Everything, git and build errors included, goes to the (rotated) log.
exec >> "$STATE/update.log" 2>&1

# PHP-FPM starts this with an empty environment.
export HOME="${HOME:-$(echo ~)}" PATH=/usr/bin:/bin:/usr/sbin:/sbin
export GIT_TERMINAL_PROMPT=0 GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=60
# Keep husky from pointing the checkout's git hooks at its own scripts.
export HUSKY=0

# Node from NODE, else the checked-out version's .nvmrc (installed if missing), else
# the latest LTS. Herd's own default is left alone. nvm's internals return non-zero
# routinely, so errexit and the ERR trap are off while it runs.
use_node() {
    trap - ERR; set +eu
    source "$HOME/Library/Application Support/Herd/config/nvm/nvm.sh" --no-use
    # Bare "nvm install" without an .nvmrc would pick the newest build, even an alpha.
    if [ -n "${NODE:-}" ]; then nvm install "$NODE" --no-progress >/dev/null 2>&1
    elif [ -f .nvmrc ]; then nvm install --no-progress >/dev/null 2>&1
    else nvm install --lts --no-progress >/dev/null 2>&1; fi
    set -eu; trap 'fail_run "error at line $LINENO"' ERR
}

# Runs the package manager pinned in package.json's packageManager (yarn, pnpm),
# without corepack, which Node 25+ no longer ships.
pm() { npx -y "$(node -p 'require("./package.json").packageManager.split("+")[0]')" "$@"; }

# The deployed version is whatever dist points at ("none" before the first build or
# when its build is gone),
# never the git checkout, so an interrupted run can't make the old build look current.
deployed=none
[ -f dist/index.html ] && deployed=$(basename "$(readlink dist)")
date '+%F %T' > "$STATE/last-check"

if [ "$SOURCE" = tags ]; then
    latest=$(git -C src ls-remote --tags --refs origin \
        | sed -n 's#.*refs/tags/\(v[0-9]*\.[0-9]*\.[0-9]*\)$#\1#p' | sort -V | tail -1) || latest=
else
    sha=$(git -C src ls-remote origin "refs/heads/$SOURCE" | cut -f1) || sha=
    latest=${sha:0:12}
fi
[ -n "$latest" ] || fail_run "could not reach GitHub or found no release"
# Tags: stable releases only (the regex drops -rc/-beta), and never a downgrade.
# Branch: any new commit.
if [ "$latest" = "$deployed" ] || { [ "$SOURCE" = tags ] && [ "$deployed" != none ] &&
    [ "$(printf '%s\n' "$deployed" "$latest" | sort -V | tail -1)" = "$deployed" ]; }; then
    log "up to date at $deployed"
    exit 0
fi

log "updating $deployed -> $latest"
out="builds/$latest"
rm -rf "$out" && mkdir -p builds
if [ "$SOURCE" = tags ]; then
    git -C src fetch -q --depth 1 origin tag "$latest"
    git -C src checkout -q "$latest"
else
    git -C src fetch -q --depth 1 origin "$SOURCE"
    git -C src checkout -q FETCH_HEAD
fi
if [ -n "$STORAGE" ]; then
    # Exit 1 means the files differ; 128 (old version not fetched locally) means unknown, so stay quiet.
    rc=0; git -C src diff --quiet "$deployed" HEAD -- $STORAGE 2>/dev/null || rc=$?
    if [ "$rc" = 1 ]; then
        log "note: $latest may upgrade the browser storage schema; rolling back to $deployed afterwards may not open your data"
    fi
fi
cd src
use_node
log "building with node $(node -v)"
build "$SITE/$out"
cd "$SITE"

[ -f "$out/index.html" ] || fail_run "$latest build has no index.html"
# Herd require()s the .html pages as PHP (short_open_tag is on), so "<?" would break them.
if grep -rlq --include='*.html' '<?' "$out"; then fail_run "$latest has '<?' in an .html page"; fi

# Tabs opened before the swap lazy-load files by their old hashed names; carry the
# previous build's own files (listed in its .files) forward one release.
(cd "$out" && find . -type f ! -name .files) > "$out/.files"
if [ -f dist/.files ]; then
    while IFS= read -r f; do
        [ -e "$out/$f" ] || { mkdir -p "$(dirname "$out/$f")" && cp "dist/$f" "$out/$f"; }
    done < dist/.files
fi

ln -sfn "$out" dist.tmp
mv -fh dist.tmp dist
echo "$latest $(date '+%F %T')" > "$STATE/last-updated"

# Keep the live build and the previous one for rollback; drop older or failed ones.
for d in builds/*; do
    [ "$d" = "$out" ] || [ "$d" = "builds/$deployed" ] || rm -rf "$d"
done
log "updated to $latest"
