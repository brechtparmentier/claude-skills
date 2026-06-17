<!-- v1.2.0 — 2026-05-03 -->
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
| AP-29 | `clean`-task verwijdert runtime-dir (`.task/`) of dep-dir (`node_modules`/`.venv`) zonder eigen namespace (`clean:all`/`clean:deps`) | **hoog** |
| AP-30 | Hardcoded `"5432:5432"` voor Postgres in `docker-compose*.yml` terwijl `ports.json` een projectspecifieke `database.docker_dev` voorziet | **hoog** |
| AP-31 | `DATABASE_URL` met hardcoded `:5432` i.p.v. de host-poort uit `ports.json` | **hoog** |
| AP-32 | `task start` voor Next.js+Prisma start alleen de dev-server, niet `db:up` + healthcheck + `prisma generate` vooraf | **hoog** |
| AP-33 | "Het werkt" claimen op basis van `task --list` alleen (parse-check ≠ runtime-check) | **hoog** |
| AP-34 | Blinde overschrijving van bestaande `package.json` / `docker-compose.yml` / `.env*` zonder eerst te lezen en gericht te patchen | **hoog** |
| AP-35 | Onnodige confirmation-vraag bij een uitvoerend werkwoord ("maak", "fix", "verbeter") wanneer geen destructieve actie nodig is | medium |

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

**Detectie-checklist** (run aan het begin van AUDIT/STANDAARD/AU
TO/AUDIT/STANDAARD):
1. Bestaat `calcport` als command?
2. Bestaat `ports.json` in repo-root?
3. Bestaat `ports.md` in repo-root?
4. Heeft de Taskfile hardcoded poort-vars?

**Fix-patroon (canonical):** vervang hardcoded vars met `sh:`-blok dat `ports.json` leest. Run `calcport --auto` zonder `--range` als `ports.json` nog niet betrouwbaar is — de auto-mode kiest een vrij range voor de repo-naam.

---

### Toelichting bij AP-29 t/m AP-35 — Database, validatie en gedragsregels (v1.2.0)

**AP-29 — Destructieve `clean`-task.**
Een `clean`-task hoort **alleen** build-artefacten te verwijderen (`.next/`, `dist/`, `out/`, `coverage/`). Het verwijderen van `node_modules/`, `.venv/` of `.task/` hoort bij een **eigen namespace** zodat de gebruiker niet per ongeluk dependencies wegmaakt.

**Fix-patroon:**

```yaml
clean:        { desc: Build-artefacten,  cmds: [rm -rf .next dist out coverage] }
clean:deps:   { desc: Dependencies,      cmds: [rm -rf node_modules .venv] }
clean:runtime:{ desc: Runtime + PID,     cmds: [rm -rf .task] }
clean:all:    { desc: ALLES (destructief), cmds: [task: clean, task: clean:deps, task: clean:runtime] }
```

**AP-30 — Hardcoded `"5432:5432"` voor Postgres.**
Als `ports.json` een projectspecifieke `database.docker_dev` voorziet, moet `docker-compose*.yml` die host-poort gebruiken — niet `5432`. Container-side blijft `5432` (interne Postgres-poort), host-side wordt projectspecifiek zodat meerdere repos parallel kunnen draaien.

**Port-mapping standaard (verplicht in Profile 1 Next.js + Prisma/Postgres):**

| Doel | ports.json sleutel | Toepassing |
|---|---|---|
| Next.js dev | `standard_development.frontend` | `next dev --port <waarde>` |
| Next.js prod | `standard_production.frontend` | `next start --port <waarde>` |
| Postgres host-poort | `database.docker_dev` | `docker-compose.yml` `ports: ["<waarde>:5432"]` + `DATABASE_URL` |
| Postgres container | `5432` (vast) | container-side van port-mapping |

**Fix-patroon (`docker-compose.yml`):**

```diff
services:
  postgres:
    image: postgres:16
    ports:
-     - "5432:5432"
+     - "<%= database.docker_dev %>:5432"
```

Toepassen in: `docker-compose.yml`, `.env.local`, `.env.example`, `taskfiles/db.yml`, en in elke `package.json` script die naar de database verbindt.

**AP-31 — `DATABASE_URL` met hardcoded `:5432`.**
Zelfde principe als AP-30. `DATABASE_URL` moet de host-poort gebruiken — dezelfde waarde als de host-side van docker-compose mapping.

**Fix-patroon (`.env.local` + `.env.example`):**

```diff
- DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
+ DATABASE_URL=postgresql://user:pass@localhost:<database.docker_dev>/dbname
```

**AP-32 — `task start` mist database-startflow voor Next.js+Prisma.**
Voor projecten met Prisma + Postgres moet `task start` deze flow uitvoeren, **in deze volgorde**:

1. `_bootstrap-env` (env-bestand aanwezig of vanuit `.env.example`)
2. `task db:up` (Postgres container starten)
3. `task db:healthcheck` (`pg_isready` polling, max 30s)
4. `prisma generate` (alleen als `schema.prisma` aanwezig)
5. `next dev --port <DEV_PORT>` (in background, met PID-capture via `_wait-for-endpoint`)
6. `curl` check op `http://localhost:<DEV_PORT>` (200/3xx/404 = OK)

Bij stap 3 of 6 faal: stop, toon laatste 20 regels van het log, exit 1.

**Fix-patroon:** voeg een `taskfiles/db.yml` include toe met `db:up`/`db:healthcheck`/`db:status`/`db:down`/`db:logs`. Update root `start:` om `db:up` + healthcheck vóór `core:start` te chainen voor projecten waar `schema.prisma` of `docker-compose.yml` met Postgres bestaat.

**AP-33 — "Het werkt" claimen na alleen `task --list`.**
`task --list` bewijst alleen dat de Taskfile YAML-parseerbaar is. Het bewijst **niet** dat:
- de tasks werken
- de poorten kloppen
- de database start
- de dev-server bereikbaar is

**Verplichte minimale runtime-validatie** (volgorde):

1. `task --list` (parse-check)
2. `task doctor` (tooling-check)
3. `task db:up` (database start, indien Postgres aanwezig)
4. `task db:status` (`pg_isready` healthcheck)
5. `task start` (full stack start)
6. `curl -fsSk -o /dev/null -w "%{http_code}\n" http://localhost:<DEV_PORT>` (dev-url bereikbaar)

Bij elke fail: stop, toon exacte fout (laatste 20 logregels of curl-fout), toon vermoedelijke oorzaak, stel een concrete fix voor (of pas die toe als ze veilig is).

**AP-34 — Blinde overschrijving van bestaande config-bestanden.**
Bij STANDAARD/REFACTOR/FIX op een bestaand project mag de skill `package.json`, `docker-compose.yml`, `.env.example`, `.env.local`, `Taskfile.yml`, of `taskfiles/*.yml` **nooit** blind overschrijven.

**Verplichte volgorde:**

1. **Lees** het huidige bestand eerst
2. **Patch gericht** — alleen de regels die fout zijn (specifieke vars, scripts-entries, port-mappings)
3. **Bewaar** structuur, comments en niet-relevante content
4. **Samenvat** kort welke regels gewijzigd zijn (vóór de "wat is gewijzigd" output)

Bij echt destructieve wijziging (bv. herstructurering van docker-compose-services): `.archive/<file>.legacy` aanmaken vóór schrijven.

**AP-35 — Onnodige akkoordvraag bij uitvoerend werkwoord.**
Als de gebruiker een uitvoerend werkwoord gebruikt ("maak", "fix", "verbeter", "pas aan", "genereer", "bouw", "herstel", "doe", "zet op"), is de opdracht **impliciet bevestigd**. De skill moet direct uitvoeren en achteraf rapporteren — geen "Akkoord om alles toe te passen?" tussenvoegen.

**Wel confirmation:** alleen bij destructie, dataverlies, blinde overschrijving (AP-34), of echte inhoudelijke twijfel. Zie `SKILL.md` Confirmation-gates voor de volledige regel.
