#!/usr/bin/env bash
# Records every speech part with macOS voices into assets/audio/.
#
# PROTOTYPE ONLY: macOS system voices are licensed for personal,
# non-commercial use. Replace this step with a text-to-speech service whose
# license allows distribution before publishing the app.
#
# Usage: tool/generate_speech.sh
# Optional: EN_VOICE="Ava (Premium)" ES_VOICE="Paulina (Enhanced)" EN_RATE=165 ES_RATE=160 JOBS=8
set -euo pipefail
cd "$(dirname "$0")/.."

flutter test tool/export_speech.dart | grep -o 'Exported [0-9]* speech parts.' || true
manifest=build/speech/manifest.tsv
out=assets/audio
mkdir -p "$out"

# Best installed voice for a locale: Premium, then Enhanced, then the fallback.
best_voice() {
  local locale=$1 fallback=$2 names
  names=$(say -v '?' | sed -nE "s/^(.*[^ ]) +${locale} +#.*/\1/p")
  for quality in Premium Enhanced; do
    local match
    match=$(grep -F "($quality)" <<<"$names" | head -1 || true)
    if [[ -n $match ]]; then echo "$match"; return; fi
  done
  echo "$fallback"
}
en_voice=${EN_VOICE:-$(best_voice en_US Samantha)}
es_voice=${ES_VOICE:-$(best_voice es_MX Paulina)}
en_rate=${EN_RATE:-165}
es_rate=${ES_RATE:-160}
echo "English voice: $en_voice ($en_rate wpm)"
echo "Spanish voice: $es_voice ($es_rate wpm)"

# A different voice or speed invalidates every clip.
stamp="$en_voice|$en_rate|$es_voice|$es_rate"
if [[ -f $out/.voices && $(cat "$out/.voices") != "$stamp" ]]; then
  echo "Voice settings changed; re-recording everything."
  find "$out" -name '*.m4a' -delete
fi
echo "$stamp" >"$out/.voices"

# Remove clips for text that no longer exists.
cut -f1 "$manifest" | sort >build/speech/wanted.txt
for file in "$out"/*.m4a; do
  [[ -e $file ]] || continue
  key=$(basename "$file" .m4a)
  grep -qx "$key" build/speech/wanted.txt || rm "$file"
done

# Record missing clips in parallel.
jobs=build/speech/jobs
: >"$jobs"
while IFS=$'\t' read -r key lang text; do
  [[ -f $out/$key.m4a ]] && continue
  if [[ $lang == en ]]; then voice=$en_voice rate=$en_rate; else voice=$es_voice rate=$es_rate; fi
  printf '%s\0%s\0%s\0%s\0' "$voice" "$rate" "$out/$key.m4a" "$text" >>"$jobs"
done <"$manifest"
todo=$(tr -cd '\0' <"$jobs" | wc -c | awk '{print $1 / 4}')
echo "Recording $todo new clips..."
# say pads its own .m4a files with 32 KB, so record raw audio and compress it.
xargs -0 -n 4 -P "${JOBS:-8}" sh -c '
  base=$(mktemp -t speech) raw=$base.aiff
  say -v "$1" -r "$2" -o "$raw" "$4" &&
    afconvert -f m4af -d aac -b 24000 "$raw" "$3"
  rm -f "$base" "$raw"' _ <"$jobs"

# Index of bundled clips, read by the app.
{
  printf '{\n  "note": "Prototype narration recorded with macOS voices; not licensed for distribution.",\n'
  printf '  "voices": {"en": "%s", "es": "%s"},\n  "clips": [\n' "$en_voice" "$es_voice"
  ls "$out" | sed -n 's/\.m4a$//p' | sort |
    awk '{ printf "%s    \"%s\"", (NR > 1 ? ",\n" : ""), $0 } END { print "" }'
  printf '  ]\n}\n'
} >"$out/index.json"
echo "Done: $(ls "$out"/*.m4a | wc -l | tr -d ' ') clips, $(du -sh "$out" | cut -f1)."
