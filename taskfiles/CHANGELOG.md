# Changelog

Notable changes to the Taskfiles skill.
Format: [Keep a Changelog](https://keepachangelog.com/), versies volgen [Semver](https://semver.org/).

## Versionering-regels

- **MAJOR** (1.0.0 → 2.0.0): breaking change in skill-conventies (nieuwe modus, hard rule wijzigt, file-structuur wijzigt)
- **MINOR** (1.0.0 → 1.1.0): nieuw profile, nieuwe optionele module, nieuwe anti-pattern, nieuwe drift-correctie
- **PATCH** (1.0.0 → 1.0.1): verduidelijking, typo, kleine bugfix in voorbeeld-snippet

Bij elke wijziging: bump versie in `SKILL.md` frontmatter (`version` + `updated`) + entry hieronder.

---

## [Unreleased]

(geen pending wijzigingen)

---

## [1.1.1] — 2026-05-03

### Fixed — drift in canonical reference (kritiek)
- **`references/canonical/Taskfile.yml`** regel 8: `dotenv: ['.env', '.env.local']` → `['.env.local', '.env']`. De skill rapporteerde AP-07 maar leverde zelf een buggy template — propageerde de bug bij elke STANDAARD/NEW. Real-run trigger: AUDIT op `nextjs_workspaceSpotifySingleAudioController` vond AP-07 in een Taskfile die rechtstreeks van canonical was afgeleid.
- **`references/canonical/taskfiles/core.yml`** vars: `RUNTIME_DIR`, `LOGS_DIR`, `DEV_LOG`, `PROD_LOG` van `.taskrun/...` → `.task/...` (drift-correctie #2 uit `references/README.md` is nu in canonical zelf toegepast).

### Changed — anti-pattern detection scope-aanscherping
- **AP-12** (geen doctor): aangescherpt naar "geen `doctor:` als root-shortcut". `core:doctor` op zichzelf voldoet niet meer — Pattern A vereist een root-facade entry die ernaar forwarded.
- **AP-14** (geen setup): zelfde aanscherping voor `setup:`.
- Nieuwe toelichting-sectie in `docs/anti-patterns.md` voor AP-12/13/14 met fout/goed-voorbeelden van root-facade compleetheid.

### Added — validatiechecklist uitgebreid
- **Root-facade compleetheid** sectie: alle "Verplicht"-tasks uit het profile moeten als root-shortcut bestaan. Specifieke checks voor `task doctor` en `task setup` (meest-vergeten shortcuts in real-run).
- **Destructieve clean-tasks** sectie: `task clean` mag alleen build-artefacten verwijderen, niet `.task/`/`node_modules/`/`.venv/` (preview van komende AP-29 in v1.2.0).

### Documented
- **`docs/mini-templates.md`** help-renderer: expliciete uitleg waarom printf-stijl gekozen is i.p.v. `task --list` (bewuste keuze voor sectie-headers, dynamische context, kleur-onderscheid). Bekende -2 in audit-scoring is **false-positive** voor deze skill.

### Real-run validation
- AUDIT op `nextjs_workspaceSpotifySingleAudioController` (`linuxpc92`/Kubuntu-NUC):
  - Score: 83/100 → FIX-modus correct gekozen
  - Gevonden bugs in skill zelf: AP-12/14 detection-rule te zwak, canonical met dotenv-drift
  - Beide gefixt in deze release

---

## [1.1.0] — 2026-05-03

### Changed — anti-pattern detection scope-uitbreiding
- **AP-24** uitgebreid van `medium` naar **`hoog`**: nu ook detectie in **sub-project `package.json` scripts** (mono-repo's met `web/`, `frontend/`, `app/`, `dashboard/` submappen). De skill scant alle sub-folder package.json's met `"next"` dep en flagt ontbrekende `--port` flag in `scripts.dev`/`scripts.start`.
- Real-run trigger: `IntuneAssignmentCheckerBrechtsMod/web/package.json` had `next dev --hostname 127.0.0.1` zonder `--port`. v1.0.0 miste dit omdat alleen Taskfile-vars werden gecheckt.

### Added — nieuwe anti-pattern
- **AP-28** (hoog): Cross-service port-conflict detectie. Universele regel — niet stack-specifiek. Skill scant alle bron-files (Taskfile vars, alle `package.json` scripts, `ecosystem.config.*`, Python startup scripts, `docker-compose*` host-side ports) en flagt duplicate poort-claims. Skill **bepaalt niet zelf** welke service welke `ports.json`-sleutel krijgt — dat blijft een project-keuze, skill detecteert alleen het conflict en vraagt confirmatie.

### Updated — flows
- `flows/standard.md` Stap 1 Discovery: pre-checks 4 en 5 toegevoegd (sub-project Next.js detectie + cross-service port-conflict scan)
- `flows/fix.md`: voorbeeld-FIX-job toegevoegd voor "Next.js sub-project zonder --port" met 6-stappen recipe

### Updated — Profile 1 Next.js (`docs/profiles.md`)
- "Cruciaal — `--port` als CLI-flag op TWEE plekken": Taskfile DEV_CMD én sub-project package.json
- "Multi-service port conflict" sectie toegevoegd (universele regel, niet "Next.js = api")
- "Mono-repo aware": expliciete vermelding dat sub-mappen met `next` dep mee-gescand worden

### Design principle gehandhaafd
- Universele patronen primeren — geen stack-specifieke aannames over welke `ports.json`-sleutel welke service krijgt. Skill detecteert conflicten, gebruiker beslist toewijzing.

---

## [1.0.0] — 2026-05-03

### Added — Skill modes
- 6 modi: **AUTO** (default), NEW, AUDIT, FIX, STANDAARD, REFACTOR
- AUTO-flow met score-gebaseerde routing (≥90 = niets, 75-89 = FIX, 50-74 = STANDAARD, <50 = STANDAARD+REFACTOR)
- Confirmation-gates per risico-niveau (nul/laag/middel/hoog)

### Added — Anti-patterns
- 27 anti-patterns met severiteit, toelichting en fix-snippets
- AP-21 t/m AP-25: gosh-safety (bash-vs-gosh PID-handling, plain `kill`, `ss` alias-conflict, Next.js `--port`, PM2-detect)
- AP-26 t/m AP-27: calcport-integratie (hardcoded ports + ports.json detect, `task ports` command)

### Added — Building blocks (gen-3)
- Vijf verplichte building blocks: `_ensure-ready`, `_kill-mode`, `_wait-for-endpoint`, `_show-endpoints`, `_bootstrap-env`
- Gosh-safe design: nooit `$!` als PID-bron, altijd `/bin/kill` voor extern gestarte processen
- Multi-iface VPN-detectie (nmcli → tun/wg/tailscale/zt → RFC1918 → 10.0.0.x)
- HTTPS-aware lifecycle met openssl SAN-check
- Auto-setup detection via mtime-vergelijking lockfile ↔ deps marker

### Added — Drop-in templates
- `references/canonical/` — Next.js gold standard (Taskfile.yml + taskfiles/core.yml + taskfiles/project.yml)
- `references/profiles/python/` — FastAPI/uvicorn + uv + ruff + pytest
- `references/patterns/core-multi-service.yml` — backend+frontend parallel + PGID-kill
- `references/patterns/core-shared-server-safe.yml` — `stop_if_owned` voor gedeelde hosts
- `references/patterns/core-prod-pipeline.yml` — parallelle prod-stack

### Added — Scoring & validation
- 100-puntenscoremodel met 9 categorieën (`docs/audit-scoring.md`)
- Validatiechecklist met gosh-safety + calcport-integratie checks
- 12 test-prompts (5 AUTO, 3 NEW, 1 AUDIT, 1 FIX, 1 STANDAARD, 1 REFACTOR)

### Added — Conventies
- Pattern A is default voor app-repo's
- Runtime-dir = `.task/` (drift-correctie van `.taskrun/`)
- `dotenv: ['.env.local', '.env']` (override wint)
- `silent: true` op file-niveau, `silent: false` op user-facing tasks
- Internal tasks: `_prefix` ÉN `internal: true`
- Calcport-integratie verplicht waar `calcport` beschikbaar is
- Tooling per stack: pnpm (Node), uv+ruff+pytest (Python)

### Refactored
- Skill opgesplitst van monolithische `skill.md` (1480 regels) naar:
  - `SKILL.md` (~250 regels, dispatcher)
  - `flows/` — 4 flow-modules (new, fix, standard, refactor)
  - `docs/` — 11 referentie-modules (decision-tree, profiles, gen3-building-blocks, modules, anti-patterns, audit-scoring, question-strategy, fallbacks, validation-checklist, mini-templates, never-do)
  - `tests/prompts.md` — 12 test-prompts
- Pre-refactor monolithische versie bewaard als `skill.legacy.md`
- Skill verhuisd naar dedicated folder `skills/taskfiles/` (afgesplitst van bron-collectie),
  zodat de skill direct kopieerbaar is naar `~/.claude/skills/` of in een plugin verpakt kan worden

### Validation
- Real-run getest op `nextjs_workspaceSpotifySingleAudioController`
  (score 64/100 → STANDAARD-modus correct gekozen, 11+ items in plan)
- Skill-update gap geïdentificeerd en gefixt: calcport pre-check ontbrak in `flows/standard.md`
  Stap 1 Discovery — toegevoegd in v1.0.0

### Known gaps (planned for v1.1+)
- Drop-in profielen voor 6 stacks ontbreken nog (Clasp, VS Code ext, CLI tool, AI/monitoring, Server beheer, Multi-project toolbelt)
- AUDIT output-format niet vastgelegd (nu vrij gevormd)
- Geen BREAKING.md template voor refactors
- Geen `.env.example` / `.task/.gitignore` mini-templates
- Mermaid-diagram voor decision-tree ontbreekt
- Skill nog niet geïnstalleerd als echte Cowork-skill (staat nu in collectie-folder)

---

## Pre-1.0.0 development

De skill is iteratief opgebouwd in een serie sessies (mei 2026):

1. Best-practices analyse van 75+ Taskfiles in `_verzameldeTaskfiles` → `BRECHT_TASKFILE_BEST_PRACTICES.md`
2. Identificatie van 3 generaties core.yml (gen-1/gen-2/gen-3) en 4 hoofdpatronen (A/B/C/D)
3. Canonieke gen-3 geïdentificeerd: `linuxoptiplexvpn/nextjs_frontend-gdriverights/` (774 regels, 8 building blocks)
4. Initial monolithic skill.md geschreven (3 modi: NEW/AUDIT/REFACTOR)
5. Modi-uitbreiding: FIX (punctueel) + STANDAARD (bulk modernize) toegevoegd
6. AUTO als default toegevoegd (Brecht's UX-inzicht)
7. Drift-correcties geïdentificeerd uit canonical (dotenv, runtime-dir)
8. Real-run op spotify-controller → gosh-safety bugs (AP-21/22/23) ontdekt en in skill verwerkt
9. Calcport-integratie als verplichte pre-check toegevoegd (Brecht's gap-vangst)
10. Big-bang refactor naar modulaire structuur (deze release)
