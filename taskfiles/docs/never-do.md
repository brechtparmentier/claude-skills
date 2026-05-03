<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §12 — Niet doen (hard NO)

De skill mag NOOIT:

- Gen-1 of gen-2 core.yml-structuur produceren (zonder `_ensure-ready`/`_kill-mode`/`_wait-for-endpoint`/`_show-endpoints`/`_bootstrap-env`)
- `tun0` hardcoderen als enige VPN-interface check
- `dotenv: ['.env', '.env.local']` zetten (override wint dan niet)
- Internal tasks zichtbaar laten (= zonder `internal: true`)
- Een single-file Taskfile produceren >500 regels voor een app-repo met start/stop
- Een mega-alias-sectie (>50 regels) toevoegen bij refactor
- Vage "// pas dit aan naar wens"-templates afleveren zonder werkende default
- Een task aanmaken met `silent: true` per task terwijl er geen file-level default staat
- Vragen welke `silent`-instelling de gebruiker wil (vast geregeld)
- Vragen welke runtime-dir (vast `.task/`)
- Hardcoded HOME-paden of server-namen in vars
- Een Pattern C/D Taskfile produceren voor een app met runtime-toggle
- Taskfile produceren zonder `default → help`
- Taskfile produceren zonder `doctor:` task voor een app-repo
- `silent: false` vergeten op `help` of `start`/`stop`/`status` (anders ziet gebruiker niets)
- Backward-compat aliases produceren voor refactor zonder ze te beperken tot max 5

---

