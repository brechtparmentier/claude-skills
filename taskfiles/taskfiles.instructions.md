---
applyTo: "**/Taskfile*.{yml,yaml}, **/taskfiles/*.{yml,yaml}"
---

# Taskfile conventions — Brecht Parmentier

Pas deze regels toe bij elk Taskfile.yml, core.yml of project.yml dat je bewerkt of genereert.

## Structuur

- **Pattern A** is de standaard voor app-repo's: `Taskfile.yml` (thin facade) + `taskfiles/core.yml` + `taskfiles/project.yml`
- Single-file > 500 regels → altijd refactor naar Pattern A
- Pure CLI-wrapper zonder start/stop → Pattern D (single-file minimaal)

## Verplichte file-level defaults

```yaml
version: '3'
silent: true
dotenv: ['.env.local', '.env']   # .env.local wint — deze volgorde is verplicht
```

`silent: false` expliciet op user-facing tasks: `help`, `start`, `stop`, `status`, `doctor`.

## RUNTIME_DIR

Altijd `.task` — nooit `.taskrun`, nooit `.run`.

```yaml
RUNTIME_DIR: '{{default ".task" .RUNTIME_DIR}}'
```

## Internal tasks

Elke helper-task: `_prefix` ÉN `internal: true`. Geen uitzonderingen.

## gosh-safe — KRITIEK (go-task ≥ 3.48)

**Nooit `$!` als PID-bron** — gosh geeft job-ID (`g1`), geen PID:

```yaml
# FOUT:
- nohup pnpm dev & echo $! > .task/dev.pid

# CORRECT: wacht op endpoint, lees PID via fuser
- task: _wait-for-endpoint
  vars: { PORT: '{{.DEV_PORT}}', SCHEME: http }
- REAL_PID=$(fuser "{{.DEV_PORT}}"/tcp 2>/dev/null | awk '{print $1}'); echo "$REAL_PID" > "{{.RUNTIME_DIR}}/dev.pid"
```

**Nooit plain `kill`** — gebruik `/bin/kill` expliciet voor extern gestarte processen.

**Nooit `ss -tlnp`** voor port-checks — gebruik `fuser PORT/tcp` of `lsof -i :PORT`.

## Verplichte tasks in elke app-repo

`default` → `help`, `help`, `start`, `stop`, `restart`, `logs`, `status`, `setup`, `doctor`, `ports`

## Gen-3 core.yml building blocks (verplicht)

`_ensure-ready`, `_kill-mode`, `_wait-for-endpoint`, `_show-endpoints`, `_bootstrap-env`

## Next.js — AP-24

`--port` op twee plekken: Taskfile `DEV_CMD` var ÉN sub-project `package.json` scripts.
Next.js negeert `PORT` env volledig.

## Anti-patterns — niet produceren

| # | Verboden patroon |
|---|---|
| AP-07 | `dotenv: ['.env', '.env.local']` (verkeerde volgorde) |
| AP-17 | Hardcoded HOME-paden of server-namen in vars |
| AP-21 | `$!` als PID-bron |
| AP-22 | Plain `kill` voor externe processen |
| AP-23 | `ss` voor port-checks |
| AP-24 | Next.js zonder `--port` CLI-flag |
| AP-26 | Hardcoded ports zonder calcport |
| AP-28 | Twee+ services op dezelfde port |
