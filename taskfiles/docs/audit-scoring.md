<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §6 — Audit-scoremodel (100 punten)

Categorieën met gewicht. Geef per categorie een score 0–max + 1-zin uitleg + concrete fix.

| # | Categorie | Max | Wat telt mee |
|---|---|---|---|
| 1 | Structuur / patroonkeuze | 15 | Klopt Pattern A/B/C/D voor dit projecttype? |
| 2 | Lifecycle-robuustheid | 15 | start/stop/restart/logs/status aanwezig + werken in beide modes (docker/local) + PID-management + waited startup |
| 3 | Runtime management | 10 | `.task/` runtime-dir, PID-file, log-rotation, `_ensure-dirs` |
| 4 | Env / bootstrap | 10 | `dotenv` correcte volgorde, `.env.example` → `.env.local` bootstrap, geen secrets gecommit |
| 5 | Naming consistency | 8 | `kebab-case` lifecycle, `kebab:colon` namespaces, `_kebab` internal — geen mix |
| 6 | Namespace hygiene | 8 | Geen platte `vpn-add` voor 30 scripts; logische groeperingen |
| 7 | Doctor / status / help kwaliteit | 10 | Doctor checkt tooling + env; help is dynamisch (mode/url/port); status klopt voor beide modes |
| 8 | Anti-pattern risico | 14 | Som van severiteit van gevonden anti-patterns: 0 = 14 pt; 1 hoog = -7; 1 medium = -3; 1 laag = -1 |
| 9 | Onderhoudbaarheid | 10 | Geen >500 regel single-file, geen mega-alias-sectie, includes gebruikt, vars gedocumenteerd |

**Drempels:**
- 90–100 → "gold standard, geen actie nodig"
- 75–89 → "solid, kleine verbeteringen aanbevolen"
- 50–74 → "werkt, maar refactor naar Pattern A + gen-3 aanbevolen"
- <50 → "fundamenteel herstructureren"

---

