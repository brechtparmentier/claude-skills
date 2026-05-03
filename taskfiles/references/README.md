# References — canonieke Taskfile templates voor de skill

Deze map bevat de daadwerkelijke gen-3 Taskfile-set die als basis dient voor de `taskfiles` skill.

---

## Welke is de meest geavanceerde?

**Winner:** `canonical/` — een 1-op-1 kopie van `linuxoptiplexvpn/nextjs_frontend-gdriverights/`.

**Waarom deze:**
- 774 regels in `taskfiles/core.yml` met alle 5 gen-3 building blocks
  (`_ensure-ready`, `_kill-mode`, `_wait-for-endpoint`, `_show-endpoints`, `_bootstrap-env`)
- HTTPS-aware lifecycle (uniek): `DEV_SCHEME`/`PROD_SCHEME`, dev cert auto-detect, openssl SAN-check
- Multi-laags VPN-detectie startend met `nmcli` (NetworkManager native) — vier fallback-niveaus
- Auto-setup-detection via mtime-vergelijking (`package.json`/`pnpm-lock.yaml` ↔ `node_modules/.modules.yaml`)
- `_wait-for-endpoint` als herbruikbare sub-task met `LABEL/PORT/SCHEME/HOST/LOG_FILE` parameters
- Drie setup-flavors: `setup`, `setup-quick`, `dev-setup`
- `setsid` proces-detach met fallback
- 17 vars, 8 internal building blocks

Dit is de evolutie ná de `linuxoptiplexpagaaiervpn` versie van dezelfde repo (575 regels) — die snapshot mist HTTPS-support, `_ensure-ready` en `_bootstrap-env`. Niet gebruiken.

---

## Structuur van `canonical/`

```
canonical/
├── Taskfile.yml                  thin facade — forwards naar core/project
├── taskfiles/
│   ├── core.yml                  774 regels — gen-3 lifecycle + docker + maintenance
│   └── project.yml               96 regels — build/test/lint/format/typecheck
```

**Gebruik in de skill:** bij modus NEW kopieert de skill deze drie files, vervangt
project-specifieke vars (APP_NAME, DEV_PORT, PROD_PORT, DEV_CMD, ...) en past
hardcoded paden aan (`certificates/localhost.pem`, `port.config.json` indien afwezig).

---

## Patroon-fragmenten (`patterns/`)

Drie specifieke patronen uit andere repo's die niet in `canonical/` zitten maar
in specifieke project-types overgenomen moeten worden. De skill citeert deze
files alleen voor het relevante stuk; ze zijn geen complete drop-in vervangers.

### `patterns/core-multi-service.yml` (651 regels)

Origineel: `linuxoptiplexvpn/_research_BingelAgendaLesFicheScraper/taskfiles/core.yml`.

**Wat overnemen wanneer:**

| Patroon | Toepassen wanneer | Regels in dit bestand |
|---|---|---|
| Aparte `FRONTEND_PID_FILE`/`BACKEND_PID_FILE`/`*_LOG_FILE` vars | Project heeft >1 langlopend service-proces | vars-blok bovenaan |
| `_stop:service` met `PID_FILE`/`PORT`/`LABEL` parameter | Same | rond regels 540-590 |
| **Process-group kill** (`PGID="$(ps -o pgid= -p "$PID" ...)"; pkill -TERM -g "$PGID"`) | Pnpm/python subprocessen die orphan-children laten | rond regels 567-575 |
| Compose-file autodetect via `vars: { sh: ... }` | i.p.v. `preconditions:` met OR-test | rond regels 84-91 |
| Calcport-integratie (poorten uit `ports.json`) | Alleen relevant als project calcport gebruikt | vars-blok |
| `db:backup` task (pg_dump met env-validatie) | Project met PostgreSQL | rond regels 600+ |

### `patterns/core-shared-server-safe.yml` (491 regels)

Origineel: `linuxoptiplexvpn/bingelKuCuDoelenRapportering2026/taskfiles/core.yml`.

**Wat overnemen wanneer:** project draait op een shared server waar meerdere
projecten dezelfde poorten of process-namen kunnen claimen.

**Het patroon:** `stop_if_owned` leest `/proc/$PID/cwd` en checkt of het proces
bij dít project hoort vóór killen. Dat voorkomt dat `task stop` per ongeluk
een ander project's server vermoordt op een gedeelde host.

### `patterns/core-prod-pipeline.yml` (351 regels)

Origineel: `linuxoptiplexvpn/clasp_kalendertoolv202601/taskfiles/core.yml`.

**Wat overnemen wanneer:** project heeft een **parallelle** prod-stack naast dev
(eigen ports, eigen PIDs, eigen logs). Komt vooral voor bij Clasp + backend
projecten, of Python + frontend hybriden.

**Patronen om over te nemen:**
- Aparte `PROD_BACKEND_PID/PGID/LOG`, `PROD_FRONTEND_*` vars
- Externe `./scripts/stop_service.sh` en `./scripts/status_service.sh`
  voor DRY tussen dev en prod (i.p.v. duplicate inline shell)
- `prod:rebuild` task voor productie-build + restart in één stap

---

## Customization-checklist bij hergebruik

Bij overnemen van `canonical/` voor een nieuw project, **altijd aanpassen:**

- [ ] `APP_NAME` — naar repo-naam
- [ ] `DEV_PORT`, `PROD_PORT`, `DOCKER_PORT` — naar projectspecifieke poorten
- [ ] `DEV_CMD`, `PROD_CMD` — naar correcte runner (next/vite/uvicorn/...)
- [ ] `INSTALL_CMD` / `PKG_MANAGER` — pnpm/uv/poetry
- [ ] `DEV_CERT_FILE`, `DEV_KEY_FILE` paden of weghalen als geen HTTPS-dev nodig
- [ ] `BACKUP_DIR` lijst van bestanden in `backup-config` task
- [ ] `DOCKER_SERVICE` naar service-naam in compose-file
- [ ] `RUNTIME_DIR` van `.taskrun` naar `.task` (de canonieke versie gebruikt
  `.taskrun` — pas aan naar de skill-default `.task` bij genereren)
- [ ] `dotenv` volgorde van `['.env', '.env.local']` naar `['.env.local', '.env']`
  (de canonieke versie heeft drift — dit is een correctie)

**Niet aanpassen:**

- De vijf internal building blocks (alleen overnemen)
- VPN-detectie in `_show-endpoints`
- HTTPS curl `-k` handling in `_wait-for-endpoint`
- Doctor-task tooling-checks (alleen aanvullen met stack-specifiek)

---

## Bekende drift in `canonical/` (correcties die de skill toepast)

De canonieke set is gold standard maar bevat 2 kleine inconsistenties die de
skill bij genereren rechtzet:

1. **dotenv-volgorde:** root `Taskfile.yml` heeft `dotenv: ['.env', '.env.local']`.
   Skill schrijft altijd `['.env.local', '.env']` zodat lokale override wint.

2. **Runtime-dir naam:** `core.yml` gebruikt `.taskrun/`. Skill standaardiseert op
   `.task/` voor consistentie met de bredere convention in Brecht's collectie.

Beide zijn opgenomen als hard rules in `skill.md` §10 *Validatiechecklist*.

---

## Bron-paden (voor wie origineel wil zien)

| File hier | Origineel pad |
|---|---|
| `canonical/Taskfile.yml` | `linuxoptiplexvpn/nextjs_frontend-gdriverights/Taskfile.yml` |
| `canonical/taskfiles/core.yml` | `linuxoptiplexvpn/nextjs_frontend-gdriverights/taskfiles/core.yml` |
| `canonical/taskfiles/project.yml` | `linuxoptiplexvpn/nextjs_frontend-gdriverights/taskfiles/project.yml` |
| `patterns/core-multi-service.yml` | `linuxoptiplexvpn/_research_BingelAgendaLesFicheScraper/taskfiles/core.yml` |
| `patterns/core-shared-server-safe.yml` | `linuxoptiplexvpn/bingelKuCuDoelenRapportering2026/taskfiles/core.yml` |
| `patterns/core-prod-pipeline.yml` | `linuxoptiplexvpn/clasp_kalendertoolv202601/taskfiles/core.yml` |
