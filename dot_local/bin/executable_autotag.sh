#!/usr/bin/env bash
#
# autotag.sh — LLM-assisted tag scanning for a zk notebook.
#
# Scans changed notes (or explicit files) with the Jev classifier (TypeSafe
# System One API) and adds existing-vocabulary tags to the YAML frontmatter. Non-destructive by default: it only
# ever adds tags (union with existing), never removes.
#
# Usage:
#   autotag.sh                 # tag notes changed since last git commit
#   autotag.sh a.md b.md       # tag specific files
#   DRY_RUN=1 autotag.sh       # print proposed diffs, write nothing
#   autotag.sh --all           # scan every tracked .md note
#
# Deps: yq (mikefarah), jq, git, curl, zk

set -euo pipefail

# cron has a minimal PATH; ensure Homebrew binaries are reachable.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

NOTEBOOK_DIR="${ZK_NOTEBOOK_DIR:-$HOME/notes}"
API_URL="${AUTOTAG_API_URL:-https://api.typesafe.ai/v1/systemone}"
THRESHOLD="${AUTOTAG_THRESHOLD:-0.9}"
CHUNK="${AUTOTAG_CHUNK:-40}"
DRY_RUN="${DRY_RUN:-0}"
MAX_TAGS="${AUTOTAG_MAX_TAGS:-3}"
BODY_CHARS="${AUTOTAG_BODY_CHARS:-3000}"
REQ_TIMEOUT="${AUTOTAG_REQ_TIMEOUT:-60}"
CACHE_FILE="$NOTEBOOK_DIR/.zk/autotag-cache.tsv"
KILL_SWITCH="$NOTEBOOK_DIR/.zk/autotag.off"

log() { printf '[autotag] %s\n' "$*" >&2; }

for bin in yq jq git curl zk; do
  command -v "$bin" >/dev/null 2>&1 || { log "missing dependency: $bin"; exit 1; }
done

cd "$NOTEBOOK_DIR"
[ -e "$KILL_SWITCH" ] && { log "kill switch present ($KILL_SWITCH); exiting"; exit 0; }

# ---- collect target notes -------------------------------------------------
is_excluded() {
  case "$1" in
    audio/*|.zk/*|.git/*) return 0 ;;
    *.md) return 1 ;;
    *) return 0 ;;
  esac
}

declare -a TARGETS=()
if [ "${1:-}" = "--all" ]; then
  while IFS= read -r f; do is_excluded "$f" || TARGETS+=("$f"); done < <(git ls-files '*.md')
elif [ "$#" -gt 0 ]; then
  for f in "$@"; do is_excluded "$f" || TARGETS+=("$f"); done
else
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    is_excluded "$f" || TARGETS+=("$f")
  done < <(git status --porcelain -- '*.md' | awk '{print $2}')
fi

[ "${#TARGETS[@]}" -eq 0 ] && { log "no notes to process"; exit 0; }
log "candidate notes: ${#TARGETS[@]}"

# ---- reference data: note ids + stopwords (used for sanitisation/filters) --
NOTE_IDS_JSON="$(git ls-files '*.md' | sed 's#.*/##; s#\.md$##' | jq -R . | jq -sc 'unique')"
STOPWORDS_JSON='["notes","note","untitled","misc","general","todo","stuff","things","info","various"]'

# ---- existing tag vocabulary (sanitised, with usage counts) ---------------
# Drop junk that leaked into the vocab (dates, note-ids, stopwords) so we
# neither show it to the model nor allow it as a "reuse" choice.
VOCAB_OBJ="$(zk tag list --format '{{name}}|{{note-count}}' 2>/dev/null \
  | jq -R 'split("|") | {name: .[0], count: ((.[1]//"0")|tonumber? // 0)}' \
  | jq -s --argjson ids "$NOTE_IDS_JSON" --argjson stop "$STOPWORDS_JSON" '
      [ .[]
        | select(.name
            | (test("[0-9]{4}")|not)
              and (. as $n | ($stop|index($n))|not)
              and (. as $n | ($ids|index($n))|not)
              and test("^[a-z0-9][a-z0-9-]*$")) ]
      | sort_by(-.count)')"
VOCAB_JSON="$(printf '%s' "$VOCAB_OBJ" | jq -c '[.[].name]')"
VOCAB_DISPLAY="$(printf '%s' "$VOCAB_OBJ" | jq -r 'map("\(.name) (\(.count))") | join(", ")')"

# ---- classifier access -----------------------------------------------------
if [ -z "${TYPESAFE_API_KEY:-}" ]; then
  TYPESAFE_API_KEY="$(op read --account teamgigs.1password.com 'op://Employee/5do4vcoy6kauirafesgb5m6qhy/credential' 2>/dev/null || true)"
fi
[ -n "$TYPESAFE_API_KEY" ] || { log "no TYPESAFE_API_KEY and 1Password lookup failed"; exit 1; }

# One bool question per vocabulary tag, chunked to keep requests small.
QUESTIONS_CHUNKS="$(printf '%s' "$VOCAB_JSON" | jq -c --argjson size "$CHUNK" '
  map({key: ., value: {type: "noul",
        instructions: "Is \"\(.)\" a clearly central theme of the note, i.e. would a reader looking for \"\(.)\" want to find it?",
        criteria: {true: "The note is substantially about \(.)", false: "Not a central theme of the note"}}})
  | [range(0; length; $size) as $i | .[$i:$i+$size] | from_entries]')"

classify_note() { # stdin: state JSON -> stdout: JSON object {tag: probability}
  local state; state="$(cat)"
  printf '%s' "$QUESTIONS_CHUNKS" | jq -c '.[]' | while IFS= read -r qs; do
    jq -nc --argjson state "$state" --argjson q "$qs" '{model:"jev-latest", state:$state, questions:$q}' \
      | curl -s --max-time "$REQ_TIMEOUT" "$API_URL" \
          -H "Authorization: Bearer $TYPESAFE_API_KEY" -H 'Content-Type: application/json' -d @- \
      | jq -c '.answers // error("no answers") | map_values(.noul)'
  done | jq -sc 'add // {}'
}

# ---- helpers --------------------------------------------------------------
frontmatter_tags() { yq --front-matter=extract -o=json '.tags // []' "$1" 2>/dev/null || echo '[]'; }
note_title()       { yq --front-matter=extract -o=json '.title // ""' "$1" 2>/dev/null | jq -r . 2>/dev/null || true; }
has_frontmatter()  { head -1 "$1" | grep -qx -- '---'; }
strip_frontmatter() {
  awk 'NR==1 && $0=="---"{fm=1;next} fm==1 && $0=="---"{fm=2;next} fm!=1{print}' "$1"
}
normalize() { # stdin JSON array -> normalized, order-preserving unique array
  jq -c '[ .[] | ascii_downcase | gsub("^\\s+|\\s+$";"") | gsub("\\s+";"-") ]
         | map(select(test("^[a-z0-9-]+$")))
         | reduce .[] as $x ([]; if index($x) then . else . + [$x] end)'
}

cache_hash() { grep -F "$1"$'\t' "$CACHE_FILE" 2>/dev/null | tail -1 | cut -f2; }
cache_put()  {
  local tmp; tmp="$(mktemp)"
  { grep -vF "$1"$'\t' "$CACHE_FILE" 2>/dev/null || true; printf '%s\t%s\n' "$1" "$2"; } >"$tmp"
  mv "$tmp" "$CACHE_FILE"
}
touch "$CACHE_FILE"

changed=0
for f in "${TARGETS[@]}"; do
  stripped="$(strip_frontmatter "$f")"
  # skip thin/low-signal notes rather than inventing tags for them
  [ "$(printf '%s' "$stripped" | tr -d '[:space:]' | wc -c | tr -d ' ')" -lt 200 ] \
    && { log "skip (thin): $f"; continue; }

  h="$(printf '%s' "$stripped" | shasum -a 256 | cut -d' ' -f1)"
  [ "$(cache_hash "$f")" = "$h" ] && continue  # body unchanged since last tagging

  cur="$(frontmatter_tags "$f")"
  title="$(note_title "$f")"
  headings="$(printf '%s\n' "$stripped" | grep -E '^#{1,6} ' | sed 's/^#\{1,6\} *//' | head -20 | paste -sd '; ' - || true)"
  bodycap="$(printf '%s' "$stripped" | head -c "$BODY_CHARS")"

  state="$(jq -nc --arg title "$title" --arg headings "$headings" --arg note "$bodycap" --argjson tags "$cur" \
          '{title:$title, headings:$headings, current_tags:$tags, note:$note}')"

  if ! probs="$(printf '%s' "$state" | classify_note 2>/dev/null)" || [ "$probs" = "{}" ]; then
    log "skip (no valid classifier output): $f"
    continue
  fi

  reuse="$(jq -cn --argjson p "$probs" --argjson cur "$cur" --argjson t "$THRESHOLD" --argjson n "$MAX_TAGS" '
    [ $p | to_entries[] | select(.value >= $t) | select(.key as $k | $cur | index($k) | not) ]
    | sort_by(-.value) | .[:$n] | map(.key)')"
  newcap='[]'

  merged="$(jq -cn --argjson a "$cur" --argjson r "$reuse" --argjson c "$newcap" '($a + $r + $c) | unique')"
  added="$(jq -cn --argjson a "$cur" --argjson b "$merged" '$b - $a')"

  if [ "$(printf '%s' "$added" | jq 'length')" -eq 0 ]; then
    cache_put "$f" "$h"
    continue
  fi

  addcsv="$(printf '%s' "$added" | jq -r 'join(", ")')"
  curcsv="$(printf '%s' "$cur" | jq -r 'join(", ")')"
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY $f : [$curcsv] +[$addcsv]"
    continue
  fi

  tmp="$(mktemp)"
  if has_frontmatter "$f"; then
    # yq -i is broken with front-matter mode; redirect + atomic move instead
    MERGED="$merged" yq --front-matter=process \
      '.tags = (strenv(MERGED) | fromjson) | .tags style="flow" | .tags[] style=""' "$f" >"$tmp"
    mv "$tmp" "$f"
  else
    { printf -- '---\ntags: %s\n---\n\n' "$merged"; cat "$f"; } >"$tmp"
    mv "$tmp" "$f"
  fi
  cache_put "$f" "$h"
  changed=$((changed+1))
  log "TAGGED $f : +[$addcsv]"
done

log "done; notes updated: $changed"
