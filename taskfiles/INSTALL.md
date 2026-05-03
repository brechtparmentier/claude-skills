<!-- v1.0.0 — 2026-05-03 -->
# Installeren — taskfiles skill

Deze folder (`skills/taskfiles/`) bevat een complete, zelfstandige skill.
De inhoud is direct kopieerbaar naar de juiste locatie voor jouw setup.

## Optie A — Anthropic skill (system-wide)

Kopieer naar je gebruikersprofiel zodat alle Cowork/Claude Code sessies de skill
automatisch kunnen triggeren.

### Linux / macOS
```bash
cp -r skills/taskfiles ~/.claude/skills/
```

### Windows
```powershell
Copy-Item -Recurse skills\taskfiles $env:APPDATA\Claude\skills\
```

Daarna activeert de skill automatisch op natuurlijke triggers
("kijk eens naar mijn taskfile", "maak een nieuwe taskfile", etc.) — zie SKILL.md frontmatter.

## Optie B — Plugin-bundel

Pak de hele `taskfiles/` folder in een plugin-archive zodat je hem kunt distribueren
naar je werkmachines (Kubuntu-NUC, linuxoptiplexvpn, etc.).

```bash
cd skills/
tar czf taskfiles-v1.0.0.tar.gz taskfiles/
# Of voor zip:
zip -r taskfiles-v1.0.0.zip taskfiles/
```

Verspreid het archive en op de doelmachine: untar in `~/.claude/skills/`.

## Optie C — Project-lokale skill

Voor één specifieke repo waar je de skill wil testen zonder system-wide te installeren:
kopieer de hele folder naar `<project-root>/.claude/skills/taskfiles/`.

## Verificatie na installatie

Open een nieuwe Cowork/Claude Code sessie en typ:

> "Welke skills heb ik?"

`taskfiles` zou in de lijst moeten verschijnen. Of test direct:

> "Kijk eens naar mijn taskfile."

Dat zou AUTO-flow moeten activeren (zie SKILL.md §0).

## Versie checken

Versie staat in:
- `SKILL.md` frontmatter (`version: 1.0.0` + `updated: 2026-05-03`)
- `CHANGELOG.md` bovenste vermelding
- Header van elke sub-file (`<!-- v1.0.0 — 2026-05-03 -->`)

## Update flow

Bij een nieuwe versie:
1. Vervang de hele `~/.claude/skills/taskfiles/` folder
2. Of: `git pull` als je hem als git-repo beheert
3. Skill triggert automatisch op de nieuwe versie bij volgende activatie
