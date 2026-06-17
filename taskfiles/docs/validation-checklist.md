<!-- v1.2.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

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

**Root-facade compleetheid (Pattern A — kritiek, sinds v1.1.1):**

Een task in `core:*` of `project:*` is **niet voldoende** — er moet een corresponderende root-shortcut bestaan.

- [ ] **Alle "Verplicht"-tasks uit het gekozen profile** (zie `docs/profiles.md`) zijn als root-shortcut beschikbaar — niet alleen via `core:*`/`project:*` indirect bereikbaar
- [ ] **Specifiek altijd verplicht in root** (Pattern A): `default`, `help`, `start`, `stop`, `restart`, `status`, `logs`, `doctor`, `setup`, `install`, `build`, `test`, `lint`, `check`, `clean`, `ports`
- [ ] **Test:** `task --list` (of `task` zonder args) toont alle root-shortcuts. Verifieer dat **`task doctor`** en **`task setup`** beide werken — dit zijn de meest-vergeten shortcuts
- [ ] **Geen redundante project-aliases** voor wat root al biedt (bv. `project:dev` als alias voor `task start` is verwarrend → schrappen)

**Destructieve clean-tasks (AP-29, sinds v1.1.1, geformaliseerd in v1.2.0):**

- [ ] `task clean` verwijdert **alleen** build-artefacten (`.next/`, `dist/`, `out/`, `coverage/`)
- [ ] `task clean` verwijdert **niet** `.task/` (runtime), `node_modules/`, `.venv/` — die zijn voor `clean:all`, `clean:deps`, of `clean:runtime`

**Database port-mapping (Next.js+Prisma+Postgres — AP-30/31, sinds v1.2.0):**

- [ ] `docker-compose*.yml` Postgres-service heeft `ports: ["<database.docker_dev>:5432"]` — **niet** `"5432:5432"` (AP-30)
- [ ] `DATABASE_URL` in `.env.local` + `.env.example` gebruikt **dezelfde host-poort** als de docker-compose mapping (AP-31)
- [ ] `task db:up` en `task db:status` rapporteren de **projectspecifieke** host-poort, niet hardcoded 5432
- [ ] Port-mapping consistent in **alle** files: `Taskfile.yml`, `taskfiles/core.yml`, `taskfiles/db.yml`, `docker-compose.yml`, `.env.local`, `.env.example`, eventuele `package.json` scripts

**Start-flow voor Next.js+Prisma (AP-32, sinds v1.2.0):**

`task start` moet voor projecten met Prisma+Postgres in deze volgorde uitvoeren:

- [ ] 1. Env bootstrap (`.env.local` aanwezig of vanuit `.env.example`)
- [ ] 2. `task db:up` — Postgres container starten
- [ ] 3. `task db:healthcheck` — `pg_isready` polling (max 30s)
- [ ] 4. `prisma generate` — alleen als `schema.prisma` aanwezig
- [ ] 5. `next dev --port <DEV_PORT>` in background met PID-capture
- [ ] 6. `curl` check op `http://localhost:<DEV_PORT>` (200/3xx/404 = OK)

Bij stap 3 of 6 faal: stop, toon laatste 20 logregels, exit 1.

**Runtime validatie verplicht — niet alleen parse-check (AP-33, sinds v1.2.0):**

`task --list` bewijst alleen YAML-parseerbaarheid, niet werking. Verplichte minimale runtime-validatie:

- [ ] 1. `task --list` (parse-check, basisvereiste)
- [ ] 2. `task doctor` (tooling-check)
- [ ] 3. `task db:up` (indien Postgres aanwezig)
- [ ] 4. `task db:status` (`pg_isready` healthcheck)
- [ ] 5. `task start` (full stack start, met curl-check ingebouwd)
- [ ] 6. `curl -fsSk http://localhost:<DEV_PORT>` (dev-url bereikbaar — alleen als `task start` dit niet al doet)

Bij elke fail: stop, toon exacte fout + vermoedelijke oorzaak + concrete fix-suggestie (of pas die toe als veilig).

**Bestaande-bestanden regel (AP-34, sinds v1.2.0):**

Bij STANDAARD/REFACTOR/FIX op een bestaand project:

- [ ] **Eerst lezen** van `package.json`, `docker-compose.yml`, `.env*`, `Taskfile.yml`, `taskfiles/*.yml`
- [ ] **Gericht patchen** — alleen de regels die fout zijn
- [ ] **Structuur, comments en niet-relevante content** blijven behouden
- [ ] **Korte samenvatting** van gewijzigde regels in de output
- [ ] Bij echt destructieve herstructurering: `.archive/<file>.legacy` aanmaken

**Uitvoeringsregel (AP-35, sinds v1.2.0):**

- [ ] Bij uitvoerend werkwoord ("maak", "fix", "verbeter", "pas aan", "genereer", "bouw", "herstel"): **direct uitvoeren**, geen "Akkoord?"-vraag
- [ ] Confirmation alleen bij: destructie, dataverlies, blinde overschrijving (AP-34), echte twijfel
- [ ] Output achteraf in vaste vorm — zie Output-regel in `flows/standard.md`

Toon checklist-resultaat aan gebruiker. Falen = blokkeren tot opgelost.

---

