<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

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

