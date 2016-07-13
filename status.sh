#!/usr/bin/env bash

output="$1"

help() {
  echo "Usage: $(basename $0) DIRECTORY"
  echo "  Tells how many records in DIRECTORY need processing, have failed, or are saved"
}

if [ -z "$output" ] || [ ! -d "$output" ] ; then
  echo "Error: DIRECTORY ($output) does not exist"
  help
  exit
fi

python -c '
import os
import json
import sys

dir = sys.argv[1]

total = 0
done = 0
timeout = 0

for filename in os.listdir(dir):
    with open(os.path.join(dir, filename)) as fp:
        data = json.load(fp)
    total += 1
    if data.get("pageshot_timeout"):
        timeout += 1
    elif data.get("pageshot"):
        done += 1
print("Total: %s\nDone: %s (%s left)\nTimed out: %s" % (total, done, total - done - timeout, timeout))
' "$output"
