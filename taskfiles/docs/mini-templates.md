<!-- v1.2.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

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
  setup:    { desc: First-time setup,    cmds: [task: core:setup] }

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

> **Waarom geen `task --list`?** Deze skill kiest **bewust** voor handgeschreven printf-help i.p.v. de automatische `task --list` output. Reden: `task --list` toont alleen tasks met `desc:` in alfabetische volgorde, **zonder** sectie-headers ("Lifecycle", "Project", "Database"), **zonder** dynamische context (mode, url, ports), en **zonder** kleur-onderscheid tussen lifecycle/project/maintenance. De printf-aanpak hieronder geeft de gebruiker direct waar hij is (welke poort, welke mode, welke vpn-url) en groepeert commands logisch. Tijdens AUDIT geeft dit een -2 voor "statische help" — dat is een **bekende false-positive** voor deze skill, niet drift.

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


### Template — Postgres + Prisma `taskfiles/db.yml` (sinds v1.2.0)

Drop-in template voor projecten met Prisma + Postgres in `docker-compose.yml`. Host-poort komt uit `ports.json` `database.docker_dev` — **nooit** hardcoded `5432:5432` (zie AP-30/31).

```yaml
version: '3'
silent: true

vars:
  # Container-side blijft altijd 5432; host-poort uit ports.json
  DB_HOST_PORT:
    sh: |
      if [ -f ports.json ]; then
        python3 -c 'import json; print(json.load(open("ports.json")).get("database",{}).get("docker_dev",5432))' 2>/dev/null || echo 5432
      else
        echo 5432
      fi
  DB_USER: '{{default "postgres" .DB_USER}}'
  DB_PASS: '{{default "postgres" .DB_PASS}}'
  DB_NAME: '{{default "app" .DB_NAME}}'
  DB_HEALTHCHECK_TIMEOUT: '30'

tasks:
  up:
    desc: Start Postgres container
    silent: false
    cmds:
      - docker compose up -d postgres
      - task: healthcheck

  down:
    desc: Stop Postgres container
    silent: false
    cmds:
      - docker compose stop postgres

  status:
    desc: Postgres healthcheck via pg_isready
    silent: false
    cmds:
      - |
        if pg_isready -h localhost -p {{.DB_HOST_PORT}} -U {{.DB_USER}} >/dev/null 2>&1; then
          printf "\033[32m[OK]\033[0m Postgres reageert op localhost:{{.DB_HOST_PORT}}\n"
        else
          printf "\033[31m[X]\033[0m Postgres NIET bereikbaar op localhost:{{.DB_HOST_PORT}}\n"
          exit 1
        fi

  healthcheck:
    desc: Poll pg_isready totdat Postgres up is (max DB_HEALTHCHECK_TIMEOUT s)
    silent: false
    cmds:
      - |
        ELAPSED=0
        while [ $ELAPSED -lt {{.DB_HEALTHCHECK_TIMEOUT}} ]; do
          if pg_isready -h localhost -p {{.DB_HOST_PORT}} -U {{.DB_USER}} >/dev/null 2>&1; then
            printf "\033[32m[OK]\033[0m Postgres up na ${ELAPSED}s\n"
            exit 0
          fi
          sleep 1
          ELAPSED=$((ELAPSED + 1))
        done
        printf "\033[31m[X]\033[0m Postgres niet bereikbaar na {{.DB_HEALTHCHECK_TIMEOUT}}s\n"
        docker compose logs --tail=20 postgres
        exit 1

  logs:
    desc: Volg Postgres logs
    cmds:
      - docker compose logs -f postgres

  reset:
    desc: Stop, verwijder volume, start opnieuw (DESTRUCTIEF — data weg)
    silent: false
    cmds:
      - docker compose down -v postgres
      - task: up

  generate:
    desc: Prisma generate client
    silent: false
    cmds:
      - pnpm exec prisma generate

  migrate:
    desc: Prisma migrate dev
    silent: false
    cmds:
      - pnpm exec prisma migrate dev

  studio:
    desc: Prisma Studio
    cmds:
      - pnpm exec prisma studio

  seed:
    desc: Prisma db seed
    cmds:
      - pnpm exec prisma db seed
```

### Template — root `Taskfile.yml` `start:` met DB-aware flow (Next.js+Prisma)

Vervang de standaard `start:` shortcut in de root Taskfile met deze flow voor Next.js+Prisma projecten (zie AP-32 en Profile 1B):

```yaml
includes:
  core:    { taskfile: ./taskfiles/core.yml,    optional: false }
  project: { taskfile: ./taskfiles/project.yml, optional: false }
  db:      { taskfile: ./taskfiles/db.yml,      optional: true  }

tasks:
  start:
    desc: Start full stack (env → db → prisma generate → next dev → curl)
    silent: false
    cmds:
      - task: core:_ensure-dirs
      - task: core:_bootstrap-env
      - task: db:up                # start Postgres + healthcheck
      - cmd: pnpm exec prisma generate
        ignore_error: false        # blokkerend
      - task: core:start           # next dev met PID-capture
      # core:start doet zelf de curl-check via _wait-for-endpoint
```

`task stop` blijft hetzelfde (`core:stop`) — het stoppen van de DB-container is `task db:down`, niet automatisch onderdeel van `task stop` (zou dataverlies-risico zijn als andere processen ermee verbonden zijn).

### Template — `docker-compose.yml` Postgres-service met dynamische host-poort

```yaml
services:
  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASS:-postgres}
      POSTGRES_DB: ${DB_NAME:-app}
    ports:
      # Host-poort uit ports.json database.docker_dev (NIET hardcoded 5432!)
      # Skill vervangt ${DB_HOST_PORT} bij genereren met de ports.json-waarde.
      - "${DB_HOST_PORT:-5432}:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "${DB_USER:-postgres}"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres-data:
```

`.env.local` en `.env.example` moeten dezelfde host-poort bevatten in `DATABASE_URL`:

```
DB_HOST_PORT=<database.docker_dev waarde>
DATABASE_URL=postgresql://postgres:postgres@localhost:${DB_HOST_PORT}/app
```
