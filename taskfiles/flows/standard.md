<!-- v1.1.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §7B — STANDAARD-flow

Gegeven: bestaande Taskfile + user-intent "breng in lijn met current standard" (of AUTO heeft STANDAARD gekozen op basis van diagnose).

**Scope:** bulk. Discovery + apply-all van afwijkingen tegelijk.

**Stap 1 — Discovery** Run intern §5b *Anti-pattern detectie* + §6 *Audit-scoremodel*. Vergelijk met `references/canonical/` + skill-conventies. Maak lijst van **alles** wat afwijkt.

**Verplichte pre-checks** (controleer deze altijd, niet alleen wanneer ze in de Taskfile-tekst voorkomen):

1. **Calcport-status** (zie AP-26):
   - Run `command -v calcport` — beschikbaar?
   - Bestaat `ports.json` in repo-root?
   - Bestaat `ports.md` in repo-root?
   - Heeft de Taskfile hardcoded poort-vars (regex: `_PORT:\s*['"]?\d+`)?
   - Op basis hiervan: voeg AP-26 of AP-27 toe aan findings als drift.
2. **gosh-safety**:
   - Bevat de Taskfile `echo \$!` patronen? → AP-21
   - Bevat de Taskfile plain `kill ` (niet `/bin/kill`)? → AP-22
   - Bevat de Taskfile `ss -tlnp` of `ss -tnlp`? → AP-23
3. **Stack-specifieke pre-checks**:
   - Next.js: bevat `DEV_CMD` `--port` flag? → AP-24 als nee
   - Next.js + ecosystem.config.* aanwezig: PM2-aware `_kill-mode`? → AP-25 als nee
4. **Sub-project Next.js detectie** (mono-repo's):
   - Bestaat er een sub-map (`web/`, `frontend/`, `app/`, `dashboard/` of vergelijkbaar) met `package.json`?
   - Heeft die `package.json` `"next"` als dep of devDep?
   - Zo ja: lees `scripts.dev` en `scripts.start` — missen `--port\s+\d+`? → **AP-24 (sub-project)**
   - Heeft `--port`? → noteer de poort-waarde voor stap 5
5. **Cross-service port-conflict scan** (universeel — zie AP-28):
   - Verzamel alle `--port <N>` of `port=<N>` waardes uit:
     - Taskfile DEV_CMD/PROD_CMD
     - Alle `<subdir>/package.json` scripts
     - `ecosystem.config.js`/`.cjs`
     - Python startup scripts (`uvicorn`, `flask run`, `gunicorn`, etc.)
     - `docker-compose*.yml` host-side ports
   - Als dezelfde poort >1× voorkomt → **AP-28** flag (toon alle bron-locaties)
   - Skill bepaalt **niet zelf** welke service welke ports.json-sleutel krijgt; vraag user bij conflict

**Standaard discovery-categorieën**:

- Pattern (single-file >500 regels → A; missing includes)
- Generatie (gen-1/gen-2 building blocks ontbreken → gen-3)
- Naming (snake_case/camelCase → kebab-case + kebab:colon)
- dotenv volgorde
- Runtime dir (`.taskrun`/`logs`/`.run` → `.task`)
- Internal tasks zonder `internal: true`
- Hardcoded ports → calcport-driven (AP-26)
- Tooling: pip → uv, py_compile → ruff, npm → pnpm (per stack-conventie)
- Building blocks ontbrekend (alle 5 gen-3 blocks)
- VPN-detectie alleen tun0 → multi-iface
- Doctor missing of incompleet — moet calcport bevatten (AP-27)
- `task ports` command ontbreekt (AP-27)
- Backward-compat alias-secties >50 regels (verwijderen → migratie-tabel in BREAKING.md)
- Hardcoded paden in vars
- Help-task statisch i.p.v. dynamisch (mode/url/ports)

**Sta