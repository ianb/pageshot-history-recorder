#!/usr/bin/env bash

set -e

help() {
  echo "Usage: $(basename $0) PROFILE_DIR"
  echo "  Reads the places information out of PROFILE_DIR and prints it out as JSON"
}

profile_dir="$1"

if [ ! -d "$profile_dir" ] ; then
  echo "Error: no PROFILE_DIR ($profile_dir)"
  help
  exit 2
fi

sql='
SELECT
  fh.title AS from_title,
  fh.url AS from_url,
  th.title,
  th.url,
  v.visit_date,
  fh.visit_count,
  fh.frecency
FROM moz_historyvisits AS v
LEFT JOIN moz_historyvisits AS fv
          ON fv.id = v.from_visit
LEFT JOIN moz_places AS fh
          ON fh.id = fv.place_id
JOIN moz_places AS th
     ON th.id = v.place_id
ORDER BY v.visit_date DESC;
'

sqlite3 -csv $profile_dir/places.sqlite "$sql" | python -c '
import sys
import csv
import json

pages = {}
for line in csv.reader(sys.stdin):
    (from_title, from_url, title, url, visit_date, visit_count, frecency) = line
    visit_date = int(visit_date or "0")
    frecency = int(frecency or "0")
    visit_count = int(visit_count or "0")
    if not pages.get(url):
        pages[url] = {
          "url": url,
          "title": title,
          "visit_count": visit_count,
          "frecency": frecency,
          "from": {},
          "last_visited": 0
        }
    if not pages[url]["from"].get(from_url):
        pages[url]["from"][from_url] = {"title": from_title, "visit_dates": []}
    pages[url]["from"][from_url]["visit_dates"].append(visit_date)
    if pages[url]["last_visited"] < visit_date:
        pages[url]["last_visited"] = visit_date

pages = sorted(pages.values(), key=lambda a: -a["last_visited"])
sys.stdout.write(json.dumps(pages, indent=2))
'
