#!/usr/bin/env bash

set -e

output="$1"

help() {
  echo "Usage: $(basename $0) OUTPUT_DIR"
  echo "  Goes through all files in OUTPUT_DIR and updates PageShot data if it is missing"
  echo "  Use: RETRY_TIMED_OUT=1 $(basename $0) OUTPUT_DIR"
  echo "       to retry previously-timed-out items"
}

if [ -z "$output" ] ; then
  echo "Error: must give OUTPUT_DIR"
  help
  exit 2
fi

if [ ! -d "$output" ] ; then
  if [ -e "$output" ] ; then
    echo "Error: OUTPUT_DIR ($output) is not a directory"
    help
    exit 2
  fi
  echo "Error: OUTPUT_DIR ($output) doesn't exist"
  help
  exit 2
fi

for filename in $output/* ; do
  python -c '
import sys
import json
import urllib
import os
import time

filename = sys.argv[1]
with open(filename) as fp:
    data = json.load(fp)
url = data["url"]
if not os.environ.get("RETRY_TIMED_OUT") and data.get("pageshot_timeout"):
    print("Skipping %s %s" % (os.path.basename(filename), url))
elif not data.get("pageshot"):
    fetch_url = "http://localhost:10082/data/?url=%s&allowUnknownAttributes=true&delayAfterLoad=1000" % urllib.quote(url)
    print("Updating %s %s\n  (fetching %s)" % (os.path.basename(filename), url, fetch_url))
    start = time.time()
    pageshot_data = urllib.urlopen(fetch_url)
    code = pageshot_data.getcode()
    if code == 502:
        data["pageshot_timeout"] = True
        with open(filename, "w") as fp:
            fp.write(json.dumps(data, indent=2))
        print("  failed/timeout after %0.1fs" % (time.time() - start))
    elif pageshot_data.getcode() != 200:
        print("  failed with code: %s (after %0.1fs)" % (pageshot_data.getcode(), time.time() - start))
    else:
        pageshot_data = pageshot_data.read()
        pageshot_data = pageshot_data.decode("UTF-8")
        pageshot_data = json.loads(pageshot_data)
        data["pageshot"] = pageshot_data
        if data.get("pageshot_timeout"):
            del data["pageshot_timeout"]
        with open(filename, "w") as fp:
            fp.write(json.dumps(data, indent=2))
        print("  done in %0.1fs" % (time.time() - start))
  ' "$filename"
done
