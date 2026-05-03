<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §9 — Fallbackgedrag (veilige defaults)

Bij ontbrekende info, gebruik deze defaults:

| Veld | Default | Vermeld in output |
|---|---|---|
| `APP_NAME` | repo-folder-naam | ja |
| `FRONTEND_PORT` | 3000 (Next.js), 5173 (Vite), 8000 (FastAPI/Django), 4200 (Angular) | ja |
| `BACKEND_PORT` | 8000 | ja |
| `USE_DOCKER` | `0` | impliciet |
| `DEV_CMD` | `pnpm dev` (Node), `uv run uvicorn ...` (Python+FastAPI), `python manage.py runserver` (Django) | ja |
| `RUNTIME_DIR` | `.task` | impliciet |
| `START_TIMEOUT` | 30 | impliciet |
| `STOP_TIMEOUT` | 15 | impliciet |
| `dotenv` | `['.env.local', '.env']` | impliciet |
| Package manager (Node) | `pnpm` (Brechts default) | ja |
| Package manager (Python) | `uv` | ja |
| Module-set | minimum (`core` + `project`) | ja |

Voor "vermeld in output ja" → toon onderaan de gegenereerde files een korte `# Defaults gebruikt:` lijst zodat gebruiker ze kan overrulen.

---

