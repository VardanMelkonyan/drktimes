#!/usr/bin/env bash
set -euo pipefail

id="${1:?usage: tool/fetch_source.sh <source-id>}"
root="$(cd "$(dirname "$0")/.." && pwd)"
data="$root/resources/devdata"
cache="$data/.cache"

url="$(python3 -c '
import json, sys
for s in json.load(open(sys.argv[1]))["sources"]:
    if s["id"] == sys.argv[2]:
        print(s.get("url") or ""); break
' "$data/sources.json" "$id")"
[ -n "$url" ] || { echo "unknown source id or no url: $id" >&2; exit 1; }

mkdir -p "$cache/$id"
pdf="$cache/$id.pdf"
curl -sSL --fail --max-time 60 \
  -A "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0" \
  -H "Accept: application/pdf,*/*" -o "$pdf" "$url"
file "$pdf" | grep -q "PDF document" || { echo "not a PDF: $url (handle manually)" >&2; exit 1; }

pages="$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')"
for p in $(seq 1 "$pages"); do
  pdftotext -layout -f "$p" -l "$p" "$pdf" "$cache/$id/page-$p.txt"
done

sha="$(sha256sum "$pdf" | cut -d' ' -f1)"
echo "pages: $pages -> $cache/$id/page-N.txt"
echo "\"retrieved\": \"$(date +%F)\", \"sha256\": \"$sha\""
