# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A slide-production pipeline combining **MARP** (Markdown → HTML/PDF slides) with **D2** (declarative diagrams) and official **AWS Architecture Icons**. Not a code project — it's a content-authoring toolchain.

## Prerequisites

- `d2` (diagram renderer)
- `marp` (MARP CLI, installed via npm)
- `just` (command runner)

Verify with `just check`.

## Key Commands

```bash
just check                              # verify tools installed
just import-icons <icon-pack-dir>       # one-time icon import from AWS ZIP pack
just icons <keyword>                    # search icon catalog
just icon-path <keyword>                # get full path for pasting into .d2 files

just new-deck <name>                    # scaffold a new deck → decks/<name>/slides.md
just new-diagram <deck> <name>          # scaffold from template → decks/<deck>/<name>.d2
just diagram <deck> <name>              # render single diagram → decks/<deck>/.output/<name>.svg
just watch-diagram <deck> <name>        # auto-render on save

just slides <name>                      # build all diagrams + slides → .output/slides.html
just slides-pdf <name>                  # build to PDF
just watch <name>                       # live-reload slides

just build                              # render all decks
just clean                              # delete all .output/ directories
```

## Architecture

**Pipeline flow:** D2 files → SVG diagrams → referenced in MARP Markdown → HTML/PDF slides.

- `decks/<name>/` — one directory per presentation, containing:
  - `slides.md` — MARP slide deck (Markdown with YAML frontmatter)
  - `*.d2` — D2 diagram source files for this deck
  - `.output/` — rendered SVGs and HTML/PDF (gitignored)
- `templates/_template.d2` — scaffold for new diagrams.
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

## MARP Slide Conventions

- Diagrams referenced as `![diagram w:900](.output/<name>.svg)` — the `diagram` alt text triggers auto-centering CSS
- `--allow-local-files` is passed automatically by justfile recipes
- `just slides` auto-builds all diagrams before rendering slides
- Slide styling uses inline CSS in YAML frontmatter (`h1`/`h2` blue, `strong` orange)
