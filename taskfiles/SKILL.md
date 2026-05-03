---
name: taskfiles
version: 1.1.0
updated: 2026-05-03
description: >
  Activeer deze skill wanneer de gebruiker een Taskfile.yml wil maken, auditen, fixen, standaardiseren
  of refactoren, of wanneer hij/zij vraagt om een task-runner setup voor een project.
  Triggers: "maak een Taskfile", "Taskfile.yml", "audit deze taskfile", "fix mijn taskfile",
  "maak hem standaard", "refactor mijn taskfile", "kijk eens naar mijn taskfile",
  "task-runner setup", "core.yml", "split-file taskfile", "gen-3 core", "Pattern A/B/C/D".
  Activeer NIET voor algemene `task` CLI vragen, andere build-tools (Make/just/npm scripts),
  of generieke shell-script vragen die niets met Brechts Taskfile-conventies te maken hebben.
---

# Taskfile Architect — skill (dispatcher)

Genereer, audit, fix, standaardiseer en refactor Taskfiles volgens Brechts vastgelegde conventies.
Canonieke basis: **Pattern A** (thin facade + core.yml + project.yml) met **gen-3 core.yml**
(auto-setup, gosh-safe PID-management, multi-iface VPN, env-bootstrap, calcport-driven ports).

Dit bestand is een **dispatcher** — de details staan in modules. Lees de relevante module
op basis van de gekozen modus.

---

## TL;DR — Wat doet deze skill

**Default modus = AUTO** (detecteer + kies passende sub-modus + apply).
Andere modi alleen als user expliciet zegt wat hij wil.

| Modus | Input | Output |
|---|---|---|
| **AUTO** ⭐ default | Bestaande Taskfile of leeg project | Self-detect → kiest NEW/FIX/STANDAARD/REFACTOR + apply |
| **NEW** | Projecttype + naam + technologie | Volledige Taskfile-set (root + taskfiles/) |
| **AUDIT** | Bestaande Taskfile(s) | Score op 100 + ranked findings + concrete fixes (read-only) |
| **FIX** | Bestaande Taskfile + één concreet probleem | Kleine diff op specifieke plek |
| **STANDAARD** | Verouderde Taskfile | Bulk-modernize naar huidige skill-conventies |
| **REFACTOR** | Bestaande Taskfile + specifiek target | Structurele transformatie naar dat target |

**Hard rules** (niet onderhandelbaar — zie `docs/never-do.md`):

- AUTO is de echte default; gebruiker hoeft niet te kiezen
- Pattern A is default voor app-repo's
- Gen-3 core.yml is canoniek — geen gen-1/gen-2 produceren
- Runtime-dir = `.task/`
- `dotenv: ['.env.local', '.env']` (override wint)
- `silent: true` op file-niveau, expliciet `silent: false` op user-facing tasks
- Internal tasks: `_prefix` ÉN `internal: true`
- Single-file boven 500 regels = altijd refactor naar Pattern A
- Calcport-integratie verplicht waar `calcport` beschikbaar is
- gosh-safe: nooit `$!` als PID-bron, altijd `/bin/kill` voor extern gestarte processen

**Volgende concrete stap:** ga direct naar §0 *AUTO-flow* (hieronder) tenzij user een specifieke
modus heeft genoemd.

---

## Activatie

**Wel activeren — natuurlijke triggers met de modus die hieruit volgt:**

| Brecht zegt | Modus | Sub-file |
|---|---|---|
| "Kijk eens naar mijn Taskfile" / "fix mijn taskfile" / "kun je deze opfrissen" / *zonder specifieke verwoording* | **AUTO** ⭐ | (deze SKILL.md §0) |
| "Maak een nieuwe Taskfile voor [project]" | **NEW** | `flows/new.md` |
| "Audit/score deze Taskfile" / "wat is er mis met deze taskfile?" | **AUDIT** | `docs/audit-scoring.md` + `docs/anti-patterns.md` |
| "[Specifiek probleem] fixen" | **FIX** | `flows/fix.md` |
| "Maak hem volledig standaard" / "modernize" | **STANDAARD** | `flows/standard.md` |
| "Splits naar Pattern B" / "upgrade naar gen-3" | **REFACTOR** | `flows/refactor.md` |

**Niet activeren:**
- Algemene `task` CLI gebruiksvragen
- Andere build-tools (Make, just, npm scripts)
- Generieke YAML/shell-script vragen
- Vragen over Anthropic skills i.p.v. `task` runner

---

## Modi-routing — geen vraag stellen, gewoon doen

**Bij activatie: ga direct naar §0 *AUTO-flow* tenzij user expliciet een specifieke modus benoemt.**

Routing-tabel:

| User intent | Lees deze module |
|---|---|
| AUTO (default) | §0 hieronder |
| NEW | `flows/new.md` |
| AUDIT | `docs/audit-scoring.md` + `docs/anti-patterns.md` |
| FIX | `flows/fix.md` |
| STANDAARD | `flows/standard.md` |
| REFACTOR | `flows/refactor.md` |

**Vraag NOOIT "welke modus?" als opener.** AUTO doet zelf de detect.

---

## §0 — AUTO-flow (default modus)

AUTO doet wat een goede senior collega zou doen die jouw conventies kent: kijkt naar de file,
zegt wat moet gebeuren, vraagt confirm op de gevaarlijke dingen, doet de rest.

### Stap 1 — Detect huidige staat

```
GEEN Taskfile gevonden in project root:
  → detect stack via:
    - package.json met "next" dep                  → Next.js profile
    - package.json met "engines.vscode"            → VS Code ext profile
    - package.json zonder bovenstaande             → Node CLI / generic
    - pyproject.toml of requirements.txt           → Python profile
    - .clasp.json                                  → Clasp profile
    - ecosystem.config.js + simpel project         → Server PM2 profile
    - alleen losse scripts/ folder                 → CLI tool / toolbelt
  → ja gedetecteerd  → ga naar Stap 3 met NEW-modus + flows/new.md
  → niet detecteerbaar → vraag projecttype (1 vraag, multiple choice 1–8)

TASKFILE BESTAAT:
  → run interne AUDIT-pass (docs/anti-patterns.md + docs/audit-scoring.md)
  → run verplichte pre-checks uit flows/standard.md Stap 1
  → ga naar Stap 2
```

### Stap 2 — Kies sub-modus op basis van diagnose

| AUDIT-uitkomst | Kies | Confirmation? | Lees |
|---|---|---|---|
| **Score ≥ 90, geen anti-patterns** | toon AUDIT-output, **doe niets** | nee | — |
| **Score 75–89, alleen punctuele issues** | **FIX** alle gevonden issues | toon diffs vooraf, ga door tenzij stop | `flows/fix.md` |
| **Score 50–74, structuur OK, veel drift/naming/tooling** | **STANDAARD** | toon plan, vraag confirm vóór schrijven | `flows/standard.md` |
| **Score < 50, óf Pattern fundamenteel verkeerd, óf gen-1/single-file >500 regels** | **STANDAARD + REFACTOR** (chained) | toon plan + impact, vraag confirm, bewaar `.archive/Taskfile.legacy.yml` | `flows/standard.md` + `flows/refactor.md` |
| **Geen Taskfile + stack gedetecteerd** | **NEW** | vraag alleen onmisbare info | `flows/new.md` |

### Stap 3 — Toon altijd vooraf (behalve bij score 90+)

Format:
```
Ik heb gevonden in [filename]:
- [N anti-patterns]: [korte lijst]
- [X drift items]: [korte lijst]
- [Y missing building blocks]: [korte lijst]

Ik ga uitvoeren: [FIX | STANDAARD | REFACTOR]
Concrete wijzigingen:
1. [...]
2. [...]

Akkoord?
```

### Stap 4 — Apply

Volg de bijhorende sub-file:
- FIX → `flows/fix.md`
- STANDAARD → `flows/standard.md`
- REFACTOR → `flows/refactor.md`
- NEW → `flows/new.md`

### Stap 5 — Diff-samenvatting + volgende stap

Bij REFACTOR/STANDAARD: bewaar oude file als `.archive/Taskfile.legacy.yml`. Toon korte tabel
"wat hernoemd / verplaatst / nieuw". Eindig met één concreet commando: meestal `task doctor`.

### Confirmation-gates (cruciaal)

| Actie | Risico | Confirmation |
|---|---|---|
| AUDIT (read-only output) | nul | nooit |
| NEW (nieuwe files in lege project) | nul | alleen onmisbare info vragen |
| FIX (kleine diffs) | laag | toon diff, ga door tenzij user stopt |
| STANDAARD (bulk modernize) | middel | toon plan vooraf, vraag expliciet confirm |
| REFACTOR (structureel) | hoog | toon plan + impact, vraag expliciet confirm + bewaar legacy |

**AUTO mag niet blind zijn.** Voor middel/hoog risico altijd vooraf tonen wat gaat gebeuren.

---

## Module-index

Lees de bijhorende module just-in-time, niet vooraf alles inladen.

### `flows/` — uitvoerbare flows

| File | Wanneer lezen |
|---|---|
| `flows/new.md` | NEW-modus: nieuw project, geen Taskfile aanwezig |
| `flows/fix.md` | FIX-modus: punctuele aanpassing op één concreet probleem |
| `flows/standard.md` | STANDAARD-modus: bulk-modernize + verplichte pre-checks |
| `flows/refactor.md` | REFACTOR-modus: chirurgische structurele transformatie |

### `docs/` — referentie-documentatie

| File | Wanneer lezen |
|---|---|
| `docs/decision-tree.md` | Pattern A/B/C/D keuze |
| `docs/profiles.md` | 8 projecttype-profielen |
| `docs/gen3-building-blocks.md` | Canonieke gen-3 core.yml + 5 building blocks + gosh-safe design |
| `docs/modules.md` | Optionele modules (db, docker, gh, git, service, prod) |
| `docs/anti-patterns.md` | **Alle 27 anti-patterns** met severiteit, toelichting, fix-snippets |
| `docs/audit-scoring.md` | 100-puntenscoremodel met 9 categorieën |
| `docs/question-strategy.md` | Wanneer wel/niet/wat vragen |
| `docs/fallbacks.md` | Veilige defaults bij ontbrekende info |
| `docs/validation-checklist.md` | Verplichte checks voor elke generatie/refactor |
| `docs/mini-templates.md` | Werkende code-snippets |
| `docs/never-do.md` | Hard NO-lijst |

### `tests/` — validatie

| File | Wanneer lezen |
|---|---|
| `tests/prompts.md` | 12 test-prompts om de skill te valideren |

### `references/` — drop-in materialen

| Folder | Inhoud |
|---|---|
| `references/canonical/` | Next.js gold standard — Taskfile.yml + taskfiles/core.yml + taskfiles/project.yml |
| `references/profiles/python/` | Python (FastAPI/uvicorn + uv + ruff + pytest) drop-in |
| `references/patterns/` | Patroon-fragmenten: multi-service, shared-server-safe, prod-pipeline |

---

## Werkmodus-samenvatting voor Claude

Wanneer geactiveerd:

1. **Default = AUTO.** Voer §0 hierboven uit. Stel geen openings-vraag "welke modus?".
2. Alleen als user expliciet een modus benoemt (Activatie-tabel), lees direct de bijhorende sub-file.
3. **Lees sub-files just-in-time** — niet alles vooraf inladen. SKILL.md geeft de routing,
   sub-files de details.
4. Hard rules zijn niet onderhandelbaar. Geen "wil je dit anders?"-checks op vaste conventies.
5. Confirmation-gates respecteren:
   - AUDIT/NEW/FIX = ga door zonder uitgebreid checken
   - STANDAARD/REFACTOR = toon plan vooraf, vraag expliciet confirm
6. Toon altijd onderaan **één concrete volgende stap** (`task doctor`, `task start`, "commit deze 3 files").
7. Bij twijfel: kies de meest robuuste default uit `docs/fallbacks.md` en vermeld het.
8. Bij conflict tussen gebruikers-voorkeur en hard rule: leg uit waarom de hard rule geldt.
9. ADD-vriendelijk: weinig vragen, veel momentum. Liever proberen + tonen dan questionnaires.
10. Bij elke wijziging aan deze skill: bump versie in frontmatter + entry in `CHANGELOG.md`.

---

## Versionering

Skill volgt [Semver](https://semver.org/) en [Keep a Changelog](https://keepachangelog.com/).

- **MAJOR** (1.0.0 → 2.0.0): breaking change in skill-conventies (nieuwe modus, hard rule wijzigt)
- **MINOR** (1.0.0 → 1.1.0): nieuw profile, nieuwe optionele module, nieuwe anti-pattern, nieuwe drift-correctie
- **PATCH** (1.0.0 → 1.0.1): verduidelijking, typo, kleine bugfix in voorbeeld-snippet

Zie `CHANGELOG.md` voor wijziging-historie.
Voor de pre-refactor monolithische versie zie `skill.legacy.md`.
