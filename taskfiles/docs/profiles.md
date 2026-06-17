<!-- v1.2.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §3 — Projecttype-profielen

Elk profiel definieert: **default Pattern**, **default vars**, **verplichte tasks**, **veelvoorkomende modules**.

### Profiel 1 — Next.js app

- **Pattern**: A (B als prisma + multi-env docker)
- **Drop-in template**: `references/canonical/` (Next.js gold standard)
- **Ports**: calcport-driven via `ports.json` met fallback
- **Vars**: `APP_NAME`, `DEV_PORT`/`PROD_PORT` (uit ports.json), `USE_DOCKER=0`, `DEV_CMD`, `PROD_CMD`, `DOCKER_SERVICE`
- **Cruciaal — `--port` als CLI-flag op TWEE plekken** (zie AP-24):

  **1. Taskfile DEV_CMD/PROD_CMD vars:**
  ```yaml
  DEV_CMD: 'pnpm exec next dev --port {{.DEV_PORT}}'
  PROD_CMD: 'pnpm exec next start --port {{.PROD_PORT}}'
  ```

  **2. Sub-project `package.json` scripts** (mono-repo's met `web/`, `frontend/`, `app/`, `dashboard/` submappen — vaak gemist):
  ```json
  "scripts": {
    "dev":   "next dev --hostname 127.0.0.1 --port 32224",
    "start": "next start --hostname 127.0.0.1 --port 32224"
  }
  ```

  Next.js negeert `PORT` env volledig en valt terug op default 3000 → 3001/3002/3003 als bezet. Dat geeft een silently-broken setup waarbij `task start` "OK" rapporteert maar dev op de verkeerde poort draait.

- **Multi-service port conflict** (zie AP-28 — universele regel, geen Next.js-specifieke aanname):

  Bij meerdere services in dezelfde repo (mono-repo of multi-package) mag elke port-waarde maar door **één** service geclaimd worden. De skill scant alle bron-files (Taskfile vars, alle `package.json` scripts, `ecosystem.config.*`, Python startup scripts, `docker-compose*` host-side ports) op `--port <N>` of `port=<N>` patronen en flagt duplicaten als AP-28.

  **Skill bepaalt NIET welke service welke ports.json-sleutel krijgt** — dat is een project-keuze. Bij conflict: toon alle vrije sleutels, vraag user welke service welke krijgt, pas dan de bron-file aan. Suggereer `calcport` als alle bestaande sleutels geclaimd zijn.

  Voorbeeld-melding:
  ```
  AP-28: poort 32222 dubbel geclaimd
    - app.py:14         python uvicorn ... --port 32222
    - web/package.json  scripts.dev: next dev ... --port 32222
  ```

- **Verplicht**: `default`, `help`, `start`, `stop`, `restart`, `logs`, `status`, `setup`, `doctor`, `install`, `build`, `test`, `lint`, `typecheck`, `check`, `ports`
- **Doctor-tools**: `task`, `git`, `node`, `pnpm`, `calcport`, `lsof` (verplicht); `fnm`, `docker` (optioneel)
- **Modules**: `db.yml` als prisma aanwezig, `docker.yml` als meerdere compose-files
- **PM2-aware**: als project PM2 gebruikt (huidig of legacy), activeer AP-25 fix in `_kill-mode`
- **Mono-repo aware**: als `web/`, `frontend/`, `app/`, `dashboard/` sub-mappen bestaan met `package.json` + `next` dep, scan ze ook voor AP-24 (sub-project)
- **Reference (gold)**: `linuxoptiplexvpn/nextjs_frontend-gdriverights/`

#### Profiel 1B — Next.js + Prisma + Postgres (sub-variant, sinds v1.2.0)

Activeren wanneer `schema.prisma` aanwezig is OF `docker-compose*.yml` een `postgres`-service definieert.

**Port-mapping standaard (verplicht, zie AP-30/31):**

| Doel | ports.json sleutel | Toepassing |
|---|---|---|
| Next.js dev | `standard_development.frontend` | `next dev --port <waarde>` |
| Next.js prod | `standard_production.frontend` | `next start --port <waarde>` |
| Postgres host-poort | `database.docker_dev` | `docker-compose.yml` `ports: ["<waarde>:5432"]` + `DATABASE_URL` |
| Postgres container | `5432` (vast) | container-side van port-mapping |

**Apply consequent in**: `Taskfile.yml`, `taskfiles/core.yml`, `taskfiles/db.yml`, `docker-compose.yml`, `.env.local`, `.env.example`, relevante `package.json` scripts.

**`task start` start-flow (verplicht, zie AP-32):**

1. Env bootstrap (`_bootstrap-env`)
2. `task db:up` — Postgres container starten
3. `task db:healthcheck` — `pg_isready` polling (max 30s)
4. `prisma generate` — alleen als `schema.prisma` aanwezig
5. `next dev --port <DEV_PORT>` in background (met PID-capture via `_wait-for-endpoint`)
6. `curl` check op `http://localhost:<DEV_PORT>`

Bij stap 3 of 6 faal: stop, toon laatste 20 logregels, exit 1.

**Verplichte tasks (extra t.o.v. Profile 1):** `db:up`, `db:down`, `db:status`, `db:healthcheck`, `db:logs`, `db:reset`, `db:generate` (Prisma), `db:migrate`, `db:studio`, `db:seed`

**Doctor-tools (extra):** `docker`, `pg_isready` (uit `postgresql-client`), `prisma` (via `pnpm exec`)

**Calcport one-liner als `ports.json` nog niet betrouwbaar is:**

```bash
calcport --auto   # geen --range — auto-mode kiest een vrij range obv repo-naam
```

Daarna `ports.json` als bron van waarheid. **Nooit** ports.json bypassen door hardcoded poorten in vars te schrijven.

**Reference**: nog geen drop-in profile in `references/profiles/`; voeg toe in toekomstige release. Voor nu: gebruik `references/canonical/` als Next.js basis en breid uit met de `db.yml`-template uit `docs/mini-templates.md` § "Postgres + Prisma db.yml".

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
- *