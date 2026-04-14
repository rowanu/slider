# ─────────────────────────────────────────────────────────────────────────────
# AWS Diagram + Slides Pipeline
# Requirements: d2, marp-cli
#
# Quick start:
#   just check                              verify all tools present
#   just import-icons <icon-pack-dir>       one-time icon import from AWS ZIP
#   just icons lambda                       find icon paths by keyword
#   just new-deck my-talk                   scaffold a new deck
#   just build                              render all decks
# ─────────────────────────────────────────────────────────────────────────────

icons_dir  := "aws-icons"
decks_dir  := "decks"
output_dir := "output"
template   := "templates/_template.d2"
d2_layout  := "elk"
browser    := env("MARP_BROWSER", env("CHROME_PATH", ""))
brave_path := "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"

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

[private]
ensure-symlink:
    @[ -L {{decks_dir}}/aws-icons ] || ln -s ../{{icons_dir}} {{decks_dir}}/aws-icons

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

# Search icons and output paths ready to paste into .d2 files
# Usage: just icons           → list all
#        just icons lambda    → filter
icons filter="":
    @if [ -f {{icons_dir}}/catalog.txt ]; then \
        if [ -n "{{filter}}" ]; then \
            grep -i "{{filter}}" {{icons_dir}}/catalog.txt | sed "s|^|../{{icons_dir}}/|" || echo "(no matches for '{{filter}}')"; \
        else \
            sed "s|^|../{{icons_dir}}/|" {{icons_dir}}/catalog.txt; \
        fi \
    else \
        echo "No catalog found — run: just import-icons <icon-pack-dir>"; \
    fi

# ── Decks ────────────────────────────────────────────────────────────────────

# Scaffold a new deck
# Usage: just new-deck my-talk         (light theme, default)
#        just new-deck my-talk dark     (dark theme)
new-deck name theme="light": ensure-symlink
    #!/usr/bin/env bash
    set -euo pipefail
    deck="{{decks_dir}}/{{name}}"
    if [ -f "$deck/slides.md" ]; then
        echo "Already exists: $deck/slides.md"
        exit 0
    fi
    mkdir -p "$deck/images"
    # Copy theme CSS
    if [ -f "templates/{{theme}}.css" ]; then
        cp "templates/{{theme}}.css" "$deck/theme.css"
    else
        echo "Unknown theme: {{theme}} (available: light, dark)"
        exit 1
    fi
    # Copy template images
    if [ -d templates/images ]; then
        cp templates/images/* "$deck/images/" 2>/dev/null || true
    fi
    # Copy and customize slides template
    sed "s/DECK_NAME/{{name}}/" templates/slides.md > "$deck/slides.md"
    # Update theme reference in frontmatter to match CSS
    theme_name=$(grep -o '/\* @theme [^ ]*' "$deck/theme.css" | awk '{print $3}')
    [ -n "$theme_name" ] && sed -i '' "s/^theme: .*/theme: $theme_name/" "$deck/slides.md"
    echo "Created: $deck/ (theme: {{theme}})"

# Switch a deck's theme
# Usage: just theme my-talk dark
theme deck variant="light":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f "templates/{{variant}}.css" ]; then
        echo "Unknown theme: {{variant}} (available: light, dark)"
        exit 1
    fi
    cp "templates/{{variant}}.css" "{{decks_dir}}/{{deck}}/theme.css"
    theme_name=$(grep -o '/\* @theme [^ ]*' "{{decks_dir}}/{{deck}}/theme.css" | awk '{print $3}')
    [ -n "$theme_name" ] && sed -i '' "s/^theme: .*/theme: $theme_name/" "{{decks_dir}}/{{deck}}/slides.md"
    echo "→ {{deck}} now uses {{variant}} theme"

# Add a new diagram to a deck from the template
# Usage: just new-diagram my-talk my-architecture
new-diagram deck name: ensure-symlink
    @if [ ! -d {{decks_dir}}/{{deck}} ]; then \
        echo "Deck not found: {{decks_dir}}/{{deck}} — run: just new-deck {{deck}}"; \
        exit 1; \
    fi
    @if [ -f {{decks_dir}}/{{deck}}/{{name}}.d2 ]; then \
        echo "Already exists: {{decks_dir}}/{{deck}}/{{name}}.d2"; \
    else \
        cp {{template}} {{decks_dir}}/{{deck}}/{{name}}.d2; \
        echo "Created: {{decks_dir}}/{{deck}}/{{name}}.d2"; \
    fi

# ── Diagrams ──────────────────────────────────────────────────────────────────

# Render a single diagram
# Usage: just diagram my-talk my-architecture
diagram deck name: ensure-symlink
    @mkdir -p {{output_dir}}/{{deck}}
    d2 --layout {{d2_layout}} {{decks_dir}}/{{deck}}/{{name}}.d2 {{output_dir}}/{{deck}}/{{name}}.svg
    @echo "→ {{output_dir}}/{{deck}}/{{name}}.svg"

# Render all diagrams in a deck
build-diagrams deck: ensure-symlink
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    mkdir -p {{output_dir}}/{{deck}}
    for f in {{decks_dir}}/{{deck}}/*.d2; do
        name=$(basename "$f" .d2)
        echo "  → $name.svg"
        if [ -d {{decks_dir}}/{{deck}}/images ]; then
            d2 --layout {{d2_layout}} "$f" {{decks_dir}}/{{deck}}/images/$name.svg
        else
            d2 --layout {{d2_layout}} "$f" {{output_dir}}/{{deck}}/$name.svg
        fi
    done

# Watch a diagram and auto-re-render on save
# Usage: just watch-diagram my-talk my-architecture
watch-diagram deck name: ensure-symlink
    d2 --watch --layout {{d2_layout}} \
        {{decks_dir}}/{{deck}}/{{name}}.d2 \
        {{output_dir}}/{{deck}}/{{name}}.svg

# Copy images directory to output (if it exists in the deck)
# Depends on build-diagrams so rendered SVGs are in images/ before copying
[private]
copy-images deck: (build-diagrams deck)
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d {{decks_dir}}/{{deck}}/images ]; then
        rm -rf {{output_dir}}/{{deck}}/images
        cp -r {{decks_dir}}/{{deck}}/images {{output_dir}}/{{deck}}/images
    fi

# ── Slides ────────────────────────────────────────────────────────────────────

# Build a deck → HTML (renders diagrams first)
# Usage: just slides my-talk
slides name: (copy-images name)
    #!/usr/bin/env bash
    set -euo pipefail
    theme_flag=""
    css=$(find {{decks_dir}}/{{name}} -maxdepth 1 -name '*.css' | head -1)
    [ -n "$css" ] && theme_flag="--theme $css"
    marp {{decks_dir}}/{{name}}/slides.md \
        --output {{output_dir}}/{{name}}/slides.html \
        --allow-local-files $theme_flag
    echo "→ {{output_dir}}/{{name}}/slides.html"

# Build a deck with browser rendering (PDF/PPTX need a Chromium browser)
[private]
marp-render name ext: (copy-images name)
    #!/usr/bin/env bash
    set -euo pipefail
    args=({{decks_dir}}/{{name}}/slides.md --output {{output_dir}}/{{name}}/slides.{{ext}} --allow-local-files)
    css=$(find {{decks_dir}}/{{name}} -maxdepth 1 -name '*.css' | head -1)
    [ -n "$css" ] && args+=(--theme "$css")
    browser="{{browser}}"
    if [ -z "$browser" ] && [ -x "{{brave_path}}" ]; then
        browser="{{brave_path}}"
    fi
    [ -n "$browser" ] && args+=(--browser-path "$browser")
    marp "${args[@]}"
    echo "→ {{output_dir}}/{{name}}/slides.{{ext}}"

# Build a deck → PDF (renders diagrams first)
# Usage: just slides-pdf my-talk
slides-pdf name: (marp-render name "pdf")

# Build a deck → PPTX (renders diagrams first)
# Usage: just slides-pptx my-talk
slides-pptx name: (marp-render name "pptx")

# Watch a deck (live reload — open .output/slides.html in browser)
# Usage: just watch my-talk
watch name: (copy-images name)
    #!/usr/bin/env bash
    set -euo pipefail
    theme_flag=""
    css=$(find {{decks_dir}}/{{name}} -maxdepth 1 -name '*.css' | head -1)
    [ -n "$css" ] && theme_flag="--theme $css"
    marp --watch \
        {{decks_dir}}/{{name}}/slides.md \
        --output {{output_dir}}/{{name}}/slides.html \
        --allow-local-files $theme_flag

# ── Combo ─────────────────────────────────────────────────────────────────────

# Build everything
build: ensure-symlink
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    for deck_dir in {{decks_dir}}/*/; do
        [ -L "${deck_dir%/}" ] && continue
        name=$(basename "$deck_dir")
        echo "Building deck: $name"
        just build-diagrams "$name"
        if [ -f "$deck_dir/slides.md" ]; then
            just slides "$name"
        fi
    done

# Delete all rendered output
clean:
    rm -rf {{output_dir}}/
    echo "Cleaned {{output_dir}}/"

# Delete imported icons (to re-import from updated pack)
clean-icons:
    rm -rf {{icons_dir}}
