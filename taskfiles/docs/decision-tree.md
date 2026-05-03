<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §2 — Beslisboom Pattern A/B/C/D

```
Heeft project een runtime (start/stop/logs/status)?
├── Nee → Is het een wrapper rond 1 CLI tool met <15 commands?
│         ├── Ja → PATTERN D (single-file minimaal)
│         └── Nee → PATTERN C (single-file met namespaces)
└── Ja  → Heeft project >2 distincte concern-groepen
          (db + docker + git + monitoring + prod)?
         ├── Ja → PATTERN B (split-file + extra namespace-includes)
         └── Nee → PATTERN A (split-file: core.yml + project.yml)  ← DEFAULT
```

**Hard rules:**
- Single-file boven 500 regels → altijd Pattern A. Geen uitzonderingen.
- App-repo met start/stop → nooit Pattern C of D.
- Pure CLI-wrapper (clasp push/pull, audit-scripts) → nooit Pattern A. Pattern D.

---

