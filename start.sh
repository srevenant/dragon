#!/bin/bash
(cd site/_build && http-server -p 1234) &
PIDS="$!"
#(mix build && onchange "user/**" -e "user/.dragon/build" -- mix build '{{file}}') &
(mix build site && onchange "site/**" -e "site/_build" -- mix build site) &
PIDS="$PIDS $!"
echo "PIDS=$PIDS"
trap "kill $PIDS; exit 0" 0 15
for pid in $PIDS; do
  wait $pid
done
