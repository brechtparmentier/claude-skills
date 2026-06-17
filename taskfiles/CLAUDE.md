# _verzameldeTaskfiles — projectcontext

## Wat is dit?

Deze map bevat twee dingen:

1. **Verzamelde Taskfiles** per server — elke server heeft een submap (`linux-pagaaier/`, `linuxpc92/`, etc.) met Taskfile.yml kopieën en een `index.json`
2. **`skills/`** — de `claude-skills` git-repo (eigen `.git`) met de taskfiles skill en distributiescripts

## claude-skills repo

- GitHub: `https://github.com/brechtparmentier/claude-skills`
- Lokaal: `skills/` submap
- Skill: `skills/taskfiles/` — auditeert en verbetert Taskfile.yml setups (v1.1.1)

### Installeren / updaten

```bash
# Linux of Git Bash Windows:
curl -sL 'https://raw.githubusercontent.com/brechtparmentier/claude-skills/main/install.sh' | bash

# Alle Linux servers tegelijk (vanuit Git Bash):
cd skills && ./update-skills.sh
```

### Servers (SSH-aliassen)

`linuxoptiplexvpn`, `linuxoptiplexpagaaiervpn`, `linuxpc92vpn`, `linodeserver`, `linuxpagaaiervpn`, `linuxgbsodkvpn`, `kubuntunuc`

## Werkomgeving

- Windows host + Remote SSH naar Linux
- VS Code met Copilot (global instructions via `%APPDATA%\Code\User\prompts\`)
- Git Bash voor scripts
