<!-- v1.0.0 — 2026-05-03 -->
<!-- Onderdeel van: taskfiles skill — zie SKILL.md voor index -->

## §4 — Gen-3 core.yml canoniek

**De canonieke template staat als drop-in bestand in `references/canonical/`.**

Bron-identificatie: `linuxoptiplexvpn/nextjs_frontend-gdriverights/` is de meest geavanceerde gen-3 in Brechts collectie (774 regels core.yml, 8 internal building blocks, HTTPS-aware, `nmcli`-gebaseerde 4-laags VPN-detectie, mtime-auto-setup, openssl SAN-check). Zie `references/README.md` voor de volledige feature-matrix versus alternatieven.

**Werkmodus van de skill:**

1. Bij NEW: kopieer alle drie de files uit `references/canonical/` naar het doelproject:
   - `Taskfile.yml` → repo root
   - `taskfiles/core.yml`
   - `taskfiles/project.yml`
2. Pas alle vars aan volgens **Customization-checklist** in `references/README.md`
3. Pas de twee bekende drift-correcties toe (zie §10):
   - `dotenv: ['.env', '.env.local']` → `['.env.local', '.env']`
   - `RUNTIME_DIR: .taskrun` → `.task`
4. Voeg stack-specifieke `doctor:` checks toe in `project.yml`

**De vijf verplichte gen-3 internal building blocks** (in elke variant van core.yml die deze skill produceert):

| Building block | Doel | gosh-safe? |
|---|---|---|
| `_ensure-ready` | mtime-vergelijking lockfile ↔ deps marker → auto `task setup` | n.v.t. |
| `_kill-mode` | PID-bestand → `/bin/kill` → fuser orphan-cleanup op poort | **ja** (zie AP-22) |
| `_wait-for-endpoint` | curl-polling met SCHEME-detect, configurable timeout | n.v.t. |
| `_show-endpoints` | multi-iface VPN-detectie + lokale + vpn endpoint-test | n.v.t. |
| `_bootstrap-env` | `.env.example` → `.env.local` fallback chain | n.v.t. |

**gosh-safe design** (kritiek — niet wijzigen tenzij je weet wat je doet):

`start:` slaat **nooit** `$!` op als PID. In plaats daarvan wacht hij op endpoint-up via `_wait-for-endpoint` en leest dan de echte PID via `fuser PORT/tcp` (zie AP-21). Dit omzeilt de go-task gosh-bug waarbij `$!` `g1` retourneert i.p.v. een numerieke PID.

`_kill-mode` gebruikt expliciet `/bin/kill` (niet shell-builtin `kill`) omdat gosh's builtin `kill` alleen werkt voor jobs in zijn eigen tabel — niet voor `nohup`-gestarte processen die naar systemd reparented zijn (zie AP-22).

Header-comment-conventie boven `start:` en `_kill-mode:` in elke gegenereerde core.yml:
```yaml
# gosh-safe: vermijdt $! als PID-bron (gebruikt fuser na _wait-for-endpoint)
#            gebruikt /bin/kill expliciet (gosh kill-builtin pakt geen externe PIDs)
```

**Daarnaast 3 patroon-fragmenten** voor specifieke project-types (in `references/patterns/`):

| Bestand | Wanneer toepassen |
|---|---|
| `core-multi-service.yml` | Project met >1 langlopend service-proces (backend+frontend parallel). Neem over: aparte PID/log vars per service, `_stop:service` met parameter, **PGID-kill** voor orphan-children |
| `core-shared-server-safe.yml` | Project op shared server. Neem over: `stop_if_owned` met `/proc/$PID/cwd` check vóór killen |
| `core-prod-pipeline.yml` | Project met parallelle prod-stack (eigen ports/PIDs/logs naast dev). Neem over: `PROD_BACKEND_PID/PGID/LOG` vars, externe `./scripts/stop_service.sh`, `prod:rebuild` |

**Skeleton voor wie geen toegang heeft tot `references/canonical/`** (bv. wanneer de skill in een andere context wordt gebruikt zonder de referentie-files):

```yaml
version: '3'
silent: true

vars:
  APP_NAME: '{{default "<app-name>" .APP_NAME}}'
  FRONTEND_PORT: '{{default "<port>" .FRONTEND_PORT}}'
  USE_DOCKER: '{{default "0" .USE_DOCKER}}'
  DEV_CMD: '{{default "<dev-cmd>" .DEV_CMD}}'
  STOP_CMD: '{{default "" .STOP_CMD}}'
  RESTART_CMD: '{{default "" .RESTART_CMD}}'
  LOGS_CMD: '{{default "tail -f .task/logs/dev.log" .LOGS_CMD}}'
  STATUS_CMD: '{{default "" .STATUS_CMD}}'
  DOCKER_SERVICE: '{{default "" .DOCKER_SERVICE}}'
  RUNTIME_DIR: '{{default ".task" .RUNTIME_DIR}}'
  LOGS_DIR: '{{default ".task/logs" .LOGS_DIR}}'
  START_TIMEOUT: '{{default "30" .START_TIMEOUT}}'
  STOP_TIMEOUT: '{{default "15" .STOP_TIMEOUT}}'
  VPN_IP: '{{default "" .VPN_IP}}'
  GREEN: '\033[32m'
  YELLOW: '\033[1;33m'
  CYAN: '\033[1;36m'
  RED: '\033[31m'
  RESET: '\033[0m'

tasks:
  # ── User-facing lifecycle ─────────────────────────────────────────
  help:
    desc: Show core help
    silent: false
    cmds:
      - task: _show-endpoints
      # printf-stijl help met dynamische url/mode/ports
      - |
        printf "{{.CYAN}}=== {{.APP_NAME}} ==={{.RESET}}\n"
        printf "{{.YELLOW}}Lifecycle:{{.RESET}}\n"
        printf "  {{.GREEN}}task start{{.RESET}}     start app\n"
        printf "  {{.GREEN}}task stop{{.RESET}}      stop app\n"
        printf "  {{.GREEN}}task restart{{.RESET}}   restart app\n"
        printf "  {{.GREEN}}task logs{{.RESET}}      tail logs\n"
        printf "  {{.GREEN}}task status{{.RESET}}    runtime status\n"
        printf "  {{.GREEN}}task doctor{{.RESET}}    diagnose tooling\n"

  start:
    desc: Start app (docker or local)
    silent: false
    cmds:
      - task: _ensure-dirs
      - task: _ensure-ready
      - task: _bootstrap-env
      - task: _start-impl
      - task: _wait-for-endpoint
      - task: _show-endpoints

  stop:
    desc: Stop app
    silent: false
    cmds:
      - task: _kill-mode

  restart:
    desc: Restart app
    silent: false
    cmds:
      - task: stop
      - task: start

  logs:
    desc: Follow logs
    silent: false
    cmds:
      - task: _logs-impl

  status:
    desc: Runtime status
    silent: false
    cmds:
      - task: _status-impl
      - task: _show-endpoints

  doctor:
    desc: Diagnose tooling and env
    silent: false
    cmds:
      # check required tools, env files, runtime dir, ports — exit non-zero on critical issues
      - task: _doctor-impl

  # ── Internal building blocks (niet aanpassen tenzij echt nodig) ───
  _ensure-dirs:
    internal: true
    cmds:
      - mkdir -p {{.RUNTIME_DIR}} {{.LOGS_DIR}}

  _ensure-ready:
    internal: true
    # Auto-setup detection: vergelijk lockfile mtime met installed deps marker.
    # Trigger `task setup` als out-of-date.
    cmds:
      - |
        # Pseudo-implementatie: vergelijk mtimes, run setup indien nodig.
        # Concrete check varieert per stack (pnpm/uv/poetry/npm).
        true

  _bootstrap-env:
    internal: true
    cmds:
      - |
        if [ ! -f .env.local ] && [ -f .env.example ]; then
          cp .env.example .env.local
          printf "{{.YELLOW}}[INIT]{{.RESET}} .env.local aangemaakt vanuit .env.example\n"
        fi

  _kill-mode:
    internal: true
    # PID-file → fuser orphan-cleanup → docker compose down
    env:
      _USE_DOCKER: '{{.USE_DOCKER}}'
      _STOP_CMD: '{{.STOP_CMD}}'
      _FRONTEND_PORT: '{{.FRONTEND_PORT}}'
      _RUNTIME_DIR: '{{.RUNTIME_DIR}}'
      _STOP_TIMEOUT: '{{.STOP_TIMEOUT}}'
    cmds:
      - |
        if [ "${_USE_DOCKER}" = "1" ]; then
          docker compose down
          exit 0
        fi
        # Try graceful via STOP_CMD or PID-file, fallback fuser on port
        if [ -n "${_STOP_CMD}" ]; then
          sh -c "${_STOP_CMD}" || true
        fi
        if [ -f "${_RUNTIME_DIR}/dev.pid" ]; then
          PID=$(cat "${_RUNTIME_DIR}/dev.pid")
          kill -TERM "$PID" 2>/dev/null || true
          for i in $(seq 1 ${_STOP_TIMEOUT}); do
            kill -0 "$PID" 2>/dev/null || break
            sleep 1
          done
          kill -KILL "$PID" 2>/dev/null || true
          rm -f "${_RUNTIME_DIR}/dev.pid"
        fi
        # Final fallback: fuser orphan cleanup op poort
        fuser -k "${_FRONTEND_PORT}/tcp" 2>/dev/null || true

  _wait-for-endpoint:
    internal: true
    env:
      _PORT: '{{.FRONTEND_PORT}}'
      _TIMEOUT: '{{.START_TIMEOUT}}'
    cmds:
      - |
        SCHEME="http"
        if [ -f .cert/local.crt ] || [ -n "${HTTPS:-}" ]; then SCHEME="https"; fi
        URL="${SCHEME}://localhost:${_PORT}"
        for i in $(seq 1 ${_TIMEOUT}); do
          if curl -sk -o /dev/null -w "%{http_code}" "${URL}" | grep -qE '^(200|3..|404)'; then
            printf "{{.GREEN}}[OK]{{.RESET}} endpoint ready: %s\n" "${URL}"
            exit 0
          fi
          sleep 1
        done
        printf "{{.YELLOW}}[WARN]{{.RESET}} endpoint niet bereikbaar binnen ${_TIMEOUT}s\n"

  _show-endpoints:
    internal: true
    env:
      _PORT: '{{.FRONTEND_PORT}}'
      _VPN_IP: '{{.VPN_IP}}'
    cmds:
      - |
        # Multi-iface VPN-detectie:
        # 1) nmcli connected wireguard|vpn|tun|tap
        # 2) ip -o -4 addr op tun|tap|wg|tailscale|ppp|utun|zt|vpn
        # 3) ip -o -4 addr met RFC1918, exclude lo|docker|br-|veth|virbr|en|eth|wl|wwan
        # 4) override via VPN_IP env
        detect_vpn_ip() {
          if [ -n "${_VPN_IP}" ]; then echo "${_VPN_IP}"; return; fi
          if command -v nmcli >/dev/null 2>&1; then
            IF=$(nmcli -t -f NAME,TYPE,DEVICE c show --active 2>/dev/null \
                 | awk -F: '$2 ~ /wireguard|vpn|tun|tap/ {print $3; exit}')
            if [ -n "$IF" ]; then
              IP=$(ip -o -4 addr show "$IF" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)
              [ -n "$IP" ] && echo "$IP" && return
            fi
          fi
          IP=$(ip -o -4 addr show 2>/dev/null \
               | awk '$2 ~ /^(tun|tap|wg|tailscale|ppp|utun|zt|vpn)/ {print $4}' \
               | cut -d/ -f1 | head -1)
          if [ -n "$IP" ]; then echo "$IP"; return; fi
          # RFC1918 fallback
          ip -o -4 addr show 2>/dev/null \
            | awk '$2 !~ /^(lo|docker|br-|veth|virbr|en|eth|wl|wwan)/ {print $4}' \
            | cut -d/ -f1 \
            | grep -E '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)' \
            | head -1
        }
        VPN=$(detect_vpn_ip)
        printf "{{.YELLOW}}url:{{.RESET}}    http://localhost:%s\n" "${_PORT}"
        if [ -n "$VPN" ]; then
          printf "{{.YELLOW}}vpn:{{.RESET}}    http://%s:%s\n" "$VPN" "${_PORT}"
        fi

  _start-impl:
    internal: true
    env:
      _USE_DOCKER: '{{.USE_DOCKER}}'
      _DEV_CMD: '{{.DEV_CMD}}'
      _RUNTIME_DIR: '{{.RUNTIME_DIR}}'
      _LOGS_DIR: '{{.LOGS_DIR}}'
    cmds:
      - |
        if [ "${_USE_DOCKER}" = "1" ]; then
          docker compose up -d
          exit 0
        fi
        # Local: start dev cmd in background, write PID
        nohup sh -c "${_DEV_CMD}" >"${_LOGS_DIR}/dev.log" 2>&1 &
        echo $! > "${_RUNTIME_DIR}/dev.pid"

  _logs-impl:
    internal: true
    env:
      _USE_DOCKER: '{{.USE_DOCKER}}'
      _LOGS_CMD: '{{.LOGS_CMD}}'
      _DOCKER_SERVICE: '{{.DOCKER_SERVICE}}'
    cmds:
      - |
        if [ "${_USE_DOCKER}" = "1" ]; then
          if [ -n "${_DOCKER_SERVICE}" ]; then
            docker compose logs -f "${_DOCKER_SERVICE}"
          else
            docker compose logs -f
          fi
          exit 0
        fi
        sh -c "${_LOGS_CMD}"

  _status-impl:
    internal: true
    env:
      _USE_DOCKER: '{{.USE_DOCKER}}'
      _STATUS_CMD: '{{.STATUS_CMD}}'
      _RUNTIME_DIR: '{{.RUNTIME_DIR}}'
    cmds:
      - |
        if [ "${_USE_DOCKER}" = "1" ]; then docker compose ps; exit 0; fi
        if [ -n "${_STATUS_CMD}" ]; then sh -c "${_STATUS_CMD}"; exit 0; fi
        if [ -f "${_RUNTIME_DIR}/dev.pid" ]; then
          PID=$(cat "${_RUNTIME_DIR}/dev.pid")
          if kill -0 "$PID" 2>/dev/null; then
            printf "{{.GREEN}}[OK]{{.RESET}} running (pid %s)\n" "$PID"
          else
            printf "{{.RED}}[X]{{.RESET}} pid-file aanwezig maar proces dood\n"
          fi
        else
          printf "{{.YELLOW}}[--]{{.RESET}} not running\n"
        fi

  _doctor-impl:
    internal: true
    cmds:
      - |
        FAIL=0
        check() {
          if command -v "$1" >/dev/null 2>&1; then
            printf "{{.GREEN}}[OK]{{.RESET}} %s\n" "$1"
          else
            printf "{{.RED}}[X]{{.RESET}} %s ontbreekt\n" "$1"
            FAIL=1
          fi
        }
        # stack-specifieke tools (vul aan via project.yml)
        check task
        check git
        # check env
        if [ ! -f .env.local ] && [ ! -f .env ]; then
          printf "{{.YELLOW}}[!]{{.RESET}} geen .env.local of .env gevonden\n"
        fi
        exit $FAIL
```

**Belangrijk**: stack-specifieke tooling-checks (pnpm, uv, prisma, ...) gaan in `project.yml`'s `doctor:` task die `core:doctor` aanvult, **niet** in core.yml.

---

