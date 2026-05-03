# claude-skills

Een verzameling Claude/Cowork/Claude-Code skills voor knowledge work, beheerd door
[@brechtparmentier](https://github.com/brechtparmentier). Gefocust op betrouwbare
defaults, ADD-vriendelijke workflows en multi-machine distributie.

## Beschikbare skills

| Skill | Versie | Status | Doel |
|---|---|---|---|
| [`taskfiles/`](./taskfiles) | 1.1.0 | stable | Genereer, audit, fix, standaardiseer en refactor `Taskfile.yml` volgens vastgelegde conventies (gen-3 core, calcport-driven ports, gosh-safe PID-management) |

## Snelstart — installatie op een machine

### One-liner (alle skills)

```bash
curl -sL https://raw.githubusercontent.com/brechtparmentier/claude-skills/main/install.sh | bash
```

### One-liner (specifieke skill)

```bash
curl -sL https://raw.githubusercontent.com/brechtparmentier/claude-skills/main/install.sh | bash -s taskfiles
```

### Handmatig via git clone

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/brechtparmentier/claude-skills.git ~/.cache/claude-skills
ln -sfn ~/.cache/claude-skills/taskfiles ~/.claude/skills/taskfiles
```

Verifieer:
```bash
ls -la ~/.claude/skills/
grep '^version:' ~/.claude/skills/taskfiles/SKILL.md
```

## Updates

### Per machine

```bash
cd ~/.cache/claude-skills && git pull --rebase
# of opnieuw runnen via install.sh (idempotent):
curl -sL https://raw.githubusercontent.com/brechtparmentier/claude-skills/main/install.sh | bash
```

### Multi-machine sync (vanaf je laptop)

Pas eerst `update-skills.sh` aan met je server-lijst, dan:

```bash
./update-skills.sh
```

## Versionering

Per skill wordt apart geversioneerd via [Semver](https://semver.org/) en
[Keep a Changelog](https://keepachangelog.com/). Tag-format:

- `taskfiles-v1.1.0` — release voor de taskfiles skill
- `<future-skill>-v1.0.0` — release voor toekomstige skills

Elke tag-push triggert een GitHub Action (`.github/workflows/release.yml`) die
automatisch een tarball-archive uploadt naar Releases:

```bash
# Download specifieke skill+versie als tarball
curl -sL https://github.com/brechtparmentier/claude-skills/releases/download/taskfiles-v1.1.0/taskfiles.tar.gz \
  | tar xz -C ~/.claude/skills/
```

## Bestand-conventies binnen elke skill

```
<skill-name>/
├── SKILL.md          dispatcher met YAML frontmatter (name, version, updated, description)
├── CHANGELOG.md      Keep-a-Changelog format
├── README.md         korte uitleg + quick start
├── INSTALL.md        installatie-opties (system-wide, plugin, project-local)
├── flows/            uitvoerbare flows (één markdown per flow)
├── docs/             referentie-documentatie (per onderwerp één markdown)
├── tests/            test-prompts voor validatie
└── references/       drop-in materialen (templates, patroon-fragmenten)
```

Lees de SKILL.md van elke skill voor details.

## Contributing

Deze repo is in eerste instantie voor persoonlijk gebruik. Issues & PRs zijn welkom
maar vragen vooraf afstemming over scope (niet elke skill past in de "betrouwbare
universele basis"-filosofie).

## License

MIT — zie [`LICENSE`](./LICENSE).
