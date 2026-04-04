# AWS Diagram + Slides Pipeline

MARP slide production with D2 architecture diagrams using official AWS icons.

## Prerequisites

```bash
# D2
curl -fsSL https://d2lang.com/install.sh | sh

# MARP CLI
npm install -g @marp-team/marp-cli

# Verify everything
just check
```

## One-time: import icons

Download the [AWS Architecture Icons](https://aws.amazon.com/architecture/icons/) asset package ZIP,
then unzip it and point at the extracted directory:

```bash
just import-icons ~/Downloads/Icon-package_01302026.../
```

Icons are organized into `aws-icons/` by type:
- **Service + Resource icons** → `aws-icons/<category>/` (e.g. `compute/`, `storage/`)
- **Group icons** (VPC, subnet, account boundaries) → `aws-icons/groups/`
- **Category icons** → `aws-icons/categories/`

Re-run when AWS releases an updated icon pack.

## Daily workflow

```bash
# Find the icon path you need
just icons lambda
just icons "api gateway"

# Start a new deck
just new-deck my-talk
# edit decks/my-talk/slides.md

# Add a diagram to a deck
just new-diagram my-talk my-architecture
# edit decks/my-talk/my-architecture.d2

# Render while editing
just watch-diagram my-talk my-architecture

# Build + preview slides (auto-renders diagrams first)
just slides my-talk
# open decks/my-talk/.output/slides.html

# Or watch slides
just watch my-talk

# Build everything
just build
```

## Referencing diagrams in MARP

After `just diagram <deck> <name>` renders the SVG into `.output/`:

```markdown
![diagram w:900](.output/<name>.svg)
```

`--allow-local-files` is passed automatically by the justfile recipes.

## D2 quick reference

```d2
# AWS service node (just icon + label)
lambda: "Lambda" {
  shape: image
  icon: ../aws-icons/compute/aws-lambda.svg
}

# Container (VPC, account, subnet)
vpc: "My VPC" {
  style.stroke: "#232F3E"
  lambda: "Lambda" {
    shape: image
    icon: ../aws-icons/compute/aws-lambda.svg
  }
}

# Connections
client -> lambda: "invoke"
lambda <-> dynamo: "read/write"

# Dashed line (logging, monitoring)
cloudtrail -> lambda { style.stroke-dash: 4 }

# Layout direction
direction: right   # or: down (default), left, up
```

Icon paths use `../aws-icons/...` which resolves via a symlink at `decks/aws-icons → ../aws-icons` (auto-created by the justfile).

## Directory structure

```
.
├── justfile
├── aws-icons/              # imported icons (gitignore if large)
│   ├── catalog.txt         # searchable index
│   ├── compute/            # service + resource icons per category
│   │   ├── aws-lambda.svg
│   │   └── amazon-ec2_instance.svg
│   ├── groups/             # VPC, subnet, account boundaries
│   └── categories/         # top-level category icons
├── templates/
│   └── _template.d2        # scaffold for new diagrams
├── decks/
│   ├── aws-icons -> ../aws-icons   # symlink (auto-created)
│   └── example/
│       ├── slides.md        # MARP source
│       ├── *.d2             # diagram sources
│       └── .output/         # rendered SVGs + HTML/PDF (gitignored)
└── .gitignore
```

## Tips

- **LLM-assisted diagrams:** Paste your rough description + the relevant icon paths
  from `just icons` into Claude and ask it to write the D2 spec. Tweak from there.
- **Icon path autocomplete:** `just icons <keyword>` outputs paths with the `../aws-icons/`
  prefix ready to paste into `.d2` files.
- **Slide image sizing:** `w:900` in the alt text controls width. Adjust per slide.
  Use `w:700` for diagrams that need more white space around them.
- **Auto diagram build:** `just slides <deck>` renders all diagrams before building
  slides — no need to run them separately.
