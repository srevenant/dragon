#!/bin/bash
target=$1

if [ -z "$target" ]; then
    echo "Syntax: {target-folder}"
    exit 1
fi

(cd ${target}/_build && http-server -p 1234) &
PIDS="$!"
(mix dragon.build ${target} && onchange "${target}/**" -e "${target}/_build" -- mix dragon.build ${target}) &
PIDS="$PIDS $!"
echo "PIDS=$PIDS"
trap "kill $PIDS; exit 0" 0 15
for pid in $PIDS; do
  wait $pid
done
