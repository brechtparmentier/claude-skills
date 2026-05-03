#!/usr/bin/env bash
# install.sh — installeer claude-skills (alle of specifieke) op deze machine.
# Idempotent: tweede run doet git pull i.p.v. clone.
# Usage:
#   ./install.sh                # alle skills
#   ./install.sh taskfiles      # alleen taskfiles skill
set -euo pipefail

REPO_URL="https://github.com/brechtparmentier/claude-skills.git"
CACHE_DIR="${CLAUDE_SKILLS_CACHE:-${HOME}/.cache/claude-skills}"
SKILL_FILTER="${1:-}"   # optioneel: skill-naam om alleen die te installeren

# Detecteer Claude skills target dir per OS
detect_target_dir() {
  case "$(uname -s)" in
    Linux*|Darwin*) echo "${HOME}/.claude/skills" ;;
    MINGW*|MSYS*|CYGWIN*) echo "${APPDATA:-$HOME/AppData/Roaming}/Claude/skills" ;;
    *) echo "${HOME}/.claude/skills" ;;
  esac
}

TARGET_DIR="$(detect_target_dir)"
mkdir -p "$TARGET_DIR" "$(dirname "$CACHE_DIR")"

# Stap 1 — clone of pull cache
if [ -d "$CACHE_DIR/.git" ]; then
  printf "\033[1m[INFO]\033[0m Updating cache: %s\n" "$CACHE_DIR"
  git -C "$CACHE_DIR" fetch --tags --prune --quiet
  git -C "$CACHE_DIR" pull --rebase --quiet
else
  printf "\033[1m[INFO]\033[0m Cloning: %s → %s\n" "$REPO_URL" "$CACHE_DIR"
  git clone --quiet "$REPO_URL" "$CACHE_DIR"
fi

# Stap 2 — bepaal welke skills te installeren
SKILLS=()
if [ -n "$SKILL_FILTER" ]; then
  if [ -d "$CACHE_DIR/$SKILL_FILTER" ] && [ -f "$CACHE_DIR/$SKILL_FILTER/SKILL.md" ]; then
    SKILLS=("$SKILL_FILTER")
  else
    printf "\033[31m[ERR]\033[0m skill '%s' niet gevonden in %s\n" "$SKILL_FILTER" "$CACHE_DIR"
    printf "Beschikbaar:\n"
    find "$CACHE_DIR" -maxdepth 2 -name SKILL.md -exec dirname {} \; \
      | xargs -I{} basename {} | sort -u | sed 's/^/  - /'
    exit 1
  fi
else
  while IFS= read -r skill_dir; do
    SKILLS+=("$(basename "$skill_dir")")
  done < <(find "$CACHE_DIR" -maxdepth 2 -name SKILL.md -exec dirname {} \;)
fi

# Stap 3 — symlink elke skill naar target dir
for skill in "${SKILLS[@]}"; do
  src="$CACHE_DIR/$skill"
  dst="$TARGET_DIR/$skill"

  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    ts="$(date +%Y%m%d_%H%M%S)"
    printf "\033[33m[WARN]\033[0m %s bestaat al (geen symlink) — verplaats naar .backup-%s\n" "$dst" "$ts"
    mv "$dst" "${dst}.backup-${ts}"
  fi

  ln -sfn "$src" "$dst"
  version="$(grep '^version:' "$src/SKILL.md" 2>/dev/null | head -1 | awk '{print $2}')"
  printf "\033[32m[OK]\033[0m %s v%s → %s\n" "$skill" "${version:-?}" "$dst"
done

printf "\n\033[32m[OK]\033[0m %d skill(s) geïnstalleerd in %s\n" "${#SKILLS[@]}" "$TARGET_DIR"
printf "Test in een nieuwe Cowork/Claude Code sessie.\n"
