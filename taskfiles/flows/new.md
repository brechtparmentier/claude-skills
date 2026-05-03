<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §1 — Failproof generatieflow (NEW)

Volg deze 9 stappen, in deze volgorde. Geen stap overslaan.

### Stap 1 — Projecttype bepalen

Vraag 1 (multiple choice):
> "Welk projecttype? (1) Next.js app — (2) Python app — (3) CLI/tooling — (4) Clasp/Apps Script — (5) VS Code extension — (6) AI/monitoring — (7) Server-beheer — (8) Multi-project toolbelt"

Als gebruiker iets noemt dat niet matcht → vraag of het *het meest lijkt op* een van die 8 → kies dat profiel.

### Stap 2 — Runtime-mode bepalen

Vraag 2:
> "Runtime: (a) lokaal-only, (b) docker-only, (c) toggle (USE_DOCKER 0/1)? Default = (a)."

### Stap 3 — Pattern kiezen (beslisboom)

Volg §2 *Beslisboom Pattern A/B/C/D* op basis van projecttype + runtime + verwachte complexiteit.

### Stap 4 — Verplichte tasks bepalen

Lees §3 *Projecttype-profielen* voor het gekozen profiel → noteer de verplichte top-level tasks.

### Stap 5 — Optionele modules bepalen

Vraag 3 (multi-select):
> "Heb je nodig: [ ] db (Prisma/Alembic/Drizzle) [ ] docker (multi-env compose) [ ] gh (issue/PR workflow) [ ] git (branch/promote/publish) [ ] service (user-systemd) [ ] prod (parallelle prod-stack)?"

### Stap 6 — Vars bepalen

Verzamel: `APP_NAME`, `FRONTEND_PORT`, `BACKEND_PORT` (als full-stack), `DEV_CMD`, `USE_DOCKER`, `DOCKER_SERVICE`, `START_TIMEOUT`, `STOP_TIMEOUT`. Voor missende vars → veilige defaults uit §9 *Fallbackgedrag*.

### Stap 7 — Files genereren

Genereer concreet:
- `Taskfile.yml` (root, thin facade) — zie §11 *Werkende mini-templates*
- `taskfiles/core.yml` (gen-3 skeleton) — zie §4 *Gen-3 core.yml canoniek*
- `taskfiles/project.yml` (project-specifieke commands)
- Optionele includes (db.yml, docker.yml, ...)
- `.env.example` als die nog niet bestaat

### Stap 8 — Validatiecheck tonen

Run §10 *Validatiechecklist* mentaal over de gegenereerde files. Toon resultaat aan gebruiker.

### Stap 9 — Gebruiksinstructies tonen

Geef concreet:
1. `task` (default → help)
2. `task setup` (eerste keer)
3. `task start` / `task stop` / `task status`
4. `task doctor` (check tooling)

Eindig altijd met **één concrete volgende stap**.

---

