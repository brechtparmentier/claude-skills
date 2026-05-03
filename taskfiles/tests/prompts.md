<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §13 — Test-prompts (validatieset voor de skill)

Twaalf prompts om de skill te valideren. Verwachte output-eigenschap staat erbij.

### AUTO (default) — meest voorkomend

1. **AUTO leeg project** — *"Setup mijn Python repo `python_invoer`."* (geen Taskfile aanwezig) → AUTO detecteert via `pyproject.toml` → kiest **NEW** + Python profile → vraagt alleen `APP_MODULE` + ports indien geen `ports.json` → genereert files.

2. **AUTO bestaande gold-standard** — *"Kijk eens naar mijn Taskfile."* (file scoort 92) → AUTO toont AUDIT-output, **doet niets**, zegt "no action needed".

3. **AUTO bestaande met punctuele issues** — *"Fix mijn taskfile."* (file scoort 80, 3 punctuele issues) → AUTO kiest **FIX**, toont 3 diffs met before/after, gaat door.

4. **AUTO verouderd Taskfile** — *"Kun je deze opfrissen?"* (file scoort 60, gen-2, naming-mix, hardcoded ports) → AUTO kiest **STANDAARD**, toont plan met ~12 wijzigingen, vraagt confirm.

5. **AUTO single-file 1180 regels** — *"Kun je deze opruimen?"* → AUTO kiest **STANDAARD + REFACTOR**, toont plan + impact, vraagt confirm, bewaart legacy in `.archive/`.

### NEW (forced)

6. **NEW Next.js** — *"Maak een Taskfile-setup voor een nieuwe Next.js app `klasspiegels-v2` met Prisma, lokaal+docker toggle."* → Pattern A + db.yml + docker.yml + gen-3 core; ports uit calcport.

7. **NEW Python full-stack** — *"Setup voor `python_factuur` (FastAPI backend + Vite frontend), uv."* → Pattern A met `taskfiles/frontend.yml` als optional include + multi-service patterns uit references/patterns.

8. **NEW Clasp minimaal** — *"Maak een Taskfile voor `clasp_kalenderhulp` (alleen clasp push/pull/open/deploy)."* → Pattern D, 5 commands, heredoc-help, `CLASP_AUTH` var.

### AUDIT (forced read-only)

9. **AUDIT** — *"Audit deze Taskfile [paste]"* → Score op 100, top-5 findings met regelnummers + concrete fixes, klasse (gold/solid/refactor/herstructureren). Geen schrijfacties.

### FIX (specifiek probleem)

10. **FIX VPN-detect** — *"VPN-detectie pakt mijn wg0 niet."* → Lokaliseer VPN-detect-block, vervang met multi-iface uit §4. Toon diff. Suggereer 1-2 vergelijkbare problemen (bv. doctor mist nmcli check).

### STANDAARD (forced bulk)

11. **STANDAARD** — *"Maak deze Taskfile volledig standaard."* → Discovery + plan met alle afwijkingen + confirm + apply-all + BREAKING.md voor renamed tasks.

### REFACTOR (specifiek target)

12. **REFACTOR gen2→gen3** — *"Mijn core.yml mist `_ensure-ready` en `_wait-for-endpoint`. Upgrade naar gen-3."* → Voeg de 5 building blocks toe, behoud bestaande project-vars-overrides. **Geen** drift-correcties of naming-fixes meebrengen — dat is STANDAARD-territorium.

---

