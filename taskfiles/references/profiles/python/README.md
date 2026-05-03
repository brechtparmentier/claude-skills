# Profile — Python (FastAPI + uv)

Drop-in template voor Python projects: FastAPI/uvicorn backend, uv package manager,
ruff voor lint+format, pytest voor tests. Pattern A — `Taskfile.yml` als thin facade,
`taskfiles/core.yml` voor lifecycle, `taskfiles/project.yml` voor build/test/quality.

---

## Wanneer dit profile gebruiken

- Python project met een long-running server (FastAPI, Flask via uvicorn, Starlette)
- uv als package manager (gen-3 conventie)
- Geen frontend, of frontend wordt los beheerd

**Voor full-stack Python+frontend** — gebruik dit profile als basis en voeg een aparte
`taskfiles/frontend.yml` include toe (Vite/Next.js). Of gebruik `references/patterns/core-multi-service.yml` als referentie.

---

## Structuur

```
profile-python/
├── Taskfile.yml                  thin facade — forwards naar core/project
└── taskfiles/
    ├── core.yml                  ~430 regels — gen-3 lifecycle + uv-aware setup
    └── project.yml               ~70 regels — uv + ruff + pytest
```

---

## Drift-correcties t.o.v. de gold-standards

| Onderwerp | Origineel (`python_leerlokaalFV`) | Dit profile |
|---|---|---|
| dotenv volgorde | `['.env', '.env.local']` | `['.env.local', '.env']` (override wint) |
| Runtime dir | `logs/` (mixed met repo) | `.task/` + `.task/logs/` |
| Tooling default | `pip install + py_compile` | `uv sync` + `ruff` |
| Test default | custom `test-db`/`test-import`/`test-syntax` | `pytest {{.TEST_DIR}}` |
| Lint default | `python -m py_compile` (= alleen syntax) | `ruff check` (= lint + import-sort + …) |
| Format default | placeholder met `pip install black` warning | `ruff format` |
| Building blocks | inline in `_start_api`/`_start_frontend` | gen-3 reusable: `_ensure-ready`, `_kill-mode`, `_wait-for-endpoint`, `_show-endpoints`, `_bootstrap-env` |
| Port management | hardcoded `35567`/`35568` in vars | calcport-driven via `ports.json` met fallback |
| VPN-detectie | alleen `tun0` met grep -oP | multi-iface (nmcli + tun/wg/tailscale/zt + RFC1918) |

---

## Customization-checklist bij hergebruik

Bij overnemen voor een nieuw Python project, **altijd aanpassen:**

- [ ] `APP_NAME` in `core.yml` vars — naar repo-naam
- [ ] `APP_MODULE` — naar correct Python pad (bv. `src.myapp.api:app` of `myapp.main:app`)
- [ ] `PY_SOURCES` in `project.yml` — naar bron-folder (default `src`)
- [ ] `TEST_DIR` in `project.yml` — naar test-folder (default `tests`)
- [ ] `ports.json` aanmaken in repo-root, of laat calcport hem genereren
- [ ] `pyproject.toml` met `[project]` sectie + `[tool.ruff]` config (zie sjabloon hieronder)
- [ ] `.env.example` aanmaken met dummy values voor secrets/db-connection
- [ ] `.gitignore` aanvullen met `.task/`, `.venv/`, `__pycache__/`, `.pytest_cache/`, `.ruff_cache/`

**Niet aanpassen** (deze zijn convention):

- De vijf gen-3 internal building blocks
- VPN-detectie in `_show-endpoints`
- `dotenv` volgorde
- `RUNTIME_DIR` naam (`.task`)

---

## Voorbeeld `pyproject.toml` (minimaal)

```toml
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110",
    "uvicorn[standard]>=0.27",
]

[tool.uv]
dev-dependencies = [
    "pytest>=8.0",
    "ruff>=0.4",
]

[tool.ruff]
line-length = 100
target-version = "py311"
src = ["src", "tests"]

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP", "SIM"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q"
```

---

## Voorbeeld `ports.json`

```json
{
  "standard_development": {
    "backend": 8000
  },
  "standard_production": {
    "backend": 8001
  }
}
```

Of laat `calcport` deze genereren obv repo-naam.

---

## Doctor-tools

Verplicht (faalt als één ontbreekt):

- `task` `git` `uv` `python3` `calcport` `lsof`

Optioneel (waarschuwing):

- `docker` (alleen als project Docker compose-file heeft)

Stack-specifieke aanvullingen kunnen in `project.yml` als aparte `doctor:` task toegevoegd worden — dan roept `core:doctor` die mee aan.

---

## Bron

Gold-standards uit collectie waarop dit profile gebaseerd is:

- `linuxoptiplexvpn/python_leerlokaalFV/` — eenvoudig Pattern A, FastAPI + Vite frontend
- `linuxoptiplexvpn/python_rubricsObservatieTool/` — uitgebreid Pattern B met `native.yml`/`docker.yml`/`prod.yml`/`demo.yml`
- `linuxoptiplexvpn/_research_BingelAgendaLesFicheScraper/` — calcport-integratie pattern

Building blocks geadopteerd uit `references/canonical/taskfiles/core.yml` (Next.js gold).
