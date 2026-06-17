<!-- v1.2.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §12 — Niet doen (hard NO)

De skill mag NOOIT:

**Structurele / canonical-regels:**

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

**Database / port-regels (sinds v1.2.0):**

- `"5432:5432"` hardcoden in `docker-compose*.yml` wanneer `ports.json` een `database.docker_dev` voorziet — gebruik `"<database.docker_dev>:5432"` (AP-30)
- `DATABASE_URL` met hardcoded `:5432` schrijven wanneer er een projectspecifieke host-poort is (AP-31)
- Port-mapping in slechts één file wijzigen — alle relevante files moeten consistent: `Taskfile.yml`, `core.yml`, `db.yml`, `docker-compose.yml`, `.env.local`, `.env.example`
- `task start` voor Next.js+Prisma laten draaien zonder `db:up` + healthcheck + `prisma generate` ervoor (AP-32)

**Validatie / claim-regels (sinds v1.2.0):**

- "Het werkt" of "alles ok" claimen op basis van alleen `task --list` (= parse-check, geen runtime-check) (AP-33)
- Validatie afsluiten zonder minimaal: `task doctor` + `task db:up` + `task db:status` + `task start` + curl op dev-url
- Bij een gefaalde test doorgaan zonder de fout te tonen + oorzaak + concrete fix te bieden

**Bestaande-bestanden-regel (sinds v1.2.0, AP-34):**

- `package.json` blind overschrijven — eerst lezen, gericht `scripts.*` of `dependencies` patchen
- `docker-compose.yml` blind overschrijven — gerichte patch op `services.postgres.ports` / `services.<app>.environment`
- `.env.local` blind overschrijven — alleen specifieke key-value patches; bewaar comments en niet-relevante regels
- `.env.example` zomaar uitbreiden zonder samenvatting van toegevoegde keys
- Een werkende `Taskfile.yml` of `taskfiles/*.yml` herschrijven terwijl een gerichte patch volstaat — diff < herschrijving

**Gedragsregels (sinds v1.2.0, AP-35):**

- Een akkoord vragen wanneer de gebruiker een uitvoerend werkwoord gebruikt ("maak", "fix", "verbeter", "pas aan", "genereer", "bouw", "herstel") en de actie niet-destructief is
- "Akkoord?" tussenvoegen in een single-prompt FIX of niet-destructieve STANDAARD
- Tijd verspillen aan plan-presentatie bij triviale fixes — direct toepassen, achteraf rapporteren
- De Output-regel overslaan: aan het einde altijd tonen wat gewijzigd is, welke tests gelukt zijn, welke gefaald, en wat de gebruiker nog moet doen (zie `flows/standard.md` Output-regel)

---

