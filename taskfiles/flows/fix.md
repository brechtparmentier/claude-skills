<!-- v1.2.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §7A — FIX-flow

Gegeven: bestaande Taskfile + één concreet probleem (van user benoemd, of geïdentificeerd door §5b anti-pattern detectie binnen AUTO).

**Scope:** punctueel. Geen pattern-wijziging, geen file-restructuring. Kleine diffs op specifieke plekken.

**Uitvoeringsregel (sinds v1.2.0):** bij uitvoerend werkwoord ("fix", "pas aan", "verbeter", "herstel") → **direct uitvoeren**, geen "Akkoord?"-vraag. Toon achteraf de diff + validatie volgens `flows/standard.md` §7B.6 Output-regel. Zie AP-35.

**Bestaande-bestanden-regel (sinds v1.2.0):** zie `flows/standard.md` §7B.2. Lees eerst, patch gericht, geen blinde overschrijving. Zie AP-34.

**Stap 1 — Locate** Lees de file, identificeer **exact** waar het probleem zit (regelnummer of task-naam).

**Stap 2 — Diagnose** Eén regel waarom de huidige aanpak faalt of suboptimaal is.

**Stap 3 — Fix** Schrijf vervangende snippet (geen volledige file-rewrite). Pas alleen de relevante regels aan.

**Stap 4 — Verify** Toon de diff (before/after) + concrete test-stap voor de gebruiker (bv. "run `task doctor` om te valideren dat fnm-detectie nu werkt").

**Stap 5 — Suggest gerelateerde** 1-2 vergelijkbare problemen die mogelijk ook bestaan. Alleen melden, niet automatisch fixen tenzij user expliciet vraagt.

**Voorbeelden van FIX-jobs:**

- "VPN-detectie pakt mijn wg0 niet" → vervang `tun0`-grep met multi-iface block uit §4
- "Voeg internal: true toe aan alle _prefix tasks" → loop door file, voeg toe waar mist
- "Doctor checkt uv niet" → voeg `need uv` toe aan doctor-task
- "Hardcoded port vervangen door calcport" → vervang var-block met `sh:`-driven calcport call
- "Maak doctor sneller via parallel checks" → herwrite met `&` + `wait`

**Vo