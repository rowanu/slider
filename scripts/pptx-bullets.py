#!/usr/bin/env python3
"""
Add click-to-reveal states to a MARP-generated PPTX.

MARP renders PPTX slides as background PNG images, so native animation is
impossible. This script replaces each slide marked '<!-- reveal: on -->'
with N copies showing progressive reveals:

  - Flat bullet slides ('* ' items): reveals one bullet at a time
  - Column layout slides (<div class="columns">): reveals one column at a time

Usage:
  python3 scripts/pptx-bullets.py SLIDES_MD PPTX_IN
      [--output PPTX_OUT] [--theme CSS] [--browser PATH]
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from copy import deepcopy
from pathlib import Path

from lxml import etree

PML = "http://schemas.openxmlformats.org/presentationml/2006/main"
REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
CT  = "http://schemas.openxmlformats.org/package/2006/content-types"

SLIDE_REL_TYPE = f"{REL}/slide"
IMAGE_REL_TYPE = f"{REL}/image"
NOTES_REL_TYPE = f"{REL}/notesSlide"


def qn(ns, local):
    return f"{{{ns}}}{local}"


def detect_layout(slide_content):
    """
    Return (layout, n_steps) for a slide.

    layout 'columns': slide uses <div class="columns">, n_steps = column count
    layout 'bullets': slide has top-level '* ' bullets, n_steps = bullet count
    layout None:      no revealable content
    """
    if '<div class="columns' in slide_content:
        # Count standalone <div> lines — each is a column opening tag
        n = len(re.findall(r'^<div>$', slide_content, re.MULTILINE))
        return ('columns', n) if n >= 2 else (None, 0)

    bullets = re.findall(r'^\* .+', slide_content, re.MULTILINE)
    n = len(bullets)
    return ('bullets', n) if n >= 2 else (None, 0)


def parse_markdown(md_path):
    """Return (front_matter_str, list_of_slide_dicts)."""
    text = Path(md_path).read_text()
    parts = re.split(r"^---\s*$", text, flags=re.MULTILINE)
    # parts[0]: before first ---, parts[1]: YAML front matter, parts[2:]: slides
    front_matter = parts[1].strip() if len(parts) > 2 else ""
    slides = []
    for i, raw in enumerate(parts[2:] if len(parts) > 2 else []):
        content = raw.strip()
        reveal = "<!-- reveal: on -->" in content
        layout, n_steps = detect_layout(content)
        slides.append({
            "index":   i,
            "content": content,
            "reveal":  reveal,
            "layout":  layout,
            "n_steps": n_steps,
        })
    return front_matter, slides


def make_reveal_md(front_matter, slide_content, layout, show_count, total_steps):
    """Build a full markdown string for one reveal state."""
    lines = slide_content.splitlines()

    # Find insertion point: after any leading <!-- ... --> directive lines
    insert_at = 0
    for i, line in enumerate(lines):
        if re.match(r"^\s*<!--.*-->\s*$", line):
            insert_at = i + 1
        elif line.strip():
            break

    if show_count < total_steps:
        hide_from = show_count + 1  # 1-indexed CSS nth-child
        if layout == "columns":
            selector = f".columns > div:nth-child(n+{hide_from})"
        else:
            selector = f"li:nth-child(n+{hide_from})"

        style_block = (
            "<style scoped>\n"
            f"{selector} {{ opacity: 0 !important; }}\n"
            "</style>"
        )
        lines.insert(insert_at, style_block)

    return f"---\n{front_matter}\n---\n\n" + "\n".join(lines)


def render_png(md_text, deck_dir, theme_css, browser_path, output_png):
    """Render a single-slide markdown string to PNG via MARP."""
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".md", dir=str(deck_dir), delete=False, prefix="_reveal_"
    ) as f:
        f.write(md_text)
        tmp_md = f.name
    try:
        cmd = [
            "marp", tmp_md,
            "--image", "png",
            "--allow-local-files",
            "--output", str(output_png),
        ]
        if theme_css:
            cmd += ["--theme", str(theme_css)]
        if browser_path:
            cmd += ["--browser-path", str(browser_path)]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"  MARP stderr: {result.stderr}", file=sys.stderr)
            raise RuntimeError(f"MARP failed with exit code {result.returncode}")
    finally:
        os.unlink(tmp_md)


def inject_reveals(pptx_in, reveal_map, pptx_out):
    """Replace slides in reveal_map with progressive-reveal slide copies.

    reveal_map: {slide_idx (0-based): [png_path, ...]}
      PNG list goes state 1 (least visible) to state N (fully visible).
    """
    with tempfile.TemporaryDirectory() as tmp_str:
        tmp = Path(tmp_str)

        with zipfile.ZipFile(str(pptx_in), "r") as z:
            z.extractall(str(tmp))

        prs_path  = tmp / "ppt" / "presentation.xml"
        prs_rpath = tmp / "ppt" / "_rels" / "presentation.xml.rels"
        ct_path   = tmp / "[Content_Types].xml"

        prs_tree = etree.parse(str(prs_path))
        prs_root = prs_tree.getroot()

        prs_rels_tree = etree.parse(str(prs_rpath))
        prs_rels = prs_rels_tree.getroot()

        ct_tree = etree.parse(str(ct_path))
        ct_root = ct_tree.getroot()

        sldIdLst = prs_root.find(qn(PML, "sldIdLst"))

        rid_to_fname = {
            r.get("Id"): Path(r.get("Target")).name
            for r in prs_rels
            if r.get("Type", "") == SLIDE_REL_TYPE
        }

        ordered = [
            (el.get(qn(REL, "id")), rid_to_fname[el.get(qn(REL, "id"))], el)
            for el in list(sldIdLst)
        ]

        used_ids     = [int(el.get("id")) for el in list(sldIdLst)]
        used_rid_nums = [
            int(m.group(1))
            for r in prs_rels
            for m in [re.search(r"(\d+)$", r.get("Id", ""))]
            if m
        ]
        used_sld_nums = [
            int(m.group(1))
            for _, fname, _ in ordered
            for m in [re.search(r"(\d+)", fname)]
            if m
        ]

        next_id  = max(used_ids,      default=256) + 1
        next_rn  = max(used_rid_nums, default=0)   + 1
        next_sn  = max(used_sld_nums, default=0)   + 1

        new_ordered = []

        for slide_idx, (rid, fname, sld_el) in enumerate(ordered):
            if slide_idx not in reveal_map:
                new_ordered.append((rid, fname, sld_el))
                continue

            pngs       = reveal_map[slide_idx]
            slide_xml  = tmp / "ppt" / "slides" / fname
            slide_rels = tmp / "ppt" / "slides" / "_rels" / f"{fname}.rels"

            orig_rels_root = etree.parse(str(slide_rels)).getroot()
            img_rel = next(
                (r for r in orig_rels_root if r.get("Type", "") == IMAGE_REL_TYPE),
                None,
            )

            for state_i, png_src in enumerate(pngs):
                img_name = f"reveal_s{slide_idx + 1}_r{state_i + 1}.png"
                shutil.copy(str(png_src), str(tmp / "ppt" / "media" / img_name))

                if state_i == 0:
                    if img_rel is not None:
                        img_rel.set("Target", f"../media/{img_name}")
                    etree.ElementTree(orig_rels_root).write(
                        str(slide_rels),
                        xml_declaration=True, encoding="UTF-8", standalone=True,
                    )
                    new_ordered.append((rid, fname, sld_el))
                else:
                    new_fname      = f"slide{next_sn}.xml"
                    new_slide_xml  = tmp / "ppt" / "slides" / new_fname
                    new_slide_rels = tmp / "ppt" / "slides" / "_rels" / f"{new_fname}.rels"

                    shutil.copy(str(slide_xml), str(new_slide_xml))

                    new_rels = deepcopy(orig_rels_root)
                    notes = next(
                        (r for r in new_rels if r.get("Type", "") == NOTES_REL_TYPE), None
                    )
                    if notes is not None:
                        new_rels.remove(notes)
                    new_img = next(
                        (r for r in new_rels if r.get("Type", "") == IMAGE_REL_TYPE), None
                    )
                    if new_img is not None:
                        new_img.set("Target", f"../media/{img_name}")

                    etree.ElementTree(new_rels).write(
                        str(new_slide_rels),
                        xml_declaration=True, encoding="UTF-8", standalone=True,
                    )

                    new_rid = f"rId{next_rn}"
                    etree.SubElement(prs_rels, "Relationship", {
                        "Id":     new_rid,
                        "Type":   SLIDE_REL_TYPE,
                        "Target": f"slides/{new_fname}",
                    })
                    etree.SubElement(ct_root, qn(CT, "Override"), {
                        "PartName":    f"/ppt/slides/{new_fname}",
                        "ContentType": (
                            "application/vnd.openxmlformats-officedocument"
                            ".presentationml.slide+xml"
                        ),
                    })

                    new_sld_el = deepcopy(sld_el)
                    new_sld_el.set("id", str(next_id))
                    new_sld_el.set(qn(REL, "id"), new_rid)
                    new_ordered.append((new_rid, new_fname, new_sld_el))

                    next_sn += 1
                    next_rn += 1
                    next_id += 1

        for el in list(sldIdLst):
            sldIdLst.remove(el)
        for _, _, el in new_ordered:
            sldIdLst.append(el)

        prs_tree.write(
            str(prs_path), xml_declaration=True, encoding="UTF-8", standalone=True
        )
        prs_rels_tree.write(
            str(prs_rpath), xml_declaration=True, encoding="UTF-8", standalone=True
        )
        ct_tree.write(
            str(ct_path), xml_declaration=True, encoding="UTF-8", standalone=True
        )

        with zipfile.ZipFile(str(pptx_out), "w", zipfile.ZIP_DEFLATED) as zout:
            for item in sorted(tmp.rglob("*")):
                if item.is_file():
                    zout.write(str(item), str(item.relative_to(tmp)))

    print(f"Saved: {pptx_out}")


def main():
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("slides_md", type=Path)
    ap.add_argument("pptx_in",   type=Path)
    ap.add_argument("--output",  type=Path)
    ap.add_argument("--theme",   type=Path)
    ap.add_argument("--browser", type=str)
    args = ap.parse_args()

    pptx_out = args.output or args.pptx_in
    deck_dir = args.slides_md.parent

    front_matter, slides = parse_markdown(args.slides_md)

    reveal_slides = [s for s in slides if s["reveal"] and s["n_steps"] >= 2]
    if not reveal_slides:
        print("No slides marked for reveal. Add '<!-- reveal: on -->' to a slide.")
        sys.exit(0)

    reveal_map = {}

    with tempfile.TemporaryDirectory() as png_dir_str:
        png_dir = Path(png_dir_str)

        for slide in reveal_slides:
            idx    = slide["index"]
            layout = slide["layout"]
            n      = slide["n_steps"]
            print(f"Slide {idx + 1} ({layout}): rendering {n} reveal states...")

            pngs = []
            for state in range(1, n + 1):
                md_text = make_reveal_md(
                    front_matter, slide["content"], layout, state, n
                )
                out_png = png_dir / f"slide{idx}_state{state}.png"
                render_png(md_text, deck_dir, args.theme, args.browser, out_png)
                print(f"  state {state}/{n}")
                pngs.append(out_png)

            reveal_map[idx] = pngs

        inject_reveals(args.pptx_in, reveal_map, pptx_out)


if __name__ == "__main__":
    main()
