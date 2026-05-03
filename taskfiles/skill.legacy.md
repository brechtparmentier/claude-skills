---
name: taskfiles
description: >
  Activeer deze skill wanneer de gebruiker een Taskfile.yml wil maken, auditen of refactoren,
  of wanneer hij/zij vraagt om een task-runner setup voor een project. Triggers: "maak een Taskfile",
  "Taskfile.yml", "audit deze taskfile", "refactor mijn taskfile", "task-runner setup",
  "taskfile best practices", "core.yml", "split-file taskfile", "gen-3 core", "Pattern A/B/C/D".
  Activeer NIET voor algemene `task` CLI vragen, andere build-tools (Make/just/npm scripts),
  of generieke shell-script vragen die niets met Brechts Taskfile-conventies te maken hebben.
---

# Taskfile Architect — skill

Genereer, audit en refactor Taskfiles volgens Brechts vastgelegde conventies. Canonieke basis:
**Pattern A** (thin facade + core.yml + project.yml) met **gen-3 core.yml** (auto-setup,
PID-managed kill, waited startup, multi-iface VPN, env-bootstrap).

---

## TL;DR — Wat doet deze skill

**Default modus = AUTO** (detecteer + kies passende sub-modus + apply).
Andere modi alleen als user expliciet zegt wat hij wil.

| Modus | Input | Output |
|---|---|---|
| **AUTO** ⭐ default | Bestaande Taskfile of leeg project | Self-detect → kiest NEW/FIX/STANDAARD/REFACTOR + apply |
| **NEW** | Projecttype + naam + technologie | Volledige Taskfile-set (root + taskfiles/) |
| **AUDIT** | Bestaande Taskfile(s) | Score op 100 + ranked findings + concrete fixes (read-only) |
| **FIX** | Bestaande Taskfile + één concreet probleem | Kleine diff op specifieke plek |
| **STANDAARD** | Verouderde Taskfile | Bulk-modernize naar huidige skill-conventies |
| **REFACTOR** | Bestaande Taskfile + specifiek target | Structurele transformatie naar dat target |

**Default keuzes** (niet vrijblijvend):
- AUTO is de echte default — gebruiker hoeft niet te kiezen
- Pattern A is default voor app-repo's
- Gen-3 core.yml is canoniek — geen gen-1/gen-2 produceren
- Runtime-dir is `.task/`
- `dotenv: ['.env.local', '.env']`
- `silent: true` op file-niveau, expliciet `silent: false` op user-facing tasks
- Internal tasks: `_prefix` ÉN `internal: true`
- Single-file boven 500 regels = altijd refactor naar Pattern A

**Volgende concrete stap:** ga direct naar §0 *AUTO-flow* tenzij user een specifieke modus heeft genoemd.

---

## Activatie

**Wel activeren — natuurlijke triggers met de modus die hieruit volgt:**

| Brecht zegt | Modus |
|---|---|
| "Kijk eens naar mijn Taskfile" / "fix mijn taskfile" / "kun je deze opfrissen" / *zonder specifieke verwoording* | **AUTO** ⭐ |
| "Maak een nieuwe Taskfile voor [project]" / "start een nieuwe repo met taskfile-setup" | **NEW** |
| "Audit/score deze Taskfile" / "wat is er mis met deze taskfile?" | **AUDIT** (read-only) |
| "[Specifiek probleem] fixen" / "voeg internal: true toe" / "VPN-detectie pakt mijn wg0 niet" | **FIX** |
| "Maak hem volledig standaard" / "modernize" / "breng in lijn met conventies" | **STANDAARD** |
| "Splits naar Pattern B" / "upgrade naar gen-3" / "Refactor naar [specifiek target]" | **REFACTOR** |
| "Voeg [db/docker/gh] namespace toe" / "maak een doctor-task" / "maak een help-renderer" | **FIX** of **REFACTOR** afh. van scope |

**Niet activeren:**
- Algemene `task` CLI gebruiksvragen ("hoe run ik task X?")
- Andere build-tools (Make, just, npm scripts, justfile)
- Generieke YAML/shell-script vragen
- Vragen die gaan over Anthropic skills i.p.v. `task` runner

---

## Modi-routing — geen vraag stellen, gewoon doen

**Bij activatie: ga direct naar §0 *AUTO-flow* tenzij user expliciet een specifieke modus benoemt** (zie Activatie-tabel hierboven).

Routing-tabel:

| User intent | Sectie |
|---|---|
| AUTO (default) | §0 *AUTO-flow* |
| NEW | §1 *Failproof generatieflow* |
| AUDIT | §6 *Audit-scoremodel* + §5b *Anti-pattern detectie* (read-only) |
| FIX | §7A *FIX-flow* |
| STANDAARD | §7B *STANDAARD-flow* |
| REFACTOR | §7C *REFACTOR-flow* |

**Vraag NOOIT "welke modus?" als opener.** AUTO doet zelf de detect. Alleen als de detect-stap stuit op iets dat beslissing van user vereist (bv. ambigu projecttype) → één gerichte vraag.

---

## §0 — AUTO-flow (default modus)

AUTO doet wat een goede senior collega zou doen die jouw conventies kent: kijkt naar de file, zegt wat moet gebeuren, vraagt confirm op de gevaarlijke dingen, doet de rest.

### Stap 1 — Detect huidige staat

```
GEEN Taskfile gevonden in project root:
  → detect stack via:
    - package.json met "next" dep                  → Next.js profile
    - package.json met "engines.vscode"            → VS Code ext profile
    - package.json zonder bovenstaande             → Node CLI / generic
    - pyproject.toml of requirements.txt           → Python profile
    - .clasp.json                                  → Clasp profile
    - ecosystem.config.js + simpel project         → Server PM2 profile
    - alleen losse scripts/ folder                 → CLI tool / toolbelt
  → ja gedetecteerd  → ga naar §0 Stap 3 met NEW-modus, geinferreerde defaults
  → niet detecteerbaar → vraag projecttype (1 vraag, multiple choice 1–8)

TASKFILE BESTAAT:
  → run interne AUDIT-pass (§5b anti-patterns + §6 score op 100)
  → ga naar §0 Stap 2
```

### Stap 2 — Kies sub-modus op basis van diagnose

| AUDIT-uitkomst | Kies | Confirmation? |
|---|---|---|
| **Score ≥ 90, geen anti-patterns** | toon AUDIT-output, **doe niets** | nee |
| **Score 75–89, alleen punctuele issues** | **FIX** alle gevonden issues | toon diffs vooraf, ga door tenzij user stop zegt |
| **Score 50–74, structuur OK, veel drift/naming/tooling** | **STANDAARD** | toon plan, vraag confirm vóór schrijven |
| **Score < 50, óf Pattern fundamenteel verkeerd, óf gen-1/single-file >500 regels** | **STANDAARD + REFACTOR** (chained) | toon plan + impact, vraag confirm, bewaar `.archive/Taskfile.legacy.yml` |
| **Geen Taskfile + stack gedetecteerd** | **NEW** | vraag alleen onmisbare info (ports, app-module) |

### Stap 3 — Toon altijd vooraf (behalve bij score 90+)

Format:
```
Ik heb gevonden in [filename]:
- [N anti-patterns]: [korte lijst]
- [X drift items]: [korte lijst]
- [Y missing building blocks]: [korte lijst]

Ik ga uitvoeren: [FIX | STANDAARD | REFACTOR]
Concrete wijzigingen:
1. [...]
2. [...]
...

Akkoord?
```

### Stap 4 — Apply

Volg de bijhorende sectie:
- FIX → §7A
- STANDAARD → §7B
- REFACTOR → §7C
- NEW → §1

### Stap 5 — Diff-samenvatting + volgende stap

Bij REFACTOR/STANDAARD: bewaar oude file als `.archive/Taskfile.legacy.yml`. Toon korte tabel "wat hernoemd / verplaatst / nieuw". Eindig met één concreet commando: meestal `task doctor`.

### Confirmation-gates (cruciaal)

| Actie | Risico | Confirmation |
|---|---|---|
| AUDIT (read-only output) | nul | nooit |
| NEW (nieuwe files in lege project) | nul | alleen onmisbare info vragen |
| FIX (kleine diffs) | laag | toon diff, ga door tenzij user stopt |
| STANDAARD (bulk modernize) | middel | toon plan vooraf, vraag expliciet confirm |
| REFACTOR (structureel) | hoog | toon plan + impact, vraag expliciet confirm + bewaar legacy |

**AUTO mag niet blind zijn.** Voor middel/hoog risico altijd vooraf tonen wat gaat gebeuren.

---

## §1 — Failproof generatieflow (NEW)

Volg deze 9 stappen, in deze volgorde. Geen stap overslaan.

### Stap 1 — Projecttype bepalen

Vraag 1 (multiple choice):
> "Welk projecttype? (1) Next.js app — (2) Python app — (3) CLI/tooling — (4) Clasp/Apps Script — (5) VS Code extension — (6) AI/monitoring — (7) Server-beheer — (8) Multi-project toolbelt"

Als gebruiker iets noemt dat niet matcht → vraag of het *het meest lijkt op* een van die 8 → kies dat profiel.

### Stap 2 — Runtime-mode bepalen

Vraag 2:
> "Runtime: (a) lokaal-only, (b) docker-only, (c) toggle (USE_DOCKER 0/1)? Default = (a)."

### Stap 3 — Pattern kiezen (beslisboom)

Volg §2 *Beslisboom Pattern A/B/C/D* op basis van projecttype + runtime + verwachte complexiteit.

### Stap 4 — Verplichte tasks bepalen

Lees §3 *Projecttype-profielen* voor het gekozen profiel → noteer de verplichte top-level tasks.

### Stap 5 — Optionele modules bepalen

Vraag 3 (multi-select):
> "Heb je nodig: [ ] db (Prisma/Alembic/Drizzle) [ ] docker (multi-env compose) [ ] gh (issue/PR workflow) [ ] git (branch/promote/publish) [ ] service (user-systemd) [ ] prod (parallelle prod-stack)?"

### Stap 6 — Vars bepalen

Verzamel: `APP_NAME`, `FRONTEND_PORT`, `BACKEND_PORT` (als full-stack), `DEV_CMD`, `USE_DOCKER`, `DOCKER_SERVICE`, `START_TIMEOUT`, `STOP_TIMEOUT`. Voor missende vars → veilige defaults uit §9 *Fallbackgedrag*.

### Stap 7 — Files genereren

Genereer concreet:
- `Taskfile.yml` (root, thin facade) — zie §11 *Werkende mini-templates*
- `taskfiles/core.yml` (gen-3 skeleton) — zie §4 *Gen-3 core.yml canoniek*
- `taskfiles/project.yml` (project-specifieke commands)
- Optionele includes (db.yml, docker.yml, ...)
- `.env.example` als die nog niet bestaat

### Stap 8 — Validatiecheck tonen

Run §10 *Validatiechecklist* mentaal over de gegenereerde files. Toon resultaat aan gebruiker.

### Stap 9 — Gebruiksinstructies tonen

Geef concreet:
1. `task` (default → help)
2. `task setup` (eerste keer)
3. `task start` / `task stop` / `task status`
4. `task doctor` (check tooling)

Eindig altijd met **één concrete volgende stap**.

---

## §2 — Beslisboom Pattern A/B/C/D

```
Heeft project een runtime (start/stop/logs/status)?
├── Nee → Is het een wrapper rond 1 CLI tool met <15 commands?
│         ├── Ja → PATTERN D (single-file minimaal)
│         └── Nee → PATTERN C (single-file met namespaces)
└── Ja  → Heeft project >2 distincte concern-groepen
          (db + docker + git + monitoring + prod)?
         ├── Ja → PATTERN B (split-file + extra namespace-includes)
         └── Nee → PATTERN A (split-file: core.yml + project.yml)  ← DEFAULT
```

**Hard rules:**
- Single-file boven 500 regels → altijd Pattern A. Geen uitzonderingen.
- App-repo met start/stop → nooit Pattern C of D.
- Pure CLI-wrapper (clasp push/pull, audit-scripts) → nooit Pattern A. Pattern D.

---

## §3 — Projecttype-profielen

Elk profiel definieert: **default Pattern**, **default vars**, **verplichte tasks**, **veelvoorkomende modules**.

### Profiel 1 — Next.js app

- **Pattern**: A (B als prisma + multi-env docker)
- **Drop-in template**: `references/canonical/` (Next.js gold standard)
- **Ports**: calcport-driven via `ports.json` met fallback
- **Vars**: `APP_NAME`, `DEV_PORT`/`PROD_PORT` (uit ports.json), `USE_DOCKER=0`, `DEV_CMD`, `PROD_CMD`, `DOCKER_SERVICE`
- **Cruciaal — DEV_CMD/PROD_CMD met `--port` als CLI-flag** (zie AP-24):
  ```yaml
  DEV_CMD: 'pnpm exec next dev --port {{.DEV_PORT}}'
  PROD_CMD: 'pnpm exec next start --port {{.PROD_PORT}}'
  ```
  Next.js negeert `PORT` env volledig en valt terug op default 3000 → 3001/3002/3003 als bezet. Dat geeft een silently-broken setup waarbij `task start` "OK" rapporteert maar dev op de verkeerde poort draait.
- **Verplicht**: `default`, `help`, `start`, `stop`, `restart`, `logs`, `status`, `setup`, `doctor`, `install`, `build`, `test`, `lint`, `typecheck`, `check`, `ports`
- **Doctor-tools**: `task`, `git`, `node`, `pnpm`, `calcport`, `lsof` (verplicht); `fnm`, `docker` (optioneel)
- **Modules**: `db.yml` als prisma aanwezig, `docker.yml` als meerdere compose-files
- **PM2-aware**: als project PM2 gebruikt (huidig of legacy), activeer AP-25 fix in `_kill-mode`
- **Reference (gold)**: `linuxoptiplexvpn/nextjs_frontend-gdriverights/`

### Profiel 2 — Python app

- **Pattern**: A (B als FastAPI + worker + frontend)
- **Drop-in template**: `references/profiles/python/` (3 files: Taskfile.yml + taskfiles/core.yml + taskfiles/project.yml). Drift t.o.v. gold-standards is al gecorrigeerd.
- **Stack**: `uv` package manager, `ruff` (lint+format in één tool), `pytest`. Geen mypy default — opt-in via auskommentaar in project.yml.
- **Ports**: calcport-driven via `ports.json` met fallback (8000 dev / 8001 prod)
- **Vars**: `APP_NAME`, `APP_MODULE` (bv. `src.myapp.api:app`), `BACKEND_DEV_PORT`/`BACKEND_PROD_PORT` (uit ports.json), `PYTHON`, `UV`, `HOST` (default 0.0.0.0)
- **Verplicht**: `default`, `help`, `start`, `start-prod`, `stop`, `restart`, `logs`, `status`, `setup`, `setup-quick`, `doctor`, `install`, `ports`, `lint`, `lint:fix`, `format`, `format:check`, `check`, `test`, `clean`, `clean:all`, `clean:logs`, `uninstall`
- **Doctor-tools**: `task`, `git`, `uv`, `python3`, `calcport`, `lsof` (verplicht); `docker` (optioneel)
- **Bij hybrid (Python+frontend)**: voeg `taskfiles/frontend.yml` als optional include toe; gebruik `references/patterns/core-multi-service.yml` als referentie voor PGID-kill en aparte PID/log per service
- **Reference (gold)**: `linuxoptiplexvpn/python_rubricsObservatieTool/` (B), `python_leerlokaalFV/` (A), `_research_BingelAgendaLesFicheScraper/` (calcport-integratie)

### Profiel 3 — CLI/tooling

- **Pattern**: C (D voor pure single-CLI wrappers)
- **Vars**: `APP_NAME`, optioneel `GUI_SUDO=` voor sudo-modes
- **Verplicht**: `default`, `help`, `doctor`, plus tool-specifieke commands in namespace
- **Conventies**: gebruik shortcut-aliases (`s/x/r/st/l`), heredoc-help (`cat << 'EOF'`)
- **Fallback chains**: lint via `ruff || pylint || flake8`
- **Reference (gold)**: `linuxoptiplexvpn/tools_ufw/`

### Profiel 4 — Clasp / Google Apps Script

- **Pattern**: D (alleen clasp), A (full-stack), B (full-stack + prod parallel)
- **Vars**: `CLASP_AUTH` dynamisch uit `.clasp.profile`, `BACKEND_PORT`, `FRONTEND_PORT`
- **Verplicht (D-vorm)**: `push`, `pull`, `open`, `versions`, `deploy`
- **Verplicht (A/B-vorm)**: zie Profiel 2 (Python) + clasp-tasks
- **Reference (gold)**: `linuxoptiplexvpn/clasp_kalendertoolv202601/` (B), `digiSchoolKalender2526GKOK/` (D)

### Profiel 5 — VS Code extension

- **Pattern**: A met aparte `dev.yml` + `git.yml` als pattern-B includes
- **Vars**: `APP_NAME` (extensie-id)
- **Verplicht**: `default`, `help`, `start` (TS watcher), `stop`, `restart`, `logs`, `status`, `compile`, `lint`, `test`, `package`, `publish`
- **Module-conventie**: `core.yml` voor watcher-runtime, `dev.yml` voor compile/test/package, `git.yml` voor branch/promote/publish
- **Reference (gold)**: `linuxoptiplexvpn/vscodeExt_combineFilesToOne/`

### Profiel 6 — AI/monitoring

- **Pattern**: C (single-file met namespaces) of A als runtime-toggle nodig is
- **Vars**: `AGENT_PORT`, `DASHBOARD_PORT`, `RUNTIME_DIR=.task`
- **Verplicht**: `default`, `help`, `start`, `stop`, `status`, `doctor`, `_build-runtime`, `_start-agent`, `_start-dashboard` (internal)
- **Health-check**: `lsof`-based port detection + curl
- **Reference (gold)**: `linux-pagaaier/ai_centralAImonitoring/`

### Profiel 7 — Server-beheer

- **Pattern**: C (multi-script wrapper met namespaces) of A (PM2 service)
- **Vars**: `SERVICE_NAME`, runtime-specifiek
- **Verplicht (PM2 service)**: `default`, `help`, `start`, `stop`, `restart`, `logs`, `status`, `install`, `enable`, `disable`
- **Verplicht (multi-script)**: `default`, `help`, plus genamespacede tasks: `vpn:add`, `nginx:reload`, `backup:db`, `security:scan`, `docker:cleanup`. **Geen platte `vpn-add`-taken op root.**
- **Reference (gold)**: `linodeserver/wireguardTool/` (PM2), `linodeserver/_linodeServerBeheer/` (multi-script — namespaces nodig)

### Profiel 8 — Multi-project toolbelt

- **Pattern**: meta-pattern. Root Taskfile dat sub-taskfiles include (`tools:*`, `linux:*`, `server:*`)
- **Vars**: optioneel
- **Verplicht**: `default`, `help`, plus namespace-prefixes per sub-project
- **Reference (gold)**: `linuxpc92/_linuxTools/`

---

## §4 — Gen-3 core.yml canoniek

**De canonieke template staat als drop-in bestand in `references/canonical/`.**

Bron-identificatie: `linuxoptiplexvpn/nextjs_frontend-gdriverights/` is de meest geavanceerde gen-3 in Brechts collectie (774 regels core.yml, 8 internal building blocks, HTTPS-aware, `nmcli`-gebaseerde 4-laags VPN-detectie, mtime-auto-setup, openssl SAN-check). Zie `references/README.md` voor de volledige feature-matrix versus alternatieven.

**Werkmodus van de skill:**

1. Bij NEW: kopieer alle drie de files uit `references/canonical/` naar het doelproject:
   - `Taskfile.yml` → repo root
   - `taskfiles/core.yml`
   - `taskfiles/project.yml`
2. Pas alle vars aan volgens **Customization-checklist** in `references/README.md`
3. Pas de twee bekende drift-correcties toe (zie §10):
   - `dotenv: ['.env', '.env.local']` → `['.env.local', '.env']`
   - `RUNTIME_DIR: .taskrun` → `.task`
4. Voeg stack-specifieke `doctor:` checks toe in `project.yml`

**De vijf verplichte gen-3 internal building blocks** (in elke variant van core.yml die deze skill produceert):

| Building block | Doel | gosh-safe? |
|---|---|---|
| `_ensure-ready` | mtime-vergelijking lockfile ↔ deps marker → auto `task setup` | n.v.t. |
| `_kill-mode` | PID-bestand → `/bin/kill` → fuser orphan-cleanup op poort | **ja** (zie AP-22) |
| `_wait-for-endpoint` | curl-polling met SCHEME-detect, configurable timeout | n.v.t. |
| `_show-endpoints` | multi-iface VPN-detectie + lokale + vpn endpoint-test | n.v.t. |
| `_bootstrap-env` | `.env.example` → `.env.local` fallback chain | n.v.t. |

**gosh-safe design** (kritiek — niet wijzigen tenzij je weet wat je doet):

`start:` slaat **nooit** `$!` op als PID. In plaats daarvan wacht hij op endpoint-up via `_wait-for-endpoint` en leest dan de echte PID via `fuser PORT/tcp` (zie AP-21). Dit omzeilt de go-task gosh-bug waarbij `$!` `g1` retourneert i.p.v. een numerieke PID.

`_kill-mode` gebruikt expliciet `/bin/kill` (niet shell-builtin `kill`) omdat gosh's builtin `kill` alleen werkt voor jobs in zijn eigen tabel — niet voor `nohup`-gestarte processen die naar systemd reparented zijn (zie AP-22).

Header-comment-conventie boven `start:` en `_kill-mode:` in elke gegenereerde core.yml:
```yaml
# gosh-safe: vermijdt $! als PID-bron (gebruikt fuser na _wait-for-endpoint)
#            gebruikt /bin/kill expliciet (gosh kill-builtin pakt geen externe PIDs)
```

**Daarnaast 3 patroon-fragmenten** voor specifieke project-types (in `references/patterns/`):

| Bestand | Wanneer toepassen |
|---|---|
| `core-multi-service.yml` | Project met >1 langlopend service-proces (backend+frontend parallel). Neem over: aparte PID/log vars per service, `_stop:service` met parameter, **PGID-kill** voor orphan-children |
| `core-shared-server-safe.yml` | Project op shared server. Neem over: `stop_if_owned` met `/proc/$PID/cwd` check vóór killen |
| `core-prod-pipeline.yml` | Project met parallelle prod-stack (eigen ports/PIDs/logs naast dev). Neem over: `PROD_BACKEND_PID/PGID/LOG` vars, externe `./scripts/stop_service.sh`, `prod:rebuild` |

**Skeleton voor wie geen toegang heeft tot `references/canonical/`** (bv. wanneer de skill in een andere context wordt gebruikt zonder de referentie-files):

```yaml
version: '3'
silent: true

vars:
  APP_NAME: '{{default "<app-name>" .APP_NAME}}'
  FRONTEND_PORT: '{{default "<port>" .FRONTEND_PORT}}'
  USE_DOCKER: '{{default "0" .USE_DOCKER}}'
  DEV_CMD: '{{default "<dev-cmd>" .DEV_CMD}}'
  STOP_CMD: '{{default "" .STOP_CMD}}'
  RESTART_CMD: '{{default "" .RESTART_CMD}}'
  LOGS_CMD: '{{default "tail -f .task/logs/dev.log" .LOGS_CMD}}'
  STATUS_CMD: '{{default "" .STATUS_CMD}}'
  DOCKER_SERVICE: '{{default "" .DOCKER_SERVICE}}'
  RUNTIME_DIR: '{{default ".task" .RUNTIME_DIR}}'
  LOGS_DIR: '{{default ".task/logs" .LOGS_DIR}}'
  START_TIMEOUT: '{{default "30" .START_TIMEOUT}}'
  STOP_TIMEOUT: '{{default "15" .STOP_TIMEOUT}}'
  VPN_IP: '{{default "" .VPN_IP}}'
  GREEN: '\033[32m'
  YELLOW: '\033[1;33m'
  CYAN: '\033[1;36m'
  RED: '\033[31m'
  RESET: '\033[0m'

tasks:
  # ── User-facing lifecycle ─────────────────────────────────────────
  help:
    desc: Show core help
    silent: false
    cmds:
      - task: _show-endpoints
      # printf-stijl help met dynamische url/mode/ports
      - |
        printf "{{.CYAN}}=== {{.APP_NAME}} ==={{.RESET}}\n"
        printf "{{.YELLOW}}Lifecycle:{{.RESET}}\n"
        printf "  {{.GREEN}}task start{{.RESET}}     start app\n"
        printf "  {{.GREEN}}task stop{{.RESET}}      stop app\n"
        printf "  {{.GREEN}}task restart{{.RESET}}   restart app\n"
        printf "  {{.GREEN}}task logs{{.RESET}}      tail logs\n"
        printf "  {{.GREEN}}task status{{.RESET}}    runtime status\n"
        printf "  {{.GREEN}}task doctor{{.RESET}}    diagnose tooling\n"

  start:
    desc: Start app (docker or local)
    silent: false
    cmds:
      - task: _ensure-dirs
      - task: _ensure-ready
      - task: _bootstrap-env
      - task: _start-impl
      - task: _wait-for-endpoint
      - task: _show-endpoints

  stop:
    desc: Stop app
    silent: false
    cmds:
      - task: _kill-mode

  restart:
    desc: Restart app
    silent: false
    cmds:
      - task: stop
      - task: start

  logs:
    desc: Follow logs
    silent: false
    cmds:
      - task: _logs-impl

  status:
    desc: Runtime status
    silent: false
    cmds:
      - task: _status-impl
      - task: _show-endpoints

  doctor:
    desc: Diagnose tooling and env
    silent: false
    cmds:
      # check required tools, env files, runtime dir, ports — exit non-zero on critical issues
      - task: _doctor-impl

  # ── Internal building blocks (niet aanpassen tenzij echt nodig) ───
  _ensure-dirs:
    internal: true
    cmds:
      - mkdir -p {{.RUNTIME_DIR}} {{.LOGS_DIR}}

  _ensure-ready:
    internal: true
    # Auto-setup detection: vergelijk lockfile mtime met installed deps marker.
    # Trigger `task setup` als out-of-date.
    cmds:
      - |
        # Pseudo-implementatie: vergelijk mtimes, run setup indien nodig.
        # Concrete check varieert per stack (pnpm/uv/poetry/npm).
        true

  _bootstrap-env:
    internal: true
    cmds:
      - |
        if [ ! -f .env.local ] && [ -f .env.example ]; then
          cp .env.example .env.local
          printf "{{.YELLOW}}[INIT]{{.RESET}} .env.local aangemaakt vanuit .env.example\n"
        fi

  _kill-mode:
    internal: true
    # PID-file → fuser orphan-cleanup → docker compose down
    env:
      _USE_DOCKER: '{{.USE_DOCKER}}'
      _STOP_CMD: '{{.STOP_CMD}}'
      _FRONTEND_PORT: '{{.FRONTEND_PORT}}'
      _RUNTIME_DIR: '{{.RUNTIME_DIR}}'
      _STOP_TIMEOUT: '{{.STOP_TIMEOUT}}'
    cmds:
      - |
        if [ "${_USE_DOCKER}" = "1" ]; then
          docker compose down
          exit 0
        fi
        # Try graceful via STOP_CMD or PID-file, fallback fuser on port
        if [ -n "${_STOP_CMD}" ]; then
          sh -c "${_STOP_CMD}" || true
        fi
        if [ -f "${_RUNTIME_DIR}/dev.pid" ]; then
          PID=$(cat "${_RUNTIME_DIR}/dev.pid")
          kill -TERM "$PID" 2>/dev/null || true
          for i in $(seq 1 ${_STOP_TIMEOUT}); do
            kill -0 "$PID" 2>/dev/null || break
            sleep 1
          done
          kill -KILL "$PID" 2>/dev/null || true
          rm -f "${_RUNTIME_DIR}/dev.pid"
        fi
        # Final fallback: fuser orphan cleanup op poort
        fuser -k "${_FRONTEND_PORT}/tcp" 2>/dev/null || true

  _wait-for-endpoint:
    internal: true
    env:
      _PORT: '{{.FRONTEND_PORT}}'
      _TIMEOUT: '{{.START_TIMEOUT}}'
    cmds:
      - |
        SCHEME="http"
        if [ -f .cert/local.crt ] || [ -n "${HTTPS:-}" ]; then SCHEME="https"; fi
        URL="${SCHEME}://localhost:${_PORT}"
        for i in $(seq 1 ${_TIMEOUT}); do
          if curl -sk -o /dev/null -w "%{http_code}" "${URL}" | grep -qE '^(200|3..|404)'; then
            printf "{{.GREEN}}[OK]{{.RESET}} endpoint ready: %s\n" "${URL}"
            exit 0
          fi
          sleep 1
        done
        printf "{{.YELLOW}}[WARN]{{.RESET}} endpoint niet bereikbaar binnen ${_TIMEOUT}s\n"

  _show-endpoints:
    internal: true
    env:
      _PORT: '{{.FRONTEND_PORT}}'
      _VPN_IP: '{{.VPN_IP}}'
    cmds:
      - |
        # Multi-iface VPN-detectie:
        # 1) nmcli connected wireguard|vpn|tun|tap
        # 2) ip -o -4 addr op tun|tap|wg|tailscale|ppp|utun|zt|vpn
        # 3) ip -o -4 addr met RFC1918, exclude lo|docker|br-|veth|virbr|en|eth|wl|wwan
        # 4) override via VPN_IP env
        detect_vpn_ip() {
          if [ -n "${_VPN_IP}" ]; then echo "${_VPN_IP}"; return; fi
          if command -v nmcli >/dev/null 2>&1; then
            IF=$(nmcli -t -f NAME,TYPE,DEVICE c show --active 2>/dev/null \
                 | awk -F: '$2 ~ /wireguard|vpn|tun|tap/ {print $3; exit}')
            if [ -n "$IF" ]; then
              IP=$(ip -o -4 addr show "$IF" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
              [ -n "$IP" ] && echo "$IP" && return
            fi
          fi
          IP=$(ip -o -4 addr show 2>/dev/null \
               | awk '$2 ~ /^(tun|tap|wg|tailscale|ppp|utun|zt|vpn)/ {print $4}' \
               | cut -d/ -f1 | head -1)
          if [ -n "$IP" ]; then echo "$IP"; return; fi
          # RFC1918 fallback
          ip -o -4 addr show 2>/dev/null \
            | awk '$2 !~ /^(lo|docker|br-|veth|virbr|en|eth|wl|wwan)/ {print $4}' \
            | cut -d/ -f1 \
            | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' \
            | head -1
        }
        VPN=$(detect_vpn_ip)
        printf "{{.YELLOW}}url:{{.RESET}}    http://localhost:%s\n" "${_PORT}"
        if [ -n "$VPN" ]; then
          printf "{{.YELLOW}}vpn:{{.RESET}}    http://%s:%s\n" "$VPN" "${_PORT}"
        fi

  _start-impl:
    internal: true
    env:
      _USE_DOCKER: '{{.USE_DOCKER}}'
      _DEV_CMD: '{{.DEV_CMD}}'
      _RUNTIME_DIR: '{{.RUNTIME_DIR}}'
      _LOGS_DIR: '{{.LOGS_DIR}}'
    cmds:
      - |
        if [ "${_USE_DOCKER}" = "1" ]; then
          docker compose up -d
          exit 0
        fi
        # Local: start dev cmd in background, write PID
        nohup sh -c "${_DEV_CMD}" >"${_LOGS_DIR}/dev.log" 2>&1 &
        echo $! > "${_RUNTIME_DIR}/dev.pid"

  _logs-impl:
    internal: true
    env:
      _USE_DOCKER: '{{.USE_DOCKER}}'
      _LOGS_CMD: '{{.LOGS_CMD}}'
      _DOCKER_SERVICE: '{{.DOCKER_SERVICE}}'
    cmds:
      - |
        if [ "${_USE_DOCKER}" = "1" ]; then
          if [ -n "${_DOCKER_SERVICE}" ]; then
            docker compose logs -f "${_DOCKER_SERVICE}"
          else
            docker compose logs -f
          fi
          exit 0
        fi
        sh -c "${_LOGS_CMD}"

  _status-impl:
    internal: true
    env:
      _USE_DOCKER: '{{.USE_DOCKER}}'
      _STATUS_CMD: '{{.STATUS_CMD}}'
      _RUNTIME_DIR: '{{.RUNTIME_DIR}}'
    cmds:
      - |
        if [ "${_USE_DOCKER}" = "1" ]; then docker compose ps; exit 0; fi
        if [ -n "${_STATUS_CMD}" ]; then sh -c "${_STATUS_CMD}"; exit 0; fi
        if [ -f "${_RUNTIME_DIR}/dev.pid" ]; then
          PID=$(cat "${_RUNTIME_DIR}/dev.pid")
          if kill -0 "$PID" 2>/dev/null; then
            printf "{{.GREEN}}[OK]{{.RESET}} running (pid %s)\n" "$PID"
          else
            printf "{{.RED}}[X]{{.RESET}} pid-file aanwezig maar proces dood\n"
          fi
        else
          printf "{{.YELLOW}}[--]{{.RESET}} not running\n"
        fi

  _doctor-impl:
    internal: true
    cmds:
      - |
        FAIL=0
        check() {
          if command -v "$1" >/dev/null 2>&1; then
            printf "{{.GREEN}}[OK]{{.RESET}} %s\n" "$1"
          else
            printf "{{.RED}}[X]{{.RESET}} %s ontbreekt\n" "$1"
            FAIL=1
          fi
        }
        # stack-specifieke tools (vul aan via project.yml)
        check task
        check git
        # check env
        if [ ! -f .env.local ] && [ ! -f .env ]; then
          printf "{{.YELLOW}}[!]{{.RESET}} geen .env.local of .env gevonden\n"
        fi
        exit $FAIL
```

**Belangrijk**: stack-specifieke tooling-checks (pnpm, uv, prisma, ...) gaan in `project.yml`'s `doctor:` task die `core:doctor` aanvult, **niet** in core.yml.

---

## §5 — Optionele modules

Per module: doel, includepad, kerntakkenset.

### `taskfiles/db.yml`
- **Doel**: Prisma/Alembic/Drizzle wrappers
- **Tasks**: `db:generate`, `db:migrate`, `db:push`, `db:studio`, `db:seed`, `db:reset`, `db:deploy`
- **Reference**: `linuxoptiplexvpn/nextjs_klasspiegelsMVP/Taskfile.yml` (db.yml include)

### `taskfiles/docker.yml`
- **Doel**: multi-environment compose management
- **Tasks**: `docker:dev`, `docker:prod`, `docker:local`, `docker:latest`, `docker:status`, `docker:stop`, `docker:logs`
- **Conventie**: 1 compose-file per omgeving, 1 task per file, vaste poorten per omgeving
- **Reference**: `linuxoptiplexvpn/nextjs_klasspiegelsMVP/Taskfile.yml`

### `taskfiles/gh.yml`
- **Doel**: GitHub issue/PR/feature/fix workflow
- **Tasks**: `gh:issue`, `gh:feature`, `gh:fix`, `gh:pr`, `gh:merge`, `gh:close`
- **Reference**: `nextjs_garagebox` (extract uit single-file)

### `taskfiles/git.yml`
- **Doel**: branch/promote/publish workflow
- **Tasks**: `git:branch`, `git:promote`, `git:publish`, `git:tag`
- **Reference**: `linuxoptiplexvpn/vscodeExt_combineFilesToOne/`

### `taskfiles/service.yml`
- **Doel**: user-systemd service install/management
- **Tasks**: `service:install`, `service:enable`, `service:disable`, `service:status`, `service:logs`
- **Reference**: `linuxpc92/repo-workspace/`

### `taskfiles/prod.yml`
- **Doel**: parallelle prod-stack naast dev (eigen ports, eigen PIDs)
- **Tasks**: `prod:start`, `prod:stop`, `prod:restart`, `prod:logs`, `prod:status`, `prod:deploy`
- **Conventie**: aparte `PROD_FRONTEND_PORT`, `PROD_BACKEND_PORT` vars; eigen `RUNTIME_DIR/prod-*.pid`
- **Reference**: `linuxoptiplexvpn/clasp_kalendertoolv202601/`

---

## §5b — Anti-pattern detectie

Run deze checks bij AUDIT en bij elke generatie als sanity-check.

| # | Check | Severiteit |
|---|---|---|
| AP-01 | Hardcoded server-naam in vars (`PROD_HOST: 'linuxpagaaiervpn'`) | hoog |
| AP-02 | `silent: true` per task overal i.p.v. file-level default | medium |
| AP-03 | `_prefix` zonder `internal: true` | medium |
| AP-04 | Backward-compat alias-sectie >50 regels | hoog |
| AP-05 | Single-file >500 regels met verstopte lifecycle-laag | hoog |
| AP-06 | Platte task-namen voor >10 server-scripts (geen namespacing) | hoog |
| AP-07 | `dotenv: ['.env', '.env.local']` (override wint niet) | hoog |
| AP-08 | Alleen `tun0` als VPN-interface check | medium |
| AP-09 | ANSI-codes inconsistent gemixt binnen 1 file | laag |
| AP-10 | `task: core:help` zonder `silent: false` op wrapper | medium |
| AP-11 | Mixed naming binnen één repo (`build:docker-full`, `setup:venv`, `installDeps`) | medium |
| AP-12 | Geen `doctor:` task | medium |
| AP-13 | Geen `default:` of `default → help` ontbreekt | medium |
| AP-14 | Geen `setup:` task (gebruiker moet zelf raden) | medium |
| AP-15 | Gen-1 of gen-2 core.yml structuur (geen `_ensure-ready`/`_kill-mode`/`_wait-for-endpoint`) | medium |
| AP-16 | `.task/`, `.taskrun/`, `.run/` mix binnen project | laag |
| AP-17 | Hardcoded paden naar HOME of repo-root | hoog |
| AP-18 | Ontbrekende `_bootstrap-env` (geen `.env.example` → `.env.local` fallback) | medium |
| AP-19 | Geen exit-codes / fout-propagatie in shell-blokken | hoog |
| AP-20 | Files > 700 regels zonder includes | hoog |
| AP-21 | `$!` als PID-bron in cmd-blok (go-task gosh-bug) | **hoog** |
| AP-22 | Plain `kill` (shell-builtin) voor extern gestarte processen | **hoog** |
| AP-23 | `ss` voor port-checks (alias-conflict, output-format-onbetrouwbaar) | medium |
| AP-24 | Next.js `DEV_CMD` met `PORT` env i.p.v. `--port` CLI-flag | medium |
| AP-25 | Geen PM2-detectie in `_kill-mode` als project PM2 gebruikt (PM2 respawnt anders) | medium |
| AP-26 | Hardcoded ports in vars terwijl `calcport` beschikbaar is OF `ports.json` ontbreekt | **hoog** |
| AP-27 | Geen `task ports` command + geen `calcport` in doctor-checks | medium |

Bij audit toon je gevonden anti-patterns met regelnummer + concrete fix.

### Toelichting bij AP-21 t/m AP-25 — go-task / gosh-context

Deze vijf anti-patterns komen voort uit de **gosh shell-engine** die go-task ≥ 3.48 ingebouwd gebruikt. Veel "intuïtieve" bash-patterns werken anders of niet:

**AP-21 — `$!` is onbetrouwbaar in gosh.**
In bash geeft `$!` de PID van het laatste background proces. In go-task gosh geeft het een **job-ID zoals `g1`** — geen numerieke PID. Gevolg: `echo $! > .task/dev.pid` schrijft "g1" naar het PID-bestand, en alle latere `kill`/`kill -0` operaties falen.

**Fix-patroon (canonical):** sla `$!` niet op. Gebruik `_wait-for-endpoint` om te wachten tot de poort up is, en lees daarna de echte PID via fuser:

```yaml
- task: _wait-for-endpoint
  vars: { PORT: '{{.PORT}}', SCHEME: '{{.SCHEME}}', ... }
- |
  REAL_PID=$(fuser "{{.PORT}}"/tcp 2>/dev/null | awk '{print $1}')
  [ -z "$REAL_PID" ] && { printf "[ERR] PID niet bepaald\n"; exit 1; }
  echo "$REAL_PID" > "{{.RUNTIME_DIR}}/dev.pid"
```

**AP-22 — gosh `kill` builtin werkt niet voor externe processen.**
gosh's ingebouwde `kill` opereert alleen op jobs in zijn eigen tabel. Processen die via `nohup ... &` zijn gestart en naar systemd reparented zijn, zijn voor gosh "onzichtbaar".

**Fix-patroon (canonical):** gebruik altijd `/bin/kill` expliciet:

```yaml
while /bin/kill -0 "$PID" 2>/dev/null && [ "$W" -lt "{{.STOP_TIMEOUT}}" ]; do
  sleep 1; W=$((W+1))
done
/bin/kill -0 "$PID" 2>/dev/null && /bin/kill -KILL "$PID" 2>/dev/null || true
```

**AP-23 — `ss` voor port-checks is dubbel onbetrouwbaar.**
- Brecht heeft `ss` aliased naar `smart-search` — `ss -tlnp | grep ...` runt dan de search-tool i.p.v. socket-statistics
- Output-format van `ss` varieert per versie en kan in non-interactive shells anders zijn

**Fix-patroon:** gebruik `fuser -n tcp PORT` (returnt exact alleen PIDs) of `lsof -i :PORT`:

```yaml
if fuser "$PORT"/tcp >/dev/null 2>&1; then
  PID=$(fuser "$PORT"/tcp 2>/dev/null | awk '{print $1}')
fi
```

**AP-24 — Next.js negeert `PORT` env.**
`next dev` valt terug op default 3000 (en daarna 3001/3002/3003 als bezet) als je niet expliciet `--port` als CLI-flag meegeeft. `PORT=25050 pnpm dev` werkt **niet**.

**Fix-patroon:** in vars-blok van core.yml:

```yaml
DEV_CMD: 'pnpm exec next dev --port {{.DEV_PORT}}'
PROD_CMD: 'pnpm exec next start --port {{.PROD_PORT}}'
```

Of als de start-cmd via `pnpm dev` script loopt: pas het npm-script in `package.json` aan om `--port` mee te geven.

**AP-26 — Hardcoded ports zonder calcport-integratie.**
Brecht's setup gebruikt `calcport` (bash tool) dat poorten berekent obv repo-naam en de uitkomst opslaat in `ports.json` (root) + `ports.md` + AI-tool docs (`copilot-instructions.md`, `CLAUDE.md`, `AGENTS.md`). Hardcoded poorten in `vars:` ondermijnen dit en leiden tot port-conflicts tussen repos.

**Detectie-checklist** (run aan het begin van AUDIT/STANDAARD/AUTO):
1. Bestaat `calcport` als command? (`command -v calcport`)
2. Bestaat `ports.json` in repo-root?
3. Bestaat `ports.md` in repo-root?
4. Heeft de Taskfile hardcoded poort-vars (regex: `_PORT:\s*['"]?\d+`)?

| calcport beschikbaar? | ports.json bestaat? | hardcoded ports? | Verdict |
|---|---|---|---|
| ja | ja | nee | OK ✅ |
| ja | ja | ja | **AP-26** — vervang hardcoded met `sh:`-blok dat ports.json leest |
| ja | nee | ja | **AP-26** — genereer `ports.json` via `calcport`, dan vervang hardcoded |
| ja | nee | nee | mogelijk nieuw project — run `calcport` om ports.json te seeden |
| nee | — | — | calcport is system-conventie maar ontbreekt: melden in doctor, fallback gebruiken |

**Fix-patroon (canonical):**

```yaml
vars:
  PORTS_FILE: '{{default "ports.json" .PORTS_FILE}}'
  DEV_PORT:
    sh: |
      if [ -f "{{.PORTS_FILE}}" ]; then
        python3 -c 'import json; d=json.load(open("{{.PORTS_FILE}}")); print(d.get("standard_development",{}).get("frontend") or d.get("frontend",{}).get("dev") or 3000)' 2>/dev/null || echo 3000
      elif command -v calcport >/dev/null 2>&1; then
        calcport 2>/dev/null | awk '/frontend.*dev/ {for(i=1;i<=NF;i++) if($i+0>0) {print $i; exit}}' || echo 3000
      else
        echo 3000
      fi
```

**AP-27 — Geen `task ports` + geen calcport in doctor.**
Standaard moet elke gegenereerde Taskfile een `task ports` command hebben dat `ports.json` toont (of `calcport` runt als fallback), en `calcport` als verplichte tool in `doctor:` opnemen.

**AP-25 — PM2 respawnt na `fuser -k`.**
Als een project PM2 gebruikt (zelfs een oude installatie van een eerdere versie van het project), zal PM2 het proces direct herstarten na een poort-kill. Symptomen: `task stop` lijkt te werken maar `task status` toont meteen weer RUNNING.

**Fix-patroon (uitbreiding van `_kill-mode`):** detecteer PM2-parentage voordat je kill doet:

```yaml
PORT_PID=$(fuser "$PORT"/tcp 2>/dev/null | awk '{print $1}')
if [ -n "$PORT_PID" ]; then
  PARENT_PID=$(ps -o ppid= -p "$PORT_PID" 2>/dev/null | tr -d '[:space:]')
  PARENT_CMD=$(ps -o cmd= -p "$PARENT_PID" 2>/dev/null)
  if echo "$PARENT_CMD" | grep -q "PM2"; then
    pm2 stop all 2>/dev/null || pm2 delete all 2>/dev/null || true
  fi
fi
# daarna pas /bin/kill + fuser -k fallback
```

---

## §6 — Audit-scoremodel (100 punten)

Categorieën met gewicht. Geef per categorie een score 0–max + 1-zin uitleg + concrete fix.

| # | Categorie | Max | Wat telt mee |
|---|---|---|---|
| 1 | Structuur / patroonkeuze | 15 | Klopt Pattern A/B/C/D voor dit projecttype? |
| 2 | Lifecycle-robuustheid | 15 | start/stop/restart/logs/status aanwezig + werken in beide modes (docker/local) + PID-management + waited startup |
| 3 | Runtime management | 10 | `.task/` runtime-dir, PID-file, log-rotation, `_ensure-dirs` |
| 4 | Env / bootstrap | 10 | `dotenv` correcte volgorde, `.env.example` → `.env.local` bootstrap, geen secrets gecommit |
| 5 | Naming consistency | 8 | `kebab-case` lifecycle, `kebab:colon` namespaces, `_kebab` internal — geen mix |
| 6 | Namespace hygiene | 8 | Geen platte `vpn-add` voor 30 scripts; logische groeperingen |
| 7 | Doctor / status / help kwaliteit | 10 | Doctor checkt tooling + env; help is dynamisch (mode/url/port); status klopt voor beide modes |
| 8 | Anti-pattern risico | 14 | Som van severiteit van gevonden anti-patterns: 0 = 14 pt; 1 hoog = -7; 1 medium = -3; 1 laag = -1 |
| 9 | Onderhoudbaarheid | 10 | Geen >500 regel single-file, geen mega-alias-sectie, includes gebruikt, vars gedocumenteerd |

**Drempels:**
- 90–100 → "gold standard, geen actie nodig"
- 75–89 → "solid, kleine verbeteringen aanbevolen"
- 50–74 → "werkt, maar refactor naar Pattern A + gen-3 aanbevolen"
- <50 → "fundamenteel herstructureren"

---

## §7A — FIX-flow

Gegeven: bestaande Taskfile + één concreet probleem (van user benoemd, of geïdentificeerd door §5b anti-pattern detectie binnen AUTO).

**Scope:** punctueel. Geen pattern-wijziging, geen file-restructuring. Kleine diffs op specifieke plekken.

**Stap 1 — Locate** Lees de file, identificeer **exact** waar het probleem zit (regelnummer of task-naam).

**Stap 2 — Diagnose** Eén regel waarom de huidige aanpak faalt of suboptimaal is.

**Stap 3 — Fix** Schrijf vervangende snippet (geen volledige file-rewrite). Pas alleen de relevante regels aan.

**Stap 4 — Verify** Toon de diff (before/after) + concrete test-stap voor de gebruiker (bv. "run `task doctor` om te valideren dat fnm-detectie nu werkt").

**Stap 5 — Suggest gerelateerde** 1-2 vergelijkbare problemen die mogelijk ook bestaan. Alleen melden, niet automatisch fixen tenzij user expliciet vraagt.

**Voorbeelden van FIX-jobs:**
- "VPN-detectie pakt mijn wg0 niet" → vervang `tun0`-grep met multi-iface block uit §4
- "Voeg internal: true toe aan alle _prefix tasks" → loop door file, voeg toe waar mist
- "Doctor checkt uv niet" → voeg `need uv` toe aan doctor-task
- "Hardcoded port vervangen door calcport" → vervang var-block met `sh:`-driven calcport call
- "Maak doctor sneller via parallel checks" → herwrite met `&` + `wait`

---

## §7B — STANDAARD-flow

Gegeven: bestaande Taskfile + user-intent "breng in lijn met current standard" (of AUTO heeft STANDAARD gekozen op basis van diagnose).

**Scope:** bulk. Discovery + apply-all van afwijkingen tegelijk.

**Stap 1 — Discovery** Run intern §5b *Anti-pattern detectie* + §6 *Audit-scoremodel*. Vergelijk met `references/canonical/` + skill-conventies. Maak lijst van **alles** wat afwijkt.

**Verplichte pre-checks** (controleer deze altijd, niet alleen wanneer ze in de Taskfile-tekst voorkomen):

1. **Calcport-status** (zie AP-26):
   - Run `command -v calcport` — beschikbaar?
   - Bestaat `ports.json` in repo-root?
   - Bestaat `ports.md` in repo-root?
   - Heeft de Taskfile hardcoded poort-vars (regex: `_PORT:\s*['"]?\d+`)?
   - Op basis hiervan: voeg AP-26 of AP-27 toe aan findings als drift.
2. **gosh-safety**:
   - Bevat de Taskfile `echo \$!` patronen? → AP-21
   - Bevat de Taskfile plain `kill ` (niet `/bin/kill`)? → AP-22
   - Bevat de Taskfile `ss -tlnp` of `ss -tnlp`? → AP-23
3. **Stack-specifieke pre-checks**:
   - Next.js: bevat `DEV_CMD` `--port` flag? → AP-24 als nee
   - Next.js + ecosystem.config.* aanwezig: PM2-aware `_kill-mode`? → AP-25 als nee

**Standaard discovery-categorieën**:

- Pattern (single-file >500 regels → A; missing includes)
- Generatie (gen-1/gen-2 building blocks ontbreken → gen-3)
- Naming (snake_case/camelCase → kebab-case + kebab:colon)
- dotenv volgorde
- Runtime dir (`.taskrun`/`logs`/`.run` → `.task`)
- Internal tasks zonder `internal: true`
- Hardcoded ports → calcport-driven (AP-26)
- Tooling: pip → uv, py_compile → ruff, npm → pnpm (per stack-conventie)
- Building blocks ontbrekend (alle 5 gen-3 blocks)
- VPN-detectie alleen tun0 → multi-iface
- Doctor missing of incompleet — moet calcport bevatten (AP-27)
- `task ports` command ontbreekt (AP-27)
- Backward-compat alias-secties >50 regels (verwijderen → migratie-tabel in BREAKING.md)
- Hardcoded paden in vars
- Help-task statisch i.p.v. dynamisch (mode/url/ports)

**Stap 2 — Plan tonen** Toon de hele lijst van geplande wijzigingen aan user. Vraag expliciet confirm voordat je iets schrijft.

Format:
```
Ik ga STANDAARD uitvoeren op [filename]. Gevonden afwijkingen:

Structureel (3):
- [...]

Drift-correcties (5):
- [...]

Tooling (2):
- [...]

Building blocks ontbrekend (4):
- [...]

Akkoord om alles toe te passen?
```

**Stap 3 — Apply-all** Schrijf nieuwe file-set in één keer. Gebruik `references/profiles/<stack>/` als basis. Bewaar oude file als `.archive/Taskfile.legacy.yml`.

**Stap 4 — Backward compat** Voor publieke tasks die hernoemd worden:
- Max 5 aliases. Niet meer.
- Geen alias-sectie van >50 regels.
- Genereer een `BREAKING.md` met migratie-tabel `oude-naam → nieuwe-naam`.

**Stap 5 — Validatie + diff-samenvatting** Run §10 *Validatiechecklist*. Toon korte tabel "wat hernoemd / verplaatst / nieuw". Eindig met `task doctor` als eerste validatiestap.

---

## §7C — REFACTOR-flow

Gegeven: bestaande Taskfile + **specifiek** target pattern of generatie van user.

**Scope:** chirurgisch. Alleen de aangevraagde structurele transformatie. Géén drift-correcties of naming-fixes meebrengen tenzij user dat expliciet vraagt.

**Stap 1 — Fingerprint** Bepaal huidige pattern (D/C/B/A) en gen (1/2/3) van core. Bevestig user-target.

**Stap 2 — Migratiepad** Kies kleinste veilige sprong:
- **D → A**: extraheer lifecycle naar nieuwe core.yml; project-specifieke commands → project.yml; root wordt thin facade
- **C → A**: zelfde, maar identificeer eerst de "verstopte lifecycle-laag" (zoek tasks die start/stop/logs/status doen of er semantisch op lijken)
- **A gen-1/gen-2 → A gen-3**: vervang core.yml door gen-3 skeleton (§4); behoud project-specifieke vars-overrides; voeg ontbrekende 5 internal building blocks toe
- **A → B**: identificeer concern-clusters (db/docker/git/prod) → split naar aparte include-files

**Stap 3 — Plan tonen** Toon impact aan user. Vraag confirm.

**Stap 4 — Apply** Schrijf nieuwe file-set. Bewaar oude als `.archive/Taskfile.legacy.yml`.

**Stap 5 — Backward compat** Zelfde regels als §7B Stap 4 (max 5 aliases, BREAKING.md voor de rest).

**Stap 6 — Validatie + rollout** Run §10. Geef:
1. Wat te committen
2. Wat hernoemd is (kort lijstje)
3. Eerste commando: `task doctor`
4. Waar de legacy-file staat

**Verschil met STANDAARD:** REFACTOR doet **alleen** de structurele transformatie. Als user wil dat ook drift en naming gefixt worden, moet hij STANDAARD aanvragen, of REFACTOR + daarna AUTO/STANDAARD.

---

## §8 — Vraagstrategie

**Hoofdregel:** AUTO is default. AUTO stelt zo min mogelijk vragen — alleen waar detect faalt of confirmation nodig is voor middel/hoog risico.

**Hard maximum:** 3 vragen op een rij. Dan eerst genereren/auditen, dan eventueel doorvragen. ADD-vriendelijk.

### Vraag-tabel per modus

| Modus | Eerste vraag (alleen indien nodig) | Tweede | Derde |
|---|---|---|---|
| **AUTO** ⭐ | (geen — detect zelf) | bij score 50–74 of <50: confirm op plan | — |
| **NEW** | Projecttype (1–8) als niet detecteerbaar | Multi-select modules (db/docker/gh/git/service/prod) | Runtime mode (lokaal/docker/toggle) — alleen als niet af te leiden |
| **AUDIT** | (geen — alleen tonen) | — | — |
| **FIX** | (geen — user heeft probleem benoemd) | confirm op diff (impliciet, "ga door tenzij stop") | — |
| **STANDAARD** | (geen — discovery zelf) | confirm op plan vóór schrijven (verplicht) | — |
| **REFACTOR** | Target pattern als niet duidelijk uit prompt | confirm op plan + impact (verplicht) | — |

**Vragen die de skill ALTIJD mag stellen** (als kritiek):
- Confirmation op middel/hoog-risico actie (STANDAARD/REFACTOR plan)
- Projecttype bij NEW als detect faalt
- Stack-specifieke detail (bv. `APP_MODULE` voor Python uvicorn) — alleen als config niet leesbaar is

**Vragen die de skill NOOIT stelt:**
- "Welke modus wil je?" — AUTO is default, gebruik gewoon AUTO
- "Welke `silent` instelling?" — vast (file-level true)
- "Welke runtime-dir?" — altijd `.task/`
- "Welke dotenv-volgorde?" — altijd `['.env.local', '.env']`
- "Moet internal tasks `_prefix` of `internal: true`?" — beide
- "Welke linter/formatter?" — per stack vastgelegd in profile (Python = ruff, etc.)
- Ports voor stacks waar calcport-detectie ze kan vinden — gebruik `ports.json`/calcport eerst

**Bij ambigu user-intent:** liever proberen + tonen dan vragen. ADD-brein wil momentum, niet questionnaires.

---

## §9 — Fallbackgedrag (veilige defaults)

Bij ontbrekende info, gebruik deze defaults:

| Veld | Default | Vermeld in output |
|---|---|---|
| `APP_NAME` | repo-folder-naam | ja |
| `FRONTEND_PORT` | 3000 (Next.js), 5173 (Vite), 8000 (FastAPI/Django), 4200 (Angular) | ja |
| `BACKEND_PORT` | 8000 | ja |
| `USE_DOCKER` | `0` | impliciet |
| `DEV_CMD` | `pnpm dev` (Node), `uv run uvicorn ...` (Python+FastAPI), `python manage.py runserver` (Django) | ja |
| `RUNTIME_DIR` | `.task` | impliciet |
| `START_TIMEOUT` | 30 | impliciet |
| `STOP_TIMEOUT` | 15 | impliciet |
| `dotenv` | `['.env.local', '.env']` | impliciet |
| Package manager (Node) | `pnpm` (Brechts default) | ja |
| Package manager (Python) | `uv` | ja |
| Module-set | minimum (`core` + `project`) | ja |

Voor "vermeld in output ja" → toon onderaan de gegenereerde files een korte `# Defaults gebruikt:` lijst zodat gebruiker ze kan overrulen.

---

## §10 — Validatiechecklist

Voor elke gegenereerde of gerefactorde set, run mentaal:

- [ ] Root `Taskfile.yml` is een thin facade (forwards-only, geen logica)
- [ ] `silent: true` op file-niveau in elke yml
- [ ] User-facing tasks (`help`, `default`, `start`, `stop`, `restart`, `status`, `doctor`) hebben `silent: false`
- [ ] Internal tasks hebben `_prefix` ÉN `internal: true`
- [ ] `dotenv: ['.env.local', '.env']` in root Taskfile.yml
- [ ] `default` task → `task: help`
- [ ] `help` toont mode + url (lokaal + vpn) + ports + lifecycle commands
- [ ] `core:start` doet `_ensure-dirs` → `_ensure-ready` → `_bootstrap-env` → `_start-impl` → `_wait-for-endpoint` → `_show-endpoints`
- [ ] `_kill-mode` heeft PID → fuser fallback
- [ ] `_show-endpoints` heeft multi-iface VPN-detectie (niet alleen tun0)
- [ ] `doctor` task aanwezig en checkt tooling + env
- [ ] `setup` task aanwezig
- [ ] Geen hardcoded HOME-paden of server-namen in vars
- [ ] Geen mixed naming (`kebab` vs `snake_case` vs `camelCase`)
- [ ] Geen file >500 regels (zonder includes)
- [ ] `.env.example` aanwezig of expliciet vermeld als TODO
- [ ] Shell-blokken hebben proper exit-codes (`exit 0` / `|| true` waar nodig)
- [ ] Geen secrets in vars of cmds

**gosh-safety checks (kritiek):**

- [ ] **Geen `echo $! > pid_file` patronen** — PID wordt gelezen via `fuser PORT/tcp` na `_wait-for-endpoint` (AP-21)
- [ ] **Geen plain `kill` voor extern gestarte processen** — gebruik `/bin/kill` expliciet (AP-22)
- [ ] **Geen `ss` voor port-checks** — gebruik `fuser -n tcp PORT` of `lsof -i :PORT` (AP-23)
- [ ] **Next.js DEV_CMD/PROD_CMD heeft `--port {{.PORT}}` als CLI-flag**, niet alleen `PORT` env (AP-24)
- [ ] **Bij PM2-projecten**: `_kill-mode` doet PM2-parentage detect vóór fuser-kill (AP-25)
- [ ] **Header-comment** boven `start:` en `_kill-mode:` met "gosh-safe" toelichting

**Calcport-integratie checks (verplicht voor alle generaties):**

- [ ] **Geen hardcoded poort-vars** als calcport beschikbaar is (regex `_PORT:\s*['"]?\d+` mag niet matchen) (AP-26)
- [ ] **Port-vars gebruiken `sh:`-blok** dat `ports.json` leest met fallback naar `calcport` en hardcoded default
- [ ] **`task ports` command aanwezig** — toont `ports.json` of runt `calcport` als fallback (AP-27)
- [ ] **`calcport` in doctor required-tools** (AP-27)
- [ ] **`PORTS_FILE` var aanwezig** met default `'ports.json'`
- [ ] **Bij NEW project zonder ports.json**: skill heeft `calcport` aangeraden of een minimale `ports.json` gegenereerd

Toon checklist-resultaat aan gebruiker. Falen = blokkeren tot opgelost.

---

## §11 — Werkende mini-templates

### Template — root `Taskfile.yml` (Pattern A)

```yaml
version: '3'
silent: true
dotenv: ['.env.local', '.env']

includes:
  core:
    taskfile: ./taskfiles/core.yml
    optional: false
  project:
    taskfile: ./taskfiles/project.yml
    optional: true
  # uncomment indien gewenst:
  # db:
  #   taskfile: ./taskfiles/db.yml
  #   optional: true
  # docker:
  #   taskfile: ./taskfiles/docker.yml
  #   optional: true

tasks:
  default:
    desc: Show help
    silent: false
    cmds:
      - task: core:help

  help:
    desc: Show help
    silent: false
    cmds:
      - task: core:help

  start:    { desc: Start app,           cmds: [task: core:start] }
  stop:     { desc: Stop app,            cmds: [task: core:stop] }
  restart:  { desc: Restart app,         cmds: [task: core:restart] }
  logs:     { desc: Tail logs,           cmds: [task: core:logs] }
  status:   { desc: Runtime status,      cmds: [task: core:status] }
  doctor:   { desc: Diagnose,            cmds: [task: core:doctor] }
  setup:    { desc: First-time setup,    cmds: [task: project:setup] }

  install:    { desc: Install deps,    cmds: [task: project:install] }
  build:      { desc: Production build, cmds: [task: project:build] }
  test:       { desc: Run tests,        cmds: [task: project:test] }
  lint:       { desc: Lint,             cmds: [task: project:lint] }
  typecheck:  { desc: Typecheck,        cmds: [task: project:typecheck] }
  check:      { desc: Lint + typecheck, cmds: [task: project:check] }
```

### Template — `taskfiles/core.yml`

**Niet inline — gebruik altijd `references/canonical/taskfiles/core.yml` als drop-in basis.** De inline skeleton in §4 is alleen een fallback wanneer die referentie niet beschikbaar is. Lees de volledige 774-regel canonieke versie en pas customization-checklist uit `references/README.md` toe.

### Template — `taskfiles/project.yml` (stub)

```yaml
version: '3'
silent: true

tasks:
  setup:
    desc: First-time setup
    cmds:
      - <package-manager> install
      # bv. pnpm install / uv sync / poetry install

  install:
    desc: Install dependencies
    cmds:
      - <package-manager> install

  build:
    desc: Production build
    cmds:
      - <package-manager> build

  test:
    desc: Run tests
    cmds:
      - <package-manager> test

  lint:
    desc: Lint code
    cmds:
      - <package-manager> lint

  typecheck:
    desc: Typecheck
    cmds:
      - <package-manager> typecheck

  check:
    desc: Lint + typecheck
    cmds:
      - task: lint
      - task: typecheck

  doctor:
    desc: Stack-specific checks (called by core:doctor)
    cmds:
      - command -v <package-manager>
      # vul aan met stack-specifieke tool checks
```

### Template — Pattern D minimaal (clasp-stijl)

```yaml
version: '3'
silent: true
dotenv: ['.env.local', '.env']

vars:
  CLASP_AUTH: '{{default "$HOME/.clasprc.json" .CLASP_AUTH}}'

tasks:
  default:
    desc: Show help
    silent: false
    cmds:
      - task: help

  help:
    desc: Show help
    silent: false
    cmds:
      - |
        cat << 'EOF'
        === <project-name> ===

        Commands:
          task push     push to Apps Script
          task pull     pull from Apps Script
          task open     open in browser
          task deploy   create new version
        EOF

  push:    { desc: Push to GAS,   cmds: ["clasp push --auth {{.CLASP_AUTH}}"] }
  pull:    { desc: Pull from GAS, cmds: ["clasp pull --auth {{.CLASP_AUTH}}"] }
  open:    { desc: Open in IDE,   cmds: ["clasp open --auth {{.CLASP_AUTH}}"] }
  deploy:  { desc: Deploy,        cmds: ["clasp deploy --auth {{.CLASP_AUTH}}"] }
```

### Template — `doctor:` task (rich)

```yaml
doctor:
  desc: Diagnose tooling and env
  silent: false
  cmds:
    - |
      FAIL=0; WARN=0
      ok()   { printf "\033[32m[OK]\033[0m %s\n" "$1"; }
      bad()  { printf "\033[31m[X]\033[0m  %s\n" "$1"; FAIL=$((FAIL+1)); }
      warn() { printf "\033[1;33m[!]\033[0m  %s\n" "$1"; WARN=$((WARN+1)); }
      need() { command -v "$1" >/dev/null 2>&1 && ok "$1" || bad "$1 ontbreekt"; }
      maybe(){ command -v "$1" >/dev/null 2>&1 && ok "$1" || warn "$1 ontbreekt (optioneel)"; }

      printf "\033[1;36m=== TOOLING ===\033[0m\n"
      need task; need git
      need pnpm    # of uv / poetry afh. van stack
      maybe docker

      printf "\n\033[1;36m=== ENV ===\033[0m\n"
      [ -f .env.local ] && ok ".env.local" || warn ".env.local ontbreekt"
      [ -f .env.example ] && ok ".env.example" || warn ".env.example ontbreekt"

      printf "\n\033[1;36m=== RUNTIME ===\033[0m\n"
      [ -d .task ] && ok ".task/ runtime dir" || warn ".task/ ontbreekt (wordt aangemaakt bij start)"

      printf "\n"
      [ "$FAIL" -gt 0 ] && printf "\033[31m%d critical issues\033[0m\n" "$FAIL" && exit 1
      [ "$WARN" -gt 0 ] && printf "\033[1;33m%d warnings\033[0m\n" "$WARN"
      printf "\033[32mDoctor: OK\033[0m\n"
```

### Template — dynamische help-renderer (printf-stijl)

```yaml
help:
  desc: Show help with dynamic context
  silent: false
  env:
    _APP_NAME: '{{.APP_NAME}}'
    _PORT: '{{.FRONTEND_PORT}}'
    _USE_DOCKER: '{{.USE_DOCKER}}'
  cmds:
    - task: _show-endpoints
    - |
      MODE=$( [ "${_USE_DOCKER}" = "1" ] && echo docker || echo local )
      printf "\033[1;36m=== %s ===\033[0m\n" "${_APP_NAME}"
      printf "\033[1mmode:\033[0m   %s\n" "$MODE"
      printf "\033[1mport:\033[0m   %s\n\n" "${_PORT}"
      printf "\033[1;33mLifecycle:\033[0m\n"
      printf "  \033[32mtask start\033[0m       start app\n"
      printf "  \033[32mtask stop\033[0m        stop app\n"
      printf "  \033[32mtask restart\033[0m     restart\n"
      printf "  \033[32mtask logs\033[0m        tail logs\n"
      printf "  \033[32mtask status\033[0m      status\n"
      printf "  \033[32mtask doctor\033[0m      diagnose\n\n"
      printf "\033[1;33mDevelopment:\033[0m\n"
      printf "  \033[32mtask install\033[0m     install deps\n"
      printf "  \033[32mtask build\033[0m       production build\n"
      printf "  \033[32mtask test\033[0m        run tests\n"
      printf "  \033[32mtask lint\033[0m        lint\n"
      printf "  \033[32mtask check\033[0m       lint + typecheck\n"
```

### Template — `taskfiles/db.yml` (Prisma)

```yaml
version: '3'
silent: true

tasks:
  generate: { desc: Prisma generate,           cmds: [pnpm db:generate] }
  migrate:  { desc: Prisma migrate dev,        cmds: [pnpm db:migrate] }
  push:     { desc: Prisma db push,            cmds: [pnpm db:push] }
  studio:   { desc: Open Prisma Studio,        cmds: [pnpm db:studio] }
  seed:     { desc: Seed database,             cmds: [pnpm db:seed] }
  reset:    { desc: Reset database (destructive!), cmds: [pnpm db:reset] }
  deploy:   { desc: Migrate deploy (production), cmds: [pnpm db:deploy] }
```

### Template — `taskfiles/docker.yml` (multi-env)

```yaml
version: '3'
silent: true

tasks:
  dev:
    desc: Start dev compose
    cmds:
      - docker compose -f docker-compose.yml up -d --build

  prod:
    desc: Start prod compose (registry image)
    cmds:
      - docker compose -f docker-compose.prod.yml up -d

  local:
    desc: Start prod with local build
    cmds:
      - docker compose -f docker-compose.prod.local.yml up -d --build

  status:
    desc: Show status across compose-files
    cmds:
      - docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

  stop:
    desc: Stop all compose envs
    cmds:
      - |
        for f in docker-compose.yml docker-compose.prod.yml docker-compose.prod.local.yml; do
          [ -f "$f" ] && docker compose -f "$f" down 2>/dev/null || true
        done

  logs:
    desc: Tail logs of active compose
    cmds:
      - docker compose logs -f
```

---

## §12 — Niet doen (hard NO)

De skill mag NOOIT:

- Gen-1 of gen-2 core.yml-structuur produceren (zonder `_ensure-ready`/`_kill-mode`/`_wait-for-endpoint`/`_show-endpoints`/`_bootstrap-env`)
- `tun0` hardcoderen als enige VPN-interface check
- `dotenv: ['.env', '.env.local']` zetten (override wint dan niet)
- Internal tasks zichtbaar laten (= zonder `internal: true`)
- Een single-file Taskfile produceren >500 regels voor een app-repo met start/stop
- Een mega-alias-sectie (>50 regels) toevoegen bij refactor
- Vage "// pas dit aan naar wens"-templates afleveren zonder werkende default
- Een task aanmaken met `silent: true` per task terwijl er geen file-level default staat
- Vragen welke `silent`-instelling de gebruiker wil (vast geregeld)
- Vragen welke runtime-dir (vast `.task/`)
- Hardcoded HOME-paden of server-namen in vars
- Een Pattern C/D Taskfile produceren voor een app met runtime-toggle
- Taskfile produceren zonder `default → help`
- Taskfile produceren zonder `doctor:` task voor een app-repo
- `silent: false` vergeten op `help` of `start`/`stop`/`status` (anders ziet gebruiker niets)
- Backward-compat aliases produceren voor refactor zonder ze te beperken tot max 5

---

## §13 — Test-prompts (validatieset voor de skill)

Twaalf prompts om de skill te valideren. Verwachte output-eigenschap staat erbij.

### AUTO (default) — meest voorkomend

1. **AUTO leeg project** — *"Setup mijn Python repo `python_invoer`."* (geen Taskfile aanwezig) → AUTO detecteert via `pyproject.toml` → kiest **NEW** + Python profile → vraagt alleen `APP_MODULE` + ports indien geen `ports.json` → genereert files.

2. **AUTO bestaande gold-standard** — *"Kijk eens naar mijn Taskfile."* (file scoort 92) → AUTO toont AUDIT-output, **doet niets**, zegt "no action needed".

3. **AUTO bestaande met punctuele issues** — *"Fix mijn taskfile."* (file scoort 80, 3 punctuele issues) → AUTO kiest **FIX**, toont 3 diffs met before/after, gaat door.

4. **AUTO verouderd Taskfile** — *"Kun je deze opfrissen?"* (file scoort 60, gen-2, naming-mix, hardcoded ports) → AUTO kiest **STANDAARD**, toont plan met ~12 wijzigingen, vraagt confirm.

5. **AUTO single-file 1180 regels** — *"Kun je deze opruimen?"* → AUTO kiest **STANDAARD + REFACTOR**, toont plan + impact, vraagt confirm, bewaart legacy in `.archive/`.

### NEW (forced)

6. **NEW Next.js** — *"Maak een Taskfile-setup voor een nieuwe Next.js app `klasspiegels-v2` met Prisma, lokaal+docker toggle."* → Pattern A + db.yml + docker.yml + gen-3 core; ports uit calcport.

7. **NEW Python full-stack** — *"Setup voor `python_factuur` (FastAPI backend + Vite frontend), uv."* → Pattern A met `taskfiles/frontend.yml` als optional include + multi-service patterns uit references/patterns.

8. **NEW Clasp minimaal** — *"Maak een Taskfile voor `clasp_kalenderhulp` (alleen clasp push/pull/open/deploy)."* → Pattern D, 5 commands, heredoc-help, `CLASP_AUTH` var.

### AUDIT (forced read-only)

9. **AUDIT** — *"Audit deze Taskfile [paste]"* → Score op 100, top-5 findings met regelnummers + concrete fixes, klasse (gold/solid/refactor/herstructureren). Geen schrijfacties.

### FIX (specifiek probleem)

10. **FIX VPN-detect** — *"VPN-detectie pakt mijn wg0 niet."* → Lokaliseer VPN-detect-block, vervang met multi-iface uit §4. Toon diff. Suggereer 1-2 vergelijkbare problemen (bv. doctor mist nmcli check).

### STANDAARD (forced bulk)

11. **STANDAARD** — *"Maak deze Taskfile volledig standaard."* → Discovery + plan met alle afwijkingen + confirm + apply-all + BREAKING.md voor renamed tasks.

### REFACTOR (specifiek target)

12. **REFACTOR gen2→gen3** — *"Mijn core.yml mist `_ensure-ready` en `_wait-for-endpoint`. Upgrade naar gen-3."* → Voeg de 5 building blocks toe, behoud bestaande project-vars-overrides. **Geen** drift-correcties of naming-fixes meebrengen — dat is STANDAARD-territorium.

---

## Extra bestanden / snippets voor latere uitbreiding

**Al aanwezig naast deze skill** (zie `references/README.md`):

- `references/canonical/Taskfile.yml` — thin facade root (drop-in)
- `references/canonical/taskfiles/core.yml` — 774 regels gen-3 core.yml (drop-in)
- `references/canonical/taskfiles/project.yml` — Next.js stack-specifieke project.yml
- `references/patterns/core-multi-service.yml` — backend+frontend parallel + PGID-kill
- `references/patterns/core-shared-server-safe.yml` — `stop_if_owned` voor gedeelde hosts
- `references/patterns/core-prod-pipeline.yml` — parallelle prod-stack + externe scripts

**Profile-templates** (in `references/profiles/`):

- `python/` — FastAPI/uvicorn + uv + ruff + pytest. Drop-in trio. Calcport-driven ports. ✅ klaar.

**Nog te maken bij v2 van de skill**:

- `references/profiles/clasp/` — gen-3 met `CLASP_AUTH` dynamic-from-`.clasp.profile`
- `references/profile-vscode-ext.yml` — TS-watcher als achtergrondservice
- `references/anti-patterns-extended.md` — before/after per anti-pattern
- `references/refactor-d-to-a.md` — stap-voor-stap migratie-script
- `references/audit-output-format.md` — exacte JSON-structuur voor audit-rapport
- `validators/validate-taskfile.sh` — bash-script dat §10 *Validatiechecklist* automatisch run
- `references/decision-tree-mermaid.md` — mermaid-diagram van §2 voor visuele referentie

Geen van de v2-uitbreidingen zijn noodzakelijk voor v1. Toevoegen wanneer de skill in praktijk knelt op specifieke punten.

---

## Werkmodus-samenvatting voor Claude

Wanneer geactiveerd:

1. **Default = AUTO.** Ga naar §0. Stel geen openings-vraag "welke modus?".
2. Alleen als user expliciet een modus benoemt (Activatie-tabel), ga je direct naar de bijhorende §.
3. Volg de §-flow strikt. Hard rules (§4 building blocks, §10 validatiechecklist, §12 niet-doen) zijn niet onderhandelbaar.
4. Confirmation-gates respecteren:
   - AUDIT/NEW/FIX = ga door zonder uitgebreid checken
   - STANDAARD/REFACTOR = toon plan vooraf, vraag expliciet confirm
5. Toon altijd onderaan **één concrete volgende stap** ("run `task doctor`", "commit deze 3 files", "test met `task start`"). Niet meer dan één.
6. Bij twijfel over een var/keuze: kies de meest robuuste default uit §9 *Fallbackgedrag* en vermeld het in output.
7. Bij conflict tussen gebruikers-voorkeur en hard rule: leg uit waarom de hard rule geldt en bied de alternatieve oplossing binnen de regels.
8. ADD-vriendelijk: weinig vragen, veel momentum. Liever proberen + tonen dan questionnaires.
