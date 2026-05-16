#!/usr/bin/env bash
# install.sh — installeer claude-skills (alle of specifieke) op deze machine.
# Idempotent: tweede run doet git pull i.p.v. clone.
# Usage:
#   ./install.sh                # alle skills
#   ./install.sh taskfiles      # alleen taskfiles skill
#
# VS Code Remote SSH gebruikers (Windows host → Linux remote):
#   Run dit script ZOWEL op je Windows machine (Git Bash) als op elke Linux remote.
#   - Windows install → Copilot global instructions in %APPDATA%\Code\User\prompts\
#   - Linux install   → Copilot via VS Code Server in ~/.vscode-server/data/User/prompts/
#                       + Claude Code + Codex adapters
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

  # Windows: symlinks vereisen Developer Mode — gebruik cp als fallback
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) cp -r "$src" "$dst" ;;
    *)                    ln -sfn "$src" "$dst" ;;
  esac
  version="$(grep '^version:' "$src/SKILL.md" 2>/dev/null | head -1 | awk '{print $2}')"
  printf "\033[32m[OK]\033[0m %s v%s → %s\n" "$skill" "${version:-?}" "$dst"
done

printf "\n\033[32m[OK]\033[0m %d skill(s) geïnstalleerd in %s\n" "${#SKILLS[@]}" "$TARGET_DIR"
printf "Test in een nieuwe Cowork/Claude Code sessie.\n"

# Stap 4 — tool-adapters (Copilot .instructions.md + Codex AGENTS.md)
# Per skill: installeer adapter-bestanden naar de juiste tool-locaties.

# Detecteer of we op Windows draaien (Git Bash / MSYS2)
is_windows() {
  case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; *) return 1 ;; esac
}

# Op Windows: symlinks vereisen Developer Mode of admin — gebruik cp
_link_or_copy() {
  local src="$1" dst="$2"
  if is_windows; then
    cp -r "$src" "$dst"
  else
    ln -sfn "$src" "$dst"
  fi
}

detect_vscode_prompts_dirs() {
  # Geeft alle relevante VS Code prompts-mappen terug (spatie-gescheiden), afhankelijk van OS
  local dirs=()
  case "$(uname -s)" in
    Linux*)
      # Lokale VS Code installatie (als aanwezig)
      dirs+=("${HOME}/.config/Code/User/prompts")
      # VS Code Server — wordt gebruikt bij Remote SSH vanuit Windows
      dirs+=("${HOME}/.vscode-server/data/User/prompts")
      ;;
    Darwin*)
      dirs+=("${HOME}/Library/Application Support/Code/User/prompts")
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Lokale Windows VS Code — dit is wat Copilot laadt als host bij Remote SSH
      dirs+=("${APPDATA:-$HOME/AppData/Roaming}/Code/User/prompts")
      ;;
  esac
  printf '%s\n' "${dirs[@]}"
}

_install_adapter() {
  local src="$1" dst="$2" label="$3"
  if [ -z "$dst" ]; then return; fi
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    ts="$(date +%Y%m%d_%H%M%S)"
    printf "\033[33m[WARN]\033[0m %s bestaat → .backup-%s\n" "$dst" "$ts"
    mv "$dst" "${dst}.backup-${ts}"
  fi
  _link_or_copy "$src" "$dst"
  printf "\033[32m[OK]\033[0m %-16s → %s\n" "$label" "$dst"
}

for skill in "${SKILLS[@]}"; do
  src_dir="$CACHE_DIR/$skill"

  # Copilot .instructions.md → alle relevante VS Code prompts-mappen
  copilot_src="${src_dir}/${skill}.instructions.md"
  if [ -f "$copilot_src" ]; then
    while IFS= read -r prompts_dir; do
      [ -z "$prompts_dir" ] && continue
      label="Copilot"
      # Onderscheid lokale vs. server installatie in label
      [[ "$prompts_dir" == *vscode-server* ]] && label="Copilot(SSH)"
      _install_adapter "$copilot_src" "${prompts_dir}/${skill}.instructions.md" "$label"
    done < <(detect_vscode_prompts_dirs)
  fi

  # Codex AGENTS.md
  agents_src="${src_dir}/AGENTS.md"
  if [ -f "$agents_src" ]; then
    _install_adapter "$agents_src" "${HOME}/.codex/AGENTS/${skill}.md"   "Codex"
    _install_adapter "$agents_src" "${HOME}/.claude/AGENTS/${skill}.md"  "ClaudeCode"
  fi
done

# Reminder voor Remote SSH gebruikers op Linux
if ! is_windows && [ -d "${HOME}/.vscode-server" ]; then
  printf "\n\033[1;36m[TIP]\033[0m VS Code Server gedetecteerd.\n"
  printf "      Copilot(SSH) adapter geïnstalleerd in ~/.vscode-server/data/User/prompts/\n"
  printf "      Voer dit script ook uit op je Windows host (Git Bash) voor global Copilot support:\n"
  printf "      curl -sL 'https://raw.githubusercontent.com/brechtparmentier/claude-skills/main/install.sh' | bash\n"
fi
