#!/usr/bin/env bash
# update-skills.sh — sync claude-skills naar al je servers in één run.
# Vereist: SSH-keys + ~/.ssh/config aliases voor de servers hieronder.
#
# Pas SERVERS aan naar jouw machine-namen.
# Run lokaal: ./update-skills.sh
set -uo pipefail

# ── Servers (aliases uit ~/.ssh/config) ──────────────────────────────────────
SERVERS=(
  kubuntu-nuc
  linuxoptiplexvpn
  linuxoptiplexpagaaiervpn
  linuxpc92
  linodeserver
  linux-pagaaier
  linux-gbsodk
)

# ── Optioneel: alleen specifieke skill updaten ───────────────────────────────
SKILL_FILTER="${1:-}"   # bv. ./update-skills.sh taskfiles

# ── Kleur-helpers ────────────────────────────────────────────────────────────
GREEN=$'\033[32m'; YELLOW=$'\033[1;33m'; RED=$'\033[31m'; CYAN=$'\033[1;36m'; RST=$'\033[0m'

INSTALL_URL="https://raw.githubusercontent.com/brechtparmentier/claude-skills/main/install.sh"

failures=()
successes=()

for server in "${SERVERS[@]}"; do
  printf "\n%s=== %s ===%s\n" "$CYAN" "$server" "$RST"

  # Quick reachability check (2s). StrictHostKeyChecking=accept-new zodat nieuwe
  # servers niet fout-positief als unreachable worden gemarkeerd.
  if ! ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "$server" 'true' 2>/dev/null; then
    printf "%s[SKIP]%s niet bereikbaar (timeout/auth)\n" "$YELLOW" "$RST"
    failures+=("$server (unreachable)")
    continue
  fi

  # Run install.sh remotely — idempotent, handelt clone én pull af
  if ssh -o StrictHostKeyChecking=accept-new "$server" "curl -sL '$INSTALL_URL' | bash -s '$SKILL_FILTER'"; then
    successes+=("$server")
  else
    printf "%s[FAIL]%s install/update mislukt\n" "$RED" "$RST"
    failures+=("$server (install error)")
  fi
done

# ── Samenvatting ─────────────────────────────────────────────────────────────
printf "\n%s=== Samenvatting ===%s\n" "$CYAN" "$RST"
printf "%s[OK]%s    %d server(s) bijgewerkt: %s\n" "$GREEN" "$RST" "${#successes[@]}" "${successes[*]:-(geen)}"
if [ "${#failures[@]}" -gt 0 ]; then
  printf "%s[FAIL]%s  %d server(s) mislukt:\n" "$RED" "$RST" "${#failures[@]}"
  printf "          - %s\n" "${failures[@]}"
  exit 1
fi
