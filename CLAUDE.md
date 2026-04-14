# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A slide-production pipeline combining **MARP** (Markdown → HTML/PDF slides) with **D2** (declarative diagrams) and official **AWS Architecture Icons**. Not a code project — it's a content-authoring toolchain.

## Prerequisites

- `d2` (diagram renderer)
- `marp` (MARP CLI, installed via npm)
- `just` (command runner)

Verify with `just check`. PDF/PPTX output requires a Chromium browser — justfile auto-detects Brave, or set `MARP_BROWSER`/`CHROME_PATH`.

## Key Commands

```bash
just check                              # verify tools installed
just import-icons <icon-pack-dir>       # one-time icon import from AWS ZIP pack
just icons <keyword>                    # search icons, output paste-ready paths

just new-deck <name>                    # scaffold a new deck → decks/<name>/slides.md
just new-deck <name> dark               # scaffold with dark theme
just theme <deck> dark                  # switch a deck's theme (light/dark)
just new-diagram <deck> <name>          # scaffold from template → decks/<deck>/<name>.d2
just diagram <deck> <name>              # render single diagram → output/<deck>/<name>.svg
just watch-diagram <deck> <name>        # auto-render on save

just slides <name>                      # build all diagrams + slides → output/<name>/slides.html
just slides-pdf <name>                  # build to PDF
just slides-pptx <name>                 # build to PPTX
just watch <name>                       # live-reload slides

just build                              # render all decks
just clean                              # delete output/ directory
```

## Architecture

**Pipeline flow:** D2 files → SVG diagrams → referenced in MARP Markdown → HTML/PDF slides.

- `decks/<name>/` — one directory per presentation, containing:
  - `slides.md` — MARP slide deck (Markdown with YAML frontmatter)
  - `*.d2` — D2 diagram source files for this deck
  - `images/` — (optional) static images + rendered diagram SVGs. When this dir exists, `build-diagrams` renders SVGs here instead of `output/`.
  - `theme.css` — deck-specific MARP theme (created by `new-deck`, switchable with `just theme`)
- `output/<name>/` — rendered SVGs (when no `images/` dir) and HTML/PDF per deck (gitignored)
- `templates/` — `_template.d2` scaffold, `slides.md` template, `light.css`/`dark.css` themes, shared `images/`
- `aws-icons/` — imported SVG icons at project root. `catalog.txt` is the searchable index.
  - `<category>/` — service icons (64px) and resource icons (48px) colocated by category
  - `groups/` — group icons (VPC, subnet, account boundaries)
  - `categories/` — top-level category icons
- `decks/aws-icons` — symlink to `../aws-icons` (auto-created by justfile)
- `justfile` — all build recipes. Uses `elk` layout engine for D2 by default.

## D2 Diagram Conventions

- AWS service nodes use `shape: image` with `icon: ../aws-icons/<category>/<slug>.svg` (resolves via symlink)
- Containers (VPC, account boundaries) use styled groups with `style.stroke` and `style.fill`
- Non-AWS actors use `shape: person`
- Default layout direction is `right`
- Connections: `->` one-way, `<->` bidirectional; dashed lines via `style.stroke-dash: 4` (for logging/monitoring flows)
- Container color conventions used in examples:
  - AWS account boundary: stroke `#232F3E`, fill `#FAFAFA`
  - Agent/compute layer: stroke `#FF9900`, fill `#FFF8F0`
  - Data layer: stroke `#3F8624`, fill `#F0FFF0`
  - Security layer: stroke `#DD344C`, fill `#FFF5F5`

### D2 Quick Reference

```d2
# AWS service node
lambda: "Lambda" {
  shape: image
  icon: ../aws-icons/compute/aws-lambda.svg
}

# Container (VPC, account, subnet)
vpc: "My VPC" {
  style.stroke: "#232F3E"
  style.fill: "#F8F8F8"
  service_inside: "Service" {
    shape: image
    icon: ../aws-icons/...
  }
}

# Connections
client -> api: "HTTPS"
lambda <-> dynamo: "read/write"
cloudtrail -> lambda { style.stroke-dash: 4 }
```

Use `just icons <keyword>` to find paste-ready icon paths for `.d2` files.

## MARP Slide Conventions

- **Diagram image paths** depend on where SVGs live:
  - Decks with `images/` dir (e.g. summit): `![w:900](images/<name>.svg)` — relative to deck
  - Decks without `images/` dir: `![diagram w:900](../../output/<deck>/<name>.svg)`
- The `diagram` alt text triggers auto-centering CSS in the default themes. Use `w:700` for diagrams needing more whitespace.
- `--allow-local-files` is passed automatically by justfile recipes
- `just slides` auto-builds all diagrams before rendering slides
- Slide classes via `<!-- _class: <name> -->` — default themes provide `title`; custom deck CSS (like summit's) can define additional classes (`divider`, `title-dark`, etc.)
- Default theme styling: `h1`/`h2` are blue (`#1836b2`), `strong` is orange (`#ff914d`), `h2` has an orange bottom border. Dark theme uses blue `#6ea8fe` instead.
- Decks can use fully custom CSS (see `decks/summit/aws-summit-sydney.css`) — set the theme name in both the CSS `/* @theme name */` comment and slides frontmatter `theme: name`
