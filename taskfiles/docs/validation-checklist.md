<!-- v1.1.1 — 2026-05-03 -->
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

**Destructieve clean-tasks (sinds v1.1.1):**

- [ ] `task clean` verwijdert **alleen** build-artefacten (`.next/`, `dist/`, `out/`, `coverage/`)
- [ ] `task clean` verwijdert **niet** `.task/` (runtime), `node_modules/`, `.venv/` — die zijn voor `clean:all` of `clean:deps` (toekomstige AP-29)

Toon checklist-resultaat aan gebruiker. Falen = blokkeren tot opgelost.

---

