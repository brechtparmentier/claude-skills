# Brecht Taskfile Best Practices

Overzicht van de toegepaste Taskfile-aanpakken in deze verzameling, gegroepeerd per setup-type, met per type de meest betrouwbare 'gold standard' aangeduid. Bedoeld als input voor een toekomstige skill die nieuwe Taskfiles consistent kan opzetten.

---

## 1. De vier hoofdpatronen

| Pattern | Vorm | Wanneer | Voorbeelden |
|---|---|---|---|
| **A — Thin facade + core + project** | `Taskfile.yml` (forwards-only) + `taskfiles/core.yml` + `taskfiles/project.yml` | Default voor app-repo's met runtime (start/stop/logs/status) | `nextjs_klasspiegelsMVP`, `python_leerlokaalFV`, `Leerlokaal-Doelen-Verzamelen` |
| **B — Multi-namespace split** | Pattern A + extra includes (`db.yml`, `docker.yml`, `native.yml`, `prod.yml`, `demo.yml`, `git.yml`, ...) | Apps met meerdere distincte concern-groepen (database, productie, demo, ci) | `python_rubricsObservatieTool` (optiplex), `clasp_kalendertoolv202601`, `vscodeExt_combineFilesToOne`, `smart-search` |
| **C — Single-file met namespaces** | Eén `Taskfile.yml` gestructureerd in `name:colon` namespaces | Tools/scripts zonder runtime-toggle, of vroege-fase apps | `tools_NASManager`, `codeql-advisor`, `tools_ufw`, `ai_centralAImonitoring`, `_linodeServerBeheer` |
| **D — Single-file minimaal** | Eén Taskfile met 5-15 simpele tasks zonder namespaces | Pure CLI-wrappers (clasp push/pull, audit-scripts) | `clasp_*`, `tools_taskfile-silent`, `tools_googleWorkspaceGetActiveMailboxes` |

**Vuistregel voor patroon-keuze:** zodra je een runtime-toggle (docker vs lokaal) hebt OF >500 regels Taskfile, ga je van C → A. Zodra je distincte taakcategorieën krijgt waarbij sommige optioneel zijn (db alleen als prisma aanwezig is), ga je van A → B.

---

## 2. Drie generaties van `core.yml` (cruciaal inzicht)

Het split-file patroon is in de loop der tijd door drie evoluties gegaan. De gen-3 versie is de gold standard.

### Gen-1 — "thin USE_DOCKER toggle"

Locatie: `linux-pagaaier/webportaal_devHubTools`, oude versies van `nextjs_klasspiegelsMVP`.

- Vars: `APP_NAME`, `FRONTEND_PORT`, `USE_DOCKER`, `DEV_CMD`, `DOCKER_SERVICE`, `VPN_IP`
- VPN-detectie alleen via `tun0` met één regex
- Runtime PID/log management heel simpel (`.task/dev.pid`)
- ~120 regels, dunne abstractie

### Gen-2 — "USE_DOCKER + pluggable lifecycle commands"

Locatie: `linuxoptiplexvpn/nextjs_klasspiegelsMVP`, `linodeserver/wireguardTool`.

- Voegt pluggable `STOP_CMD`, `RESTART_CMD`, `LOGS_CMD`, `STATUS_CMD` toe (env-overridable)
- VPN-detectie via geneste functies met fallbacks (tun0 → ifconfig 10.x)
- Apart `_ensure_runtime_dirs` internal task
- ~225 regels

### Gen-3 — "Full lifecycle, PID-managed, waited-startup, multi-iface VPN"

Locatie: `linuxoptiplexvpn/nextjs_frontend-gdriverights`, `linuxoptiplexvpn/clasp_kalendertoolv202601`.

- Eigen vars: `RUNTIME_DIR`, `LOGS_DIR`, expliciete PID/PGID-bestanden per service, `START_TIMEOUT`, `STOP_TIMEOUT`
- `_kill-mode` doet PID-bestand → `fuser` orphan-cleanup (cruciaal voor pnpm/next-dev die orphan child processes laten staan)
- `_wait-for-endpoint` doet curl-polling met SCHEME-detect zodat "started"-feedback betekenisvol is
- `_show-endpoints` doet multi-interface VPN-detectie: nmcli → tun/wg/tailscale/zt → 10.x fallback → openssl SAN-check voor https
- `_ensure-ready` doet **auto-setup-detection**: vergelijkt mtime van `package.json`/`pnpm-lock.yaml` met `node_modules/.modules.yaml` en triggert auto `task setup` als out-of-date
- HTTPS-aware status-check, sudo-prompt awareness voor cert-installs
- `_bootstrap-env` met `.env.example` → `.env.local` fallback chain
- ~700 regels, maar bijna alle complexiteit zit in 4-5 reusable internal building blocks

**Voor de skill:** start altijd vanaf gen-3 als template. De internal tasks `_ensure-ready`, `_kill-mode`, `_wait-for-endpoint`, `_show-endpoints`, `_bootstrap-env` zijn "5 reusable building blocks" die een groot deel van de operationele kwaliteit dragen.

---

## 3. Per project-type: gold standard

### Next.js apps

**Gold:** `linuxoptiplexvpn/nextjs_frontend-gdriverights/`

Gebruikt gen-3 core.yml met alle building blocks. Heeft daarnaast rijke set lifecycle-aliases (`start-frontend`, `restart-frontend`) die verschillende mental models bedienen.

**Aanvullend interessant:** `linuxoptiplexvpn/nextjs_klasspiegelsMVP/Taskfile.yml` voegt `db.yml` als apart include toe en bevat een **multi-environment Docker-namespace** (`docker:dev` 6180, `docker:prod` 44385, `docker:local`, `docker:latest` 44386, `docker:v17` 28684) — dat patroon (1 compose-file per omgeving, 1 task per file) is nuttig om naar de gold-template over te zetten.

**Anti-pattern in deze categorie:** `nextjs_garagebox` (1180 regels single-file) — heeft duidelijk een verstopte gen-2 lifecycle-laag (start/stop/restart/logs/status met 3 backends: pm2-dev/pm2-prod/docker) die zou moeten worden geëxtrueerd naar `core.yml`.

### Python apps

**Gold:** `linuxoptiplexvpn/python_rubricsObservatieTool/`

Meest gerijpte pattern-B split met aparte `native.yml`, `docker.yml`, `prod.yml`, `demo.yml`, `monitoring.yml` includes. Versioneer-bewust ("Gegenereerd via M3 Taskfile Suite v3.0.0").

**Voor mindere complexiteit:** `linuxoptiplexvpn/python_leerlokaalFV/` — backend+frontend met `_start_api` + `_start_frontend` als internal tasks, compactere versie van hetzelfde patroon.

**Anti-pattern in deze repo:** ~250 regels backward-compat aliases-sectie wordt onderhoudslast — bewust vermijden in de skill.

### Tools / CLI scripts

**Gold (single-file):** `linuxoptiplexvpn/tools_ufw/Taskfile.yml`

625 regels uitstekend gestructureerd: `gui:*` namespace, parametriseerbaar `GUI_SUDO=`, fallback-chains voor lint/format (ruff → pylint → flake8), `s/x/r/st/l` shortcut-aliases, helder doctor.

**Eervolle vermeldingen:** `tools_NASManager` en `codeql-advisor` voor heredoc-help (`cat << 'EOF'` met box-drawing chars i.p.v. printf-hell).

### Clasp / Google Apps Script

**Gold (full-stack):** `linuxoptiplexvpn/clasp_kalendertoolv202601/`

Split-file met FastAPI backend + Vite frontend lifecycle naast elkaar; `CLASP_AUTH` dynamisch berekend uit `.clasp.profile` zodat profielen-per-project werken; aparte prod ports en prod-stack.

**Gold (zonder stack):** `linuxoptiplexvpn/digiSchoolKalender2526GKOK/Taskfile.yml` — 5 commands, single-file, perfect minimaal pattern-D.

### VS Code Extensions

**Gold:** `linuxoptiplexvpn/vscodeExt_combineFilesToOne/`

Split-file met clean 3-namespace structuur:
- `core.yml` — TS watcher als achtergrondservice (start/stop/restart/logs/status)
- `dev.yml` — compile/lint/test/package/publish
- `git.yml` — branch/pr/merge/promote/publish workflow

Schoonst voorbeeld van scheiding "infrastructuur — productie-werk — release-werk".

### AI tools / monitoring

**Gold:** `linux-pagaaier/ai_centralAImonitoring/Taskfile.yml`

Single-file pattern-C; `_build-runtime`, `_start-agent`, `_start-dashboard` als internal tasks; expliciete `lsof`-based port-detectie; curl health-checks. Mist alleen de `doctor` + `status`-integratie van gen-3.

### Server beheer

**Gold (PM2 services):** `linodeserver/wireguardTool/` — compact, to-the-point, doctor-loos maar daar is het use-case voor.

**Gold (multi-script wrapper):** `linodeserver/_linodeServerBeheer/Taskfile.yml` — wrappert ~30 scripts.
**Verbetering nodig in skill:** namespacen. Alle `vpn-*`, `nginx-*`, `backup-*`, `security-*`, `docker-*` taken zouden `vpn:*`, `nginx:*`, ... moeten worden. Anders wordt `task --list` onbruikbaar.

### Specials

- **`smart-search`** — namespace-zware single-root + `.taskfiles/Taskfile.config.yml` en submodulen. Uniek: `set: [errexit, pipefail, nounset]` (POSIX-strict) — geen andere repo doet dit, en het is een waardevolle gem die in nieuwe templates standaard moet.
- **`repo-workspace`** — `service:install`-flow voor user-systemd, `task-runtime.sh` als externe runtime-helper voor multi-service orchestration. Patroon om aan te bevelen wanneer het project in een systemd unit moet draaien.
- **`_linuxTools`** — root-niveau Taskfile dat per sub-project een aparte workspace bundelt; meta-pattern voor "verzameling van projecten als één toolbelt".

---

## 4. Cross-cutting best practices

### 4.1 VPN/IP-detectie (gold uit gen-3 `_show-endpoints`)

Zoek in volgorde:
1. `nmcli` — connected wireguard|vpn|tun|tap interface
2. `ip -o -4 addr` op `tun|tap|wg|tailscale|ppp|utun|zt|vpn` interfaces
3. `ip -o -4 addr` met RFC1918-filter, exclude `lo|docker|br-|veth|virbr|en|eth|wl|wwan`
4. Specifieke fallback op 10.0.0.x
5. **`VPN_IP` env-override** als handmatige escape hatch

Te vermijden: alleen `ip addr show tun0` — faalt op wireguard `wg0` of tailscale.

### 4.2 Internal-tasks markering

Gebruik **beide tegelijk**: `internal: true` (verbergt uit `task --list`) PLUS `_prefix` op de naam (visuele markering in source). Gen-3 doet dit consistent. Sommige oudere repos hebben alleen `_prefix` zonder `internal: true` — taken blijven dan zichtbaar in `--list-all`.

### 4.3 `silent` flags

`silent: true` op file-niveau, `silent: false` selectief op taken die feedback nodig hebben (`help`, `default`, `start`, `stop`, `restart`, `status`, `doctor`). De anti-pattern (zie `_linodeServerBeheer`) is `silent: true` per task overal heen schrijven i.p.v. één file-level default.

### 4.4 dotenv volgorde

`dotenv: ['.env.local', '.env']` — eerste-bestand wint, en `.env.local` is de override. De omgekeerde volgorde (gangbaarder gezien) is fout. `linuxoptiplexvpn/nextjs_klasspiegelsMVP` heeft het correct.

### 4.5 `.env.example` bootstrap

Gen-3 `_bootstrap-env`: als `.env.local` niet bestaat, kopieer `.env.example` ernaar. Voorkomt setup-frictie. Standaard maken in skill.

### 4.6 Help-rendering: twee stijlen, beide valide

| Stijl | Source-leesbaarheid | Dynamische content |
|---|---|---|
| `cat << 'EOF'` heredoc met box-drawing chars | Hoog | Beperkt (statisch) |
| `printf "\033[..."` per regel met `{{.COLOR}}` vars | Lager | Hoog (mode/url/port in header) |

Aanbeveling: **printf-stijl** wanneer help dynamische context wil tonen (USE_DOCKER mode, VPN-detected url, ports), **heredoc** wanneer puur statisch.

### 4.7 Default + help

Standaard: `default:` doet `task: help`. `help:` in root forward naar `task: core:help` (split-file) of inline (single-file).

### 4.8 Docker vs lokaal abstractie

`USE_DOCKER=0/1` toggle in core.yml is helder. Default = `0`. Voor docker-only projecten zet `USE_DOCKER: '1'` als fixed var in de root Taskfile.yml; voor lokaal-only laat het op `0`.

### 4.9 Runtime directory naming

Gebruik `.task/`. Drift bestaat (`.taskrun/`, `.run/`) maar `.task/` is dominant en convention.

### 4.10 Task-naming conventies

- **Lifecycle**: plain `kebab-case` (`start`, `stop`, `restart`, `logs`, `status`, `doctor`, `setup`, `clean`)
- **Namespaces**: `kebab:colon-case` (`db:migrate`, `docker:up`, `gh:issue`, `prod:deploy`)
- **Internal**: `_kebab-case` (`_show-endpoints`, `_ensure-ready`)

Niet mixen met `snake_case` in dezelfde repo.

---

## 5. Anti-patterns (vermijden in skill)

| Anti-pattern | Voorbeeld in collectie |
|---|---|
| Hardcoded server-naam in een var | `python_rubricsObservatieTool` met `PROD_HOST: 'linuxpagaaiervpn'` |
| `silent: true` per task overal i.p.v. file-level default | `_linodeServerBeheer` |
| `_prefix` zonder `internal: true` | `webportaal_devHubTools` optiplex `_ensure_runtime_dirs` |
| Massive backward-compat alias-sectie | `python_rubricsObservatieTool` optiplex (~250 regels aliases) |
| Single-file >500 regels met verstopte lifecycle-laag | `nextjs_garagebox` (1180 regels) |
| Plain task-namen voor 30 server-scripts (geen namespacing) | `_linodeServerBeheer` (`vpn-add`, `nginx-collect`, ...) |
| dotenv-volgorde `['.env', '.env.local']` (override wint niet) | komt op meerdere plaatsen voor |
| Alleen `tun0` als VPN-interface check | gen-1 core.yml |
| ANSI-codes inconsistent gemixt (`{{.GREEN}}` vars vs hardcoded `\033[32m`) | drift door collectie |
| `task: core:help` zonder `silent: false` op de wrapper-task → help in silent mode | vroege `wireguardTool` |
| Mixed naming binnen één repo (`build:docker-full`, `setup:venv`, `installDeps`) | meerdere |

---

## 6. Skill-bouwstenen (concrete aanbevelingen)

1. **Default = pattern A** (thin facade + core.yml + project.yml). Optionele namespace-includes (`db.yml`, `docker.yml`) als opt-ins voor pattern B.

2. **Adopteer gen-3 core.yml als basis-template.** Verplichte internal building blocks: `_ensure-ready`, `_kill-mode`, `_wait-for-endpoint`, `_show-endpoints`, `_bootstrap-env`, `_ensure-dirs`.

3. **Standaard pluggable vars in core.yml:**
   ```yaml
   APP_NAME, FRONTEND_PORT (+ BACKEND_PORT), USE_DOCKER (default 0),
   DEV_CMD, START_TIMEOUT (default 30), STOP_TIMEOUT (default 15),
   RUNTIME_DIR (default .task), LOGS_DIR (default .task/logs),
   VPN_IP (override),
   STOP_CMD/RESTART_CMD/LOGS_CMD/STATUS_CMD (optional pluggables)
   ```

4. **Conventies hard-coderen:**
   - `silent: true` op file-niveau, `silent: false` op help/default/start/stop/restart/status/doctor
   - `dotenv: ['.env.local', '.env']`
   - Internal-tasks: `_prefix` mét `internal: true`
   - Naming: `kebab-case` lifecycle, `kebab:colon` namespaces, `_kebab-case` internal
   - `set: [errexit, pipefail, nounset]` in shell-cmds waar mogelijk (uit smart-search)

5. **Verplichte top-level tasks** in elk template:
   - `default` → `help`
   - `help` → `core:help` (split) of inline (single)
   - `start`, `stop`, `restart`, `logs`, `status`
   - `setup`, `doctor`
   - `install`, `build`, `test`, `lint`, `typecheck`, `check`

6. **Optionele namespace-modules** als losse skill-templates:
   - `db.yml` (Prisma, Alembic, Drizzle profielen)
   - `docker.yml` (multi-environment compose: dev/prod/local/latest)
   - `gh.yml` (issue/PR/feature/fix workflow — uit `nextjs_garagebox`)
   - `git.yml` (branch/promote/publish — uit `vscodeExt_combineFilesToOne`)
   - `service.yml` (user-systemd install/enable/status — uit `repo-workspace`)
   - `prod.yml` (parallel prod-ports/PIDs naast dev — uit `clasp_kalendertool`)

7. **Help-renderer als sub-component**: maakt `printf`-stijl header met dynamische `mode/url/ports` plus secties (Lifecycle, Project, Database, Docker) met `task xxx` in groen.

8. **Doctor-task als eerstegraads burger** in elk template: missing tools opsommen, optionele tools warnen, env-bestanden checken.

---

## 7. Reference files voor de skill

Hieronder de bestanden die de skill als templates/snippets kan citeren:

| Doel | Pad |
|---|---|
| Gen-3 core.yml lifecycle reference | `linuxoptiplexvpn/nextjs_frontend-gdriverights/taskfiles/core.yml` |
| Gen-3 backend+frontend met prod-stack parallel | `linuxoptiplexvpn/clasp_kalendertoolv202601/taskfiles/core.yml` |
| Multi-namespace include reference (pattern B) | `linuxoptiplexvpn/python_rubricsObservatieTool/Taskfile.yml` |
| `db.yml` include + multi-environment `docker:*` | `linuxoptiplexvpn/nextjs_klasspiegelsMVP/Taskfile.yml` |
| Single-file gold (pattern C) voor pure tools | `linuxoptiplexvpn/tools_ufw/Taskfile.yml` |
| Clean 3-namespace split (core/dev/git) | `linuxoptiplexvpn/vscodeExt_combineFilesToOne/Taskfile.yml` |
| POSIX-strict mode (`errexit/pipefail/nounset`) | `*/smart-search/Taskfile.yml` |
| User-systemd `service:*` flow | `linuxpc92/repo-workspace/taskfiles/core.yml` |

**Patroon over servers:** `linuxoptiplexvpn` is consistent de meest geëvolueerde versie (gen-3). `linuxpc92` zit één generatie achter. `linux-pagaaier` en `linux-gbsodk` zijn vaak nog gen-1/gen-2. Voor de skill is `linuxoptiplexvpn` dus de canonieke bron.
