#!/bin/bash
# idle-exit.sh <seconds> <dir> "<ports>" <command...>: runs the command under PM2 and
# stops it once, for <seconds>, nothing has been connected to any of the ports and
# nothing in <dir> has changed. It then exits 0, which the app's PM2 definition treats
# as a stop (stop_exit_codes), not a crash. synk-mac-apps copies it to ~/.synk-mac-apps.
# It looks every 30 seconds, so a shorter connection (one SMTP message) counts through
# the change it makes in <dir>. Time the Mac spends asleep counts as quiet.
idle=$1 dir=$2 ports=$3
shift 3
lsof_ports=()
for p in $ports; do lsof_ports+=(-iTCP:"$p"); done
mark=$(mktemp -t idle-exit)
"$@" &
child=$!
trap 'kill "$child" 2>/dev/null; wait "$child"; rm -f "$mark" "$mark.new"; exit 0' INT TERM

last=$(date +%s)
while kill -0 "$child" 2>/dev/null; do
    sleep 30 & wait $!
    touch "$mark.new"
    if [ -n "$(find "$dir" -newer "$mark" -print -quit 2>/dev/null)" ] ||
        lsof -nP "${lsof_ports[@]}" -sTCP:ESTABLISHED >/dev/null 2>&1; then
        last=$(date +%s)
    fi
    mv -f "$mark.new" "$mark"
    [ $(($(date +%s) - last)) -lt "$idle" ] && continue
    echo "$(date '+%F %T') idle-exit: nothing for $((idle / 60)) minutes; stopping"
    kill "$child"; wait "$child"; rm -f "$mark"; exit 0
done
# The app ended by itself: pass its exit code on, so PM2 restarts it after a crash.
wait "$child"; rc=$?
rm -f "$mark"
exit $rc
