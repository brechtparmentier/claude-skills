<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §8 — Vraagstrategie

**Hoofdregel:** AUTO is default. AUTO stelt zo min mogelijk vragen — alleen waar detect faalt of confirmation nodig is voor middel/hoog risico.

**Hard maximum:** 3 vragen op een rij. Dan eerst genereren/auditen, dan eventueel doorvragen. ADD-vriendelijk.

### Vraag-tabel per modus

| Modus | Eerste vraag (alleen indien nodig) | Tweede | Derde |
|---|---|---|---|
| **AUTO** ⭐ | (geen — detect zelf) | bij score 50–74 of <50: confirm op plan | — |
| **NEW** | Projecttype (1–8) als niet detecteerbaar | Multi-select modules (db/docker/gh/git/service/prod) | Runtime mode (lokaal/docker/toggle) — alleen als niet af te leiden |
| **AUDIT** | (geen — alleen tonen) | — | — |
| **FIX** | (geen — user heeft probleem benoemd) | confirm op diff (impliciet, "ga door tenzij stop") | — |
| **STANDAARD** | (geen — discovery zelf) | confirm op plan vóór schrijven (verplicht) | — |
| **REFACTOR** | Target pattern als niet duidelijk uit prompt | confirm op plan + impact (verplicht) | — |

**Vragen die de skill ALTIJD mag stellen** (als kritiek):
- Confirmation op middel/hoog-risico actie (STANDAARD/REFACTOR plan)
- Projecttype bij NEW als detect faalt
- Stack-specifieke detail (bv. `APP_MODULE` voor Python uvicorn) — alleen als config niet leesbaar is

**Vragen die de skill NOOIT stelt:**
- "Welke modus wil je?" — AUTO is default, gebruik gewoon AUTO
- "Welke `silent` instelling?" — vast (file-level true)
- "Welke runtime-dir?" — altijd `.task/`
- "Welke dotenv-volgorde?" — altijd `['.env.local', '.env']`
- "Moet internal tasks `_prefix` of `internal: true`?" — beide
- "Welke linter/formatter?" — per stack vastgelegd in profile (Python = ruff, etc.)
- Ports voor stacks waar calcport-detectie ze kan vinden — gebruik `ports.json`/calcport eerst

**Bij ambigu user-intent:** liever proberen + tonen dan vragen. ADD-brein wil momentum, niet questionnaires.

---

