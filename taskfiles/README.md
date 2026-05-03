<!-- v1.0.0 — 2026-05-03 -->
# taskfiles — Cowork/Claude Code skill

Genereer, audit, fix, standaardiseer en refactor `Taskfile.yml` bestanden volgens
Brechts vastgelegde conventies. Canonieke basis: Pattern A (split-file) met gen-3 core.yml.

**Default modus:** AUTO — detecteer + kies passende sub-modus + apply.

## Quick start

Zie [`INSTALL.md`](./INSTALL.md) voor installatie. Daarna activeert de skill automatisch op:

- "Kijk eens naar mijn taskfile" → AUTO-flow
- "Maak een nieuwe taskfile voor [project]" → NEW-flow
- "Audit deze taskfile" → AUDIT (read-only)
- "Fix [specifiek probleem]" → FIX
- "Maak hem volledig standaard" → STANDAARD
- "Refactor naar Pattern B" → REFACTOR

## Inhoud

| Folder/file | Doel |
|---|---|
| `SKILL.md` | Dispatcher — wordt eerst geladen bij activatie. Bevat AUTO-flow + module-index |
| `CHANGELOG.md` | Versie-historie (Keep-a-Changelog format) |
| `INSTALL.md` | Installatie-instructies |
| `flows/` | Uitvoerbare flows: new, fix, standard, refactor |
| `docs/` | Referentie-documentatie: 11 modules met conventies, anti-patterns, scoring |
| `tests/` | 12 test-prompts om de skill te valideren |
| `references/` | Drop-in templates: canonical Next.js, Python profile, patroon-fragmenten |
| `skill.legacy.md` | Pre-refactor monolithische versie (1480 regels) — voor historische naslag |

## Versie

**v1.0.0** — 2026-05-03

Zie [`CHANGELOG.md`](./CHANGELOG.md) voor details.
