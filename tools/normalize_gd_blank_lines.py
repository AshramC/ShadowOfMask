import argparse
from pathlib import Path


def normalize_blank_lines(text: str) -> str:
    lines = text.splitlines()
    out = []
    prev_blank = False
    for line in lines:
        is_blank = len(line.strip()) == 0
        if is_blank:
            if prev_blank:
                continue
            out.append("")
            prev_blank = True
        else:
            out.append(line.rstrip())
            prev_blank = False

    # strip leading/trailing blank lines
    while out and out[0] == "":
        out.pop(0)
    while out and out[-1] == "":
        out.pop()

    return "\n".join(out) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Normalize blank lines in GDScript files.")
    parser.add_argument("--root", default=None, help="Repository root (default: script parent)")
    parser.add_argument("--dry-run", action="store_true", help="Do not write changes")
    args = parser.parse_args()

    script_root = Path(__file__).resolve().parent
    root = Path(args.root).resolve() if args.root else script_root.parent
    target_dir = root / "godot_ui" / "scripts"
    if not target_dir.exists():
        print(f"Target directory not found: {target_dir}")
        return 1

    modified = 0
    for path in target_dir.rglob("*.gd"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        normalized = normalize_blank_lines(text)
        if normalized != text:
            modified += 1
            if not args.dry_run:
                path.write_text(normalized, encoding="utf-8", newline="\n")

    print(f"Normalized {modified} file(s) under {target_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
