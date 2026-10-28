#!/usr/bin/env bash
# Resolve a stable codesign identity for personal installs.
# Prefer Apple Development + Personal Team so TCC grants stick across rebuilds.
# Ad-hoc (`-`) changes CDHash every sign → macOS re-prompts Microphone / Screen Recording.
#
# Outputs (eval-friendly):
#   SIGN_IDENTITY=...
#   DEVELOPMENT_TEAM=...   (empty when ad-hoc)
#   SIGN_MODE=apple-development|adhoc
#
# Override: SPEAKER_MASTER_DEVELOPMENT_TEAM=<TeamID>
set -euo pipefail

prefer_team="${SPEAKER_MASTER_DEVELOPMENT_TEAM:-}"

list_apple_development() {
  local identities line name subject team
  identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"
  [[ -z "$identities" ]] && return 0
  while IFS= read -r line; do
    name="$(sed -n 's/.*"\(Apple Development: [^"]*\)".*/\1/p' <<<"$line")"
    [[ -z "$name" ]] && continue
    subject="$(security find-certificate -c "${name%% (*}" -p 2>/dev/null \
      | openssl x509 -noout -subject 2>/dev/null || true)"
    team="$(sed -n 's/.*OU=\([^,/]*\).*/\1/p' <<<"$subject" | head -1 | tr -d ' ')"
    [[ -z "$team" ]] && continue
    printf '%s\t%s\n' "$team" "$name"
  done <<<"$identities" | LC_ALL=C sort -u
}

picked_team=""
picked_name=""

while IFS=$'\t' read -r team name; do
  [[ -z "$team" || -z "$name" ]] && continue
  if [[ -n "$prefer_team" ]]; then
    if [[ "$team" == "$prefer_team" ]]; then
      picked_team="$team"
      picked_name="$name"
      break
    fi
    continue
  fi
  # Deterministic: lexicographically first Team ID among Apple Development certs.
  picked_team="$team"
  picked_name="$name"
  break
done < <(list_apple_development)

if [[ -n "$picked_name" && -n "$picked_team" ]]; then
  SIGN_IDENTITY="$picked_name"
  DEVELOPMENT_TEAM="$picked_team"
  SIGN_MODE="apple-development"
else
  SIGN_IDENTITY="-"
  DEVELOPMENT_TEAM=""
  SIGN_MODE="adhoc"
fi

printf 'SIGN_IDENTITY=%q\n' "$SIGN_IDENTITY"
printf 'DEVELOPMENT_TEAM=%q\n' "$DEVELOPMENT_TEAM"
printf 'SIGN_MODE=%q\n' "$SIGN_MODE"
