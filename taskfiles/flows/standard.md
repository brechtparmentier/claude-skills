<!-- v1.2.0 — 2026-05-03 -->
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


---

## §7B.1 — Uitvoeringsregel (sinds v1.2.0)

**Bij uitvoerend werkwoord** ("maak", "fix", "verbeter", "pas aan", "genereer", "bouw", "herstel", "doe", "zet op") → **direct uitvoeren**, geen "Akkoord?"-tussenvraag. De opdracht is impliciet bevestigd.

**Confirmation alleen vragen bij:**
- Destructieve acties (verwijderen `node_modules`, `.venv`, `.task/`, database-data)
- Dataverlies (overschrijven user-config zonder backup)
- Blinde overschrijving van bestaande config-files (zie §7B.2 *Bestaande-bestanden-regel*)
- Echte inhoudelijke twijfel (ambigue opdracht met twee tegenstrijdige interpretaties)

Zie ook AP-35 in `docs/anti-patterns.md` en `SKILL.md` Confirmation-gates.

---

## §7B.2 — Bestaande-bestanden-regel (sinds v1.2.0)

Wanneer `package.json`, `docker-compose.yml`, `.env.example`, `.env.local`, `Taskfile.yml`, of `taskfiles/*.yml` al bestaan:

1. **Eerst lezen** — `cat` / Read het volledige bestand
2. **Gericht patchen** — alleen de regels die fout zijn (specifieke `scripts.*`, `services.<x>.ports`, env-keys, vars)
3. **Bewaar** structuur, comments en niet-relevante content (ook regelvolgorde waar mogelijk)
4. **Samenvat** kort welke regels gewijzigd zijn in de output (§7B.5 Output-regel)
5. Bij echt destructieve herstructurering: `.archive/<file>.legacy` aanmaken vóór schrijven

**Nooit:** blinde `cat > file` overschrijving zonder eerst te lezen + patchen.

Zie AP-34 in `docs/anti-patterns.md`.

---

## §7B.3 — Database / Port-regel (Next.js+Prisma+Postgres — sinds v1.2.0)

**Calcport one-liner** wanneer `ports.json` nog niet betrouwbaar is:

```bash
calcport --auto    # geen --range — auto-mode kiest vrij range obv repo-naam
```

Daarna **`ports.json` als bron van waarheid**. Mapping:

| Doel | ports.json sleutel | Toepassing |
|---|---|---|
| Next.js dev | `standard_development.frontend` | `next dev --port <waarde>` |
| Next.js prod | `standard_production.frontend` | `next start --port <waarde>` |
| Postgres host-poort | `database.docker_dev` | `docker-compose.yml ports: ["<waarde>:5432"]` + `DATABASE_URL` |
| Postgres container | `5432` (vast) | container-side van port-mapping |

**Apply consequent in alle relevante files:**
- `Taskfile.yml`
- `taskfiles/core.yml`
- `taskfiles/db.yml`
- `docker-compose.yml`
- `.env.local`
- `.env.example`
- `package.json` scripts (waar nodig)

**Nooit:** `"5432:5432"` als `database.docker_dev` aanwezig is (AP-30), of `DATABASE_URL` met hardcoded `:5432` (AP-31). Zie AP-30/31 in `docs/anti-patterns.md`.

---

## §7B.4 — Start-regel (Next.js+Prisma — sinds v1.2.0)

`task start` voor projecten met Prisma + Postgres moet **deze flow** uitvoeren, in deze volgorde:

1. `_bootstrap-env` — env-file aanwezig of vanuit `.env.example`
2. `task db:up` — Postgres container starten
3. `task db:healthcheck` — `pg_isready` polling (max 30s)
4. `prisma generate` — alleen als `schema.prisma` aanwezig
5. `next dev --port <DEV_PORT>` in background met PID-capture via `_wait-for-endpoint`
6. `curl -fsSk -o /dev/null -w "%{http_code}\n" http://localhost:<DEV_PORT>` — verwacht 200/3xx/404

Bij stap 3 of 6 faal:
- **stop** (exit 1)
- toon de exacte fout (laatste 20 logregels)
- toon vermoedelijke oorzaak
- stel concrete fix voor (of pas die toe als veilig)

Zie AP-32 in `docs/anti-patterns.md`. Template voor `db.yml` staat in `docs/mini-templates.md` § "Postgres + Prisma db.yml".

---

## §7B.5 — Validatie-regel (sinds v1.2.0)

**Nooit "alles werkt" claimen na alleen `task --list`** — dat is een parse-check, geen runtime-check.

**Minimale validatie** (volgorde, bij elk gefaalde stap: stop + show error + propose fix):

1. `task --list` (parse-check, basisvereiste)
2. `task doctor` (tooling-check)
3. `task db:up` (Postgres start — indien Postgres aanwezig)
4. `task db:status` (`pg_isready` healthcheck)
5. `task start` (full stack start, met curl-check ingebouwd)
6. `curl -fsSk http://localhost:<DEV_PORT>` (alleen als stap 5 dit niet al doet)

Bij falen:
- **stop** — geen volgende validatiestap proberen
- **toon exacte fout** — output van het commando, laatste 20 logregels
- **toon vermoedelijke oorzaak** — bv. "Postgres container draait niet" of "DATABASE_URL bevat verkeerde poort"
- **stel concrete fix voor** — of pas die direct toe als de fix veilig is (= geen dataverlies, geen overschrijven van user-config)

Zie AP-33 in `docs/anti-patterns.md`.

---

## §7B.6 — Output-regel (sinds v1.2.0)

Aan het einde van elke STANDAARD-run (en FIX/AUTO bij niet-triviale wijzigingen): toon **alleen** deze 4 secties — niets meer, niets minder.

```
## Wat gewijzigd is
- <file>:<regel> — <korte beschrijving>
- ...

## Commando's succesvol getest
- task --list
- task doctor
- ...

## Commando's gefaald (indien van toepassing)
- <commando> — <exacte fout>
  Vermoedelijke oorzaak: <...>
  Voorgestelde fix: <...>

## Wat je daarna moet uitvoeren
<één concrete actie — bv. `task db:migrate`, of `task start` opnieuw>
```

**Geen pep-talk, geen "Hoop dat dit helpt!", geen samenvatting van de wijziging-rationale.** De wijzigingen spreken voor zich; de validatie-output is de bewijslast.
