<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §7C — REFACTOR-flow

Gegeven: bestaande Taskfile + **specifiek** target pattern of generatie van user.

**Scope:** chirurgisch. Alleen de aangevraagde structurele transformatie. Géén drift-correcties of naming-fixes meebrengen tenzij user dat expliciet vraagt.

**Stap 1 — Fingerprint** Bepaal huidige pattern (D/C/B/A) en gen (1/2/3) van core. Bevestig user-target.

**Stap 2 — Migratiepad** Kies kleinste veilige sprong:
- **D → A**: extraheer lifecycle naar nieuwe core.yml; project-specifieke commands → project.yml; root wordt thin facade
- **C → A**: zelfde, maar identificeer eerst de "verstopte lifecycle-laag" (zoek tasks die start/stop/logs/status doen of er semantisch op lijken)
- **A gen-1/gen-2 → A gen-3**: vervang core.yml door gen-3 skeleton (§4); behoud project-specifieke vars-overrides; voeg ontbrekende 5 internal building blocks toe
- **A → B**: identificeer concern-clusters (db/docker/git/prod) → split naar aparte include-files

**Stap 3 — Plan tonen** Toon impact aan user. Vraag confirm.

**Stap 4 — Apply** Schrijf nieuwe file-set. Bewaar oude als `.archive/Taskfile.legacy.yml`.

**Stap 5 — Backward compat** Zelfde regels als §7B Stap 4 (max 5 aliases, BREAKING.md voor de rest).

**Stap 6 — Validatie + rollout** Run §10. Geef:
1. Wat te committen
2. Wat hernoemd is (kort lijstje)
3. Eerste commando: `task doctor`
4. Waar de legacy-file staat

**Verschil met STANDAARD:** REFACTOR doet **alleen** de structurele transformatie. Als user wil dat ook drift en naming gefixt worden, moet hij STANDAARD aanvragen, of REFACTOR + daarna AUTO/STANDAARD.

---

