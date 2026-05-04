<!-- v1.1.1 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

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
| AP-12 | Geen `doctor:` task **als root-shortcut** (niet alleen `core:doctor`) | medium |
| AP-13 | Geen `default:` of `default → help` ontbreekt | medium |
| AP-14 | Geen `setup:` task **als root-shortcut** (niet alleen `core:setup`) | medium |
| AP-15 | Gen-1 of gen-2 core.yml structuur (geen `_ensure-ready`/`_kill-mode`/`_wait-for-endpoint`) | medium |
| AP-16 | `.task/`, `.taskrun/`, `.run/` mix binnen project | laag |
| AP-17 | Hardcoded paden naar HOME of repo-root | hoog |
| AP-18 | Ontbrekende `_bootstrap-env` (geen `.env.example` → `.env.local` fallback) | medium |
| AP-19 | Geen exit-codes / fout-propagatie in shell-blokken | hoog |
| AP-20 | Files > 700 regels zonder includes | hoog |
| AP-21 | `$!` als PID-bron in cmd-blok (go-task gosh-bug) | **hoog** |
| AP-22 | Plain `kill` (shell-builtin) voor extern gestarte processen | **hoog** |
| AP-23 | `ss` voor port-checks (alias-conflict, output-format-onbetrouwbaar) | medium |
| AP-24 | Next.js zonder `--port` CLI-flag — in **Taskfile DEV_CMD** of in **sub-project `package.json` scripts** | **hoog** |
| AP-25 | Geen PM2-detectie in `_kill-mode` als project PM2 gebruikt (PM2 respawnt anders) | medium |
| AP-26 | Hardcoded ports in vars terwijl `calcport` beschikbaar is OF `ports.json` ontbreekt | **hoog** |
| AP-27 | Geen `task ports` command + geen `calcport` in doctor-checks | medium |
| AP-28 | Twee+ services claimen dezelfde port-waarde (cross-language port-conflict) | **hoog** |

Bij audit toon je gevonden anti-patterns met regelnummer + concrete fix.

### Toelichting bij AP-12 / AP-13 / AP-14 — Pattern A root-facade compleetheid

In Pattern A is de root `Taskfile.yml` een **thin facade** die forwarded naar `core:*` en `project:*`. Gebruikers typen altijd `task <command>` vanuit de root — nooit `task core:<command>` of `task project:<command>`.

**Detectie-regel** (aangescherpt in v1.1.1):

Een task telt alleen als "aanwezig" wanneer hij **als root-shortcut** beschikbaar is. `core:doctor` of `project:setup` op zichzelf is **niet voldoende** — er moet een corresponderende top-level entry in de root `Taskfile.yml` staan die ernaar forwarded.

**Fout (AP-12 triggert ondanks `core:doctor`):**

```yaml
# Taskfile.yml (root) — geen 'doctor:' shortcut
includes:
  core: { taskfile: ./taskfiles/core.yml }
tasks:
  start: { cmds: [task: core:start] }
  stop:  { cmds: [task: core:stop] }
  # ← doctor ontbreekt; gebruiker krijgt "Task 'doctor' does not exist"
```

**Goed:**

```yaml
tasks:
  start:  { cmds: [task: core:start] }
  stop:   { cmds: [task: core:stop] }
  doctor: { cmds: [task: core:doctor] }   # ← verplicht
  setup:  { cmds: [task: core:setup] }    # ← verplicht
```

**Verplichte root-shortcuts per profile** (zie `docs/profiles.md` "Verplicht"-lijst per profile). De skill mag een profile pas als compleet gegenereerd beschouwen wanneer **alle** items uit de "Verplicht"-lijst als root-shortcut bestaan, niet alleen via include indirect bereikbaar zijn.

**Validatie:** zie `docs/validation-checklist.md` — de root-shortcut-check is sinds v1.1.1 verplicht onderdeel van elke generatie/refactor.

---

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

**AP-24 — Next.js negeert `PORT` env (in Taskfile DEV_CMD ÉN in sub-project package.json scripts).**

`next dev` valt terug op default 3000 (en daarna 3001/3002/3003 als bezet) als je niet expliciet `--port` als CLI-flag meegeeft. `PORT=25050 pnpm dev` werkt **niet**.

**Detectie heeft twee bronnen** — beide checken bij AUDIT/AUTO/STANDAARD:

**1. Taskfile-vars** (`DEV_CMD`/`PROD_CMD` in core.yml of project.yml):

```yaml
DEV_CMD: 'pnpm exec next dev --port {{.DEV_PORT}}'   # ← --port verplicht
PROD_CMD: 'pnpm exec next start --port {{.PROD_PORT}}'
```

**2. Sub-project `package.json` scripts** (mono-repo's met `web/`, `frontend/`, `app/`, `dashboard/` submappen):

Detection-rule:
```
voor elke <subdir>/package.json waar dependencies of devDependencies "next" bevat:
  if scripts.dev mist regex /--port\s+\d+/ → AP-24 (sub-project)
  if scripts.start mist regex /--port\s+\d+/ → AP-24 (sub-project)
```

**Meld als:** `AP-24 (sub-project): web/package.json scripts.dev mist --port flag`

**Fix-patroon (sub-project):**

```diff
// web/package.json
- "dev": "next dev --hostname 127.0.0.1"
+ "dev": "next dev --hostname 127.0.0.1 --port 32224"

- "start": "next start --hostname 127.0.0.1"
+ "start": "next start --hostname 127.0.0.1 --port 32224"
```

**Welke poort kiezen?** Lees `ports.json` in repo-root, kies een sleutel die nog niet door een andere service geclaimd is (`api`, `dashboard`, `docs`, ...) — zie AP-28 voor conflict-detectie. Bij twijfel: voeg een nieuwe sleutel toe via `calcport`.

**Aanvullende suggestie bij FIX**: voeg een Taskfile-task `web:dev` toe die `pnpm --dir web dev` aanroept, zodat de sub-project consistent via `task` start.

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
        python3 -c 'import json; d=json.load(open("{{.PORTS_FILE}}")); print(d.get("standard_d