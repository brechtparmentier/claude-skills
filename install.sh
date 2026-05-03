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

# Stap 4 — tool-adapters (Copilot .instructions.md + Codex AGENTS.md)
# Per skill: installeer adapter-bestanden naar de juiste tool-locaties.

detect_vscode_prompts_dir() {
  case "$(uname -s)" in
    Linux*)          echo "${HOME}/.config/Code/User/prompts" ;;
    Darwin*)         echo "${HOME}/Library/Application Support/Code/User/prompts" ;;
    MINGW*|MSYS*|CYGWIN*) echo "${APPDATA:-$HOME/AppData/Roaming}/Code/User/prompts" ;;
    *)               echo "" ;;
  esac
}

VSCODE_PROMPTS="$(detect_vscode_prompts_dir)"

_install_adapter() {
  local src="$1" dst="$2" label="$3"
  if [ -z "$dst" ]; then return; fi
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    ts="$(date +%Y%m%d_%H%M%S)"
    printf "\033[33m[WARN]\033[0m %s bestaat (geen symlink) → .backup-%s\n" "$dst" "$ts"
    mv "$dst" "${dst}.backup-${ts}"
  fi
  ln -sfn "$src" "$dst"
  printf "\033[32m[OK]\033[0m %-12s → %s\n" "$label" "$dst"
}

for skill in "${SKILLS[@]}"; do
  src_dir="$CACHE_DIR/$skill"

  # Copilot .instructions.md → VS Code user prompts
  copilot_src="${src_dir}/${skill}.instructions.md"
  if [ -f "$copilot_src" ] && [ -n "$VSCODE_PROMPTS" ]; then
    _install_adapter "$copilot_src" "${VSCODE_PROMPTS}/${skill}.instructions.md" "Copilot"
  fi

  # Codex / Claude Code AGENTS.md → ~/.codex/AGENTS/<skill>.md
  agents_src="${src_dir}/AGENTS.md"
  codex_dst="${HOME}/.codex/AGENTS/${skill}.md"
  if [ -f "$agents_src" ]; then
    _install_adapter "$agents_src" "$codex_dst" "Codex"
    # Maak ook ~/.claude/AGENTS/<skill>.md aan voor Claude Code
    claude_agents_dst="${HOME}/.claude/AGENTS/${skill}.md"
    _install_adapter "$agents_src" "$claude_agents_dst" "ClaudeCode"
  fi
done
