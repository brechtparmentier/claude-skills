# Taskfile Architect — Brecht Parmentier's conventions

Activeer deze instructies wanneer je een `Taskfile.yml`, `taskfiles/core.yml` of
`taskfiles/project.yml` maakt, auditeert, fixt, standaardiseert of refactort.

**Niet activeren** voor algemene `task` CLI-vragen, Make/just/npm-scripts of
generieke shell-script vragen zonder verband met deze conventies.

---

## Modus-routing (geen vraag stellen, gewoon doen)

| Situatie | Wat doen |
|---|---|
| Geen Taskfile aanwezig | Detecteer stack → genereer (NEW) |
| Taskfile aanwezig, geen specifieke vraag | Audit + auto-fix (AUTO) |
| Eén concreet probleem | FIX: minimale diff |
| "Modernize / maak standaard" | STANDAARD: bulk-upgrade |
| "Splits naar Pattern B" / structurele verandering | REFACTOR |

**Vraag NOOIT als opener "welke modus wil je?"** — AUTO detecteert zelf.

---

## Structuur — Pattern A/B/C/D

```
App met start/stop?
├── Nee, pure CLI-wrapper (<15 cmds)     → PATTERN D (single-file minimaal)
├── Nee, maar meerdere namespaces        → PATTERN C (single-file)
└── Ja
    ├── >2 concern-groepen (db/docker/git/prod)  → PATTERN B (extra includes)
    └── standaard                                → PATTERN A ← DEFAULT
```

**Pattern A** = `Taskfile.yml` (thin facade) + `taskfiles/core.yml` + `taskfiles/project.yml`

Hard rules:
- Single-file > 500 regels → altijd Pattern A, geen uitzonderingen
- App-repo met start/stop → nooit Pattern C of D
- Pure CLI-wrapper → nooit Pattern A

---

## Gen-3 core.yml — verplichte building blocks

Elke core.yml die je produceert moet deze 5 internal tasks bevatten:

| Task | Doel |
|---|---|
| `_ensure-ready` | mtime lockfile ↔ deps marker → auto `task setup` |
| `_kill-mode` | PID → `/bin/kill` → fuser orphan-cleanup op poort |
| `_wait-for-endpoint` | curl-polling met SCHEME-detect, configurable timeout |
| `_show-endpoints` | multi-iface VPN-detectie + lokale + vpn endpoint-test |
| `_bootstrap-env` | `.env.example` → `.env.local` fallback chain |

Gen-1 of gen-2 (zonder deze blocks) produceren is verboden.

---

## gosh-safe patronen (KRITIEK — niet afwijken)

go-task ≥ 3.48 gebruikt gosh als shell-engine. Twee patronen werken anders dan bash:

### AP-21 — `$!` geeft job-ID (`g1`), geen PID

**Fout:**
```yaml
- nohup pnpm dev &
- echo $! > .task/dev.pid   # schrijft "g1" — kapot
```

**Correct:**
```yaml
- task: _wait-for-endpoint
  vars: { PORT: '{{.DEV_PORT}}', SCHEME: http }
- |
  REAL_PID=$(fuser "{{.DEV_PORT}}"/tcp 2>/dev/null | awk '{print $1}')
  [ -z "$REAL_PID" ] && { printf "[ERR] PID niet bepaald\n"; exit 1; }
  echo "$REAL_PID" > "{{.RUNTIME_DIR}}/dev.pid"
```

Verplichte header-comment boven `start:` en `_kill-mode:`:
```yaml
# gosh-safe: vermijdt $! als PID-bron (gebruikt fuser na _wait-for-endpoint)
#            gebruikt /bin/kill expliciet (gosh kill-builtin pakt geen externe PIDs)
```

### AP-22 — `kill` builtin werkt niet voor externe processen

gosh's `kill` ziet alleen eigen jobs. Processen gestart via `nohup ... &` zijn reparented naar systemd.

**Correct — gebruik altijd `/bin/kill` expliciet:**
```yaml
while /bin/kill -0 "$PID" 2>/dev/null && [ "$W" -lt "{{.STOP_TIMEOUT}}" ]; do
  sleep 1; W=$((W+1))
done
/bin/kill -0 "$PID" 2>/dev/null && /bin/kill -KILL "$PID" 2>/dev/null || true
```

### AP-23 — `ss` is onbetrouwbaar (aliased naar smart-search)

Gebruik altijd `fuser PORT/tcp` of `lsof -i :PORT` voor port-checks.

---

## Hard rules (nooit onderhandelen)

- `dotenv: ['.env.local', '.env']` — in deze volgorde (override wint)
- `silent: true` op file-niveau; `silent: false` op user-facing tasks (`help`, `start`, `stop`, `status`)
- `RUNTIME_DIR: .task` (niet `.taskrun`, niet `.run`)
- Internal tasks: `_prefix` ÉN `internal: true`
- Geen hardcoded HOME-paden of server-namen in vars
- `default:` verplicht → `task: help`
- `doctor:` verplicht in elke app-repo
- Nooit `ss -tlnp` voor port-checks
- Nooit `$!` als PID-bron
- Nooit plain `kill` voor extern gestarte processen → altijd `/bin/kill`
- Calcport-integratie verplicht waar `calcport` beschikbaar is

---

## Anti-pattern checklist (run bij elke AUDIT en generatie)

| # | Check | Ernst |
|---|---|---|
| AP-01 | Hardcoded server-naam in vars | hoog |
| AP-02 | `silent: true` per task i.p.v. file-level | medium |
| AP-03 | `_prefix` zonder `internal: true` | medium |
| AP-04 | Alias-sectie > 50 regels | hoog |
| AP-05 | Single-file > 500 regels met lifecycle | hoog |
| AP-07 | `dotenv: ['.env', '.env.local']` (verkeerde volgorde) | hoog |
| AP-08 | Alleen `tun0` als VPN-check | medium |
| AP-10 | `task: core:help` zonder `silent: false` op wrapper | medium |
| AP-12 | Geen `doctor:` task | medium |
| AP-13 | Geen `default:` → help | medium |
| AP-15 | Gen-1/gen-2 core.yml (ontbrekende building blocks) | medium |
| AP-17 | Hardcoded paden naar HOME of repo-root | hoog |
| AP-21 | `$!` als PID-bron (gosh-bug) | **hoog** |
| AP-22 | Plain `kill` voor externe processen (gosh-bug) | **hoog** |
| AP-23 | `ss` voor port-checks (alias-conflict) | medium |
| AP-24 | Next.js zonder `--port` CLI-flag (Taskfile + sub-project package.json) | **hoog** |
| AP-26 | Hardcoded ports zonder `calcport` terwijl beschikbaar | **hoog** |
| AP-28 | Twee+ services claimen dezelfde port-waarde | **hoog** |

Toon gevonden anti-patterns met regelnummer + concrete fix.

---

## Canonieke vars (verplicht in elke app core.yml)

```yaml
vars:
  APP_NAME: '{{default "<app-name>" .APP_NAME}}'
  FRONTEND_PORT: '{{default "<port>" .FRONTEND_PORT}}'   # uit ports.json via calcport
  USE_DOCKER: '{{default "0" .USE_DOCKER}}'
  DEV_CMD: '{{default "<dev-cmd>" .DEV_CMD}}'
  RUNTIME_DIR: '{{default ".task" .RUNTIME_DIR}}'
  LOGS_DIR: '{{default ".task/logs" .LOGS_DIR}}'
  START_TIMEOUT: '{{default "30" .START_TIMEOUT}}'
  STOP_TIMEOUT: '{{default "15" .STOP_TIMEOUT}}'
  GREEN: '\033[32m'
  YELLOW: '\033[1;33m'
  CYAN: '\033[1;36m'
  RED: '\033[31m'
  RESET: '\033[0m'
```

---

## Next.js specifiek (AP-24 — dubbele fix vereist)

`--port` moet op **twee plekken** staan:

1. `DEV_CMD: 'pnpm exec next dev --port {{.DEV_PORT}}'` in Taskfile vars
2. `"dev": "next dev --hostname 127.0.0.1 --port 32224"` in sub-project `package.json`

Next.js negeert `PORT` env volledig — valt terug op 3000/3001/3002 als bezet.
Scan ook `web/`, `frontend/`, `app/`, `dashboard/` sub-mappen op missende `--port`.

---

## Stack-detectie (voor NEW-modus zonder bestaande Taskfile)

| Aanwezige file | Profiel |
|---|---|
| `package.json` met `"next"` dep | Next.js |
| `package.json` met `"engines.vscode"` | VS Code extensie |
| `pyproject.toml` / `requirements.txt` | Python (uv+ruff+pytest) |
| `.clasp.json` | Clasp/Apps Script |
| `ecosystem.config.js` | Server PM2 |
| Alleen `scripts/` folder | CLI toolbelt |
| `package.json` zonder bovenstaande | Node CLI/generic |
