# ─────────────────────────────────────────────────────────────────────────────
# AWS Diagram + Slides Pipeline
# Requirements: d2, marp-cli
#
# Quick start:
#   just check                        verify all tools present
#   just import-icons <icon-pack-dir> one-time icon import from AWS ZIP
#   just icons lambda                 find icon paths by keyword
#   just new-diagram my-arch          scaffold a new diagram
#   just build                        render all diagrams + slides
# ─────────────────────────────────────────────────────────────────────────────

icons_dir  := "aws-icons"
diag_dir   := "diagrams"
slides_dir := "slides"
out_dir    := "output"
d2_layout  := "elk"   # options: elk, dagre, tala (tala requires licence)

# Default: show available recipes
default:
    @just --list

# ── Setup & checks ────────────────────────────────────────────────────────────

# Verify all required tools are installed
check:
    @echo "Checking tools..."
    @command -v d2      >/dev/null 2>&1 || (echo "❌  d2 not found      → https://d2lang.com/tour/install" && exit 1)
    @command -v marp    >/dev/null 2>&1 || (echo "❌  marp not found    → npm install -g @marp-team/marp-cli" && exit 1)
    @echo "✅  All tools available"

# ── Icons ─────────────────────────────────────────────────────────────────────

# Import icons from AWS Architecture Icons ZIP (the extracted directory)
# Downloads: https://aws.amazon.com/architecture/icons/
# Usage: just import-icons ~/Downloads/Icon-package_01302026.../
import-icons source:
    #!/usr/bin/env bash
    set -euo pipefail
    total=0

    # ── Architecture Service Icons (64px) ──
    svc_dir=$(find "{{source}}" -maxdepth 1 -type d -name 'Architecture-Service-Icons*' | head -1)
    if [ -n "$svc_dir" ]; then
        count=0
        for cat_dir in "$svc_dir"/Arch_*/; do
            category=$(basename "$cat_dir" | sed 's/^Arch_//' | tr '[:upper:]' '[:lower:]')
            size_dir="$cat_dir/64"
            [ -d "$size_dir" ] || continue
            mkdir -p "{{icons_dir}}/$category"
            for svg in "$size_dir"/*.svg; do
                [ -f "$svg" ] || continue
                slug=$(basename "$svg" .svg | sed 's/^Arch_//; s/_64$//' | tr '[:upper:]' '[:lower:]')
                cp "$svg" "{{icons_dir}}/$category/$slug.svg"
                count=$((count + 1))
            done
        done
        echo "  Service icons:  $count"
        total=$((total + count))
    fi

    # ── Resource Icons (48px, same category dirs as service) ──
    res_dir=$(find "{{source}}" -maxdepth 1 -type d -name 'Resource-Icons*' | head -1)
    if [ -n "$res_dir" ]; then
        count=0
        for cat_dir in "$res_dir"/Res_*/; do
            category=$(basename "$cat_dir" | sed 's/^Res_//' | tr '[:upper:]' '[:lower:]')
            mkdir -p "{{icons_dir}}/$category"
            for svg in "$cat_dir"/*.svg; do
                [ -f "$svg" ] || continue
                slug=$(basename "$svg" .svg | sed 's/^Res_//; s/_48$//' | tr '[:upper:]' '[:lower:]')
                cp "$svg" "{{icons_dir}}/$category/$slug.svg"
                count=$((count + 1))
            done
        done
        echo "  Resource icons: $count"
        total=$((total + count))
    fi

    # ── Architecture Group Icons (32px, flat dir) ──
    grp_dir=$(find "{{source}}" -maxdepth 1 -type d -name 'Architecture-Group-Icons*' | head -1)
    if [ -n "$grp_dir" ]; then
        count=0
        mkdir -p "{{icons_dir}}/groups"
        for svg in "$grp_dir"/*.svg; do
            [ -f "$svg" ] || continue
            slug=$(basename "$svg" .svg | sed 's/_32$//' | tr '[:upper:]' '[:lower:]')
            cp "$svg" "{{icons_dir}}/groups/$slug.svg"
            count=$((count + 1))
        done
        echo "  Group icons:    $count"
        total=$((total + count))
    fi

    # ── Category Icons (48px) ──
    cat_dir=$(find "{{source}}" -maxdepth 1 -type d -name 'Category-Icons*' | head -1)
    if [ -n "$cat_dir" ]; then
        count=0
        size_dir="$cat_dir/Arch-Category_48"
        if [ -d "$size_dir" ]; then
            mkdir -p "{{icons_dir}}/categories"
            for svg in "$size_dir"/*.svg; do
                [ -f "$svg" ] || continue
                slug=$(basename "$svg" .svg | sed 's/^Arch-Category_//; s/_48$//' | tr '[:upper:]' '[:lower:]')
                cp "$svg" "{{icons_dir}}/categories/$slug.svg"
                count=$((count + 1))
            done
        fi
        echo "  Category icons: $count"
        total=$((total + count))
    fi

    echo "✅  $total icons imported to {{icons_dir}}/"
    just rebuild-catalog

# Rebuild catalog (if you add icons manually)
rebuild-catalog:
    @find {{icons_dir}} \( -name "*.png" -o -name "*.svg" \) \
      | sed "s|^{{icons_dir}}/||" | sort > {{icons_dir}}/catalog.txt
    @echo "Catalog rebuilt: $(wc -l < {{icons_dir}}/catalog.txt) entries"

# List available icons, optionally filtered by keyword
# Usage: just icons           → list all
#        just icons lambda    → filter
icons filter="":
    @if [ -f {{icons_dir}}/catalog.txt ]; then \
        if [ -n "{{filter}}" ]; then \
            grep -i "{{filter}}" {{icons_dir}}/catalog.txt || echo "(no matches for '{{filter}}')"; \
        else \
            cat {{icons_dir}}/catalog.txt; \
        fi \
    else \
        echo "No catalog found — run: just extract-icons <pptx>"; \
    fi

# Show the full icon path ready to paste into a .d2 file
# Usage: just icon-path lambda
icon-path name:
    @grep -i "{{name}}" {{icons_dir}}/catalog.txt \
      | head -10 \
      | sed "s|^|{{icons_dir}}/|" \
      || echo "(no matches for '{{name}}')"

# ── Diagrams ──────────────────────────────────────────────────────────────────

# Scaffold a new diagram from the template
# Usage: just new-diagram my-architecture
new-diagram name:
    @mkdir -p {{diag_dir}}
    @if [ -f {{diag_dir}}/{{name}}.d2 ]; then \
        echo "Already exists: {{diag_dir}}/{{name}}.d2"; \
    else \
        cp {{diag_dir}}/_template.d2 {{diag_dir}}/{{name}}.d2; \
        echo "Created: {{diag_dir}}/{{name}}.d2"; \
    fi

# Render a single diagram → output/diagrams/<name>.svg
# Usage: just diagram my-architecture
diagram name:
    @mkdir -p {{out_dir}}/diagrams
    d2 --layout {{d2_layout}} {{diag_dir}}/{{name}}.d2 {{out_dir}}/diagrams/{{name}}.svg
    @echo "→ {{out_dir}}/diagrams/{{name}}.svg"

# Render all diagrams (skips _template.d2)
build-diagrams:
    @mkdir -p {{out_dir}}/diagrams
    @shopt -s nullglob; \
    for f in {{diag_dir}}/*.d2; do \
        name=$(basename "$f" .d2); \
        [ "$name" = "_template" ] && continue; \
        echo "  → $name.svg"; \
        d2 --layout {{d2_layout}} "$f" {{out_dir}}/diagrams/$name.svg; \
    done

# Watch a single diagram and auto-re-render on save
# Usage: just watch-diagram my-architecture
watch-diagram name:
    d2 --watch --layout {{d2_layout}} {{diag_dir}}/{{name}}.d2 {{out_dir}}/diagrams/{{name}}.svg

# ── Slides ────────────────────────────────────────────────────────────────────

# Build a single deck → HTML
# Usage: just slides my-talk
slides name:
    @mkdir -p {{out_dir}}/slides
    marp {{slides_dir}}/{{name}}.md \
        --output {{out_dir}}/slides/{{name}}.html \
        --allow-local-files
    @echo "→ {{out_dir}}/slides/{{name}}.html"

# Build a single deck → PDF
# Usage: just slides-pdf my-talk
slides-pdf name:
    @mkdir -p {{out_dir}}/slides
    marp {{slides_dir}}/{{name}}.md \
        --output {{out_dir}}/slides/{{name}}.pdf \
        --allow-local-files
    @echo "→ {{out_dir}}/slides/{{name}}.pdf"

# Build all decks → HTML
build-slides:
    @mkdir -p {{out_dir}}/slides
    @shopt -s nullglob; \
    for f in {{slides_dir}}/*.md; do \
        name=$(basename "$f" .md); \
        echo "  → $name.html"; \
        marp "$f" --output {{out_dir}}/slides/$name.html --allow-local-files; \
    done

# Watch a deck (live reload — open output/slides/<name>.html in browser)
# Usage: just watch my-talk
watch name:
    marp --watch \
        {{slides_dir}}/{{name}}.md \
        --output {{out_dir}}/slides/{{name}}.html \
        --allow-local-files

# ── Combo ─────────────────────────────────────────────────────────────────────

# Render a diagram then rebuild the slides that use it
# Usage: just update my-architecture my-talk
update diagram_name slide_name: (diagram diagram_name) (slides slide_name)

# Build everything
build: build-diagrams build-slides

# Delete all output
clean:
    rm -rf {{out_dir}}

# Delete imported icons (to re-import from updated pack)
clean-icons:
    rm -rf {{icons_dir}}
