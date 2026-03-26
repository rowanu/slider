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
just check                          # verify tools installed
just import-icons <icon-pack-dir>  # one-time icon import from AWS ZIP pack
just icons <keyword>               # search icon catalog
just icon-path <keyword>           # get full path for pasting into .d2 files

just new-diagram <name>            # scaffold from _template.d2 → diagrams/<name>.d2
just diagram <name>                # render single diagram → output/diagrams/<name>.svg
just watch-diagram <name>          # auto-render on save

just slides <name>                 # build slides/<name>.md → output/slides/<name>.html
just slides-pdf <name>             # build to PDF
just watch <name>                  # live-reload slides

just build                         # render all diagrams + slides
just clean                         # delete output/
```

## Architecture

**Pipeline flow:** D2 files → SVG diagrams → referenced in MARP Markdown → HTML/PDF slides.

- `diagrams/*.d2` — D2 diagram source files. `_template.d2` is the scaffold.
- `slides/*.md` — MARP slide decks (Markdown with YAML frontmatter).
- `aws-icons/` — imported SVG icons organized by category. `catalog.txt` is the searchable index.
- `output/diagrams/` — rendered SVGs. `output/slides/` — final HTML/PDF.
- `justfile` — all build recipes. Uses `elk` layout engine for D2 by default.

## D2 Diagram Conventions

- AWS service nodes use `shape: image` with `icon: aws-icons/<category>/<slug>.svg`
- Containers (VPC, account boundaries) use styled groups with `style.stroke` and `style.fill`
- Non-AWS actors use `shape: person`
- Default layout direction is `right`

## MARP Slide Conventions

- Diagrams referenced as `![diagram w:900](../output/diagrams/<name>.svg)` — the `diagram` alt text triggers auto-centering CSS
- `--allow-local-files` is passed automatically by justfile recipes
- Slide styling uses inline CSS in YAML frontmatter (`h1`/`h2` blue, `strong` orange)
