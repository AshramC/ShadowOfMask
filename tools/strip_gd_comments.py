import argparse
import sys
from pathlib import Path


def strip_comments_from_bytes(data: bytes) -> bytes:
    lines = data.splitlines(keepends=True)
    out_chunks = []
    for line in lines:
        newline = b""
        if line.endswith(b"\r\n"):
            newline = b"\r\n"
            content = line[:-2]
        elif line.endswith(b"\n"):
            newline = b"\n"
            content = line[:-1]
        else:
            content = line

        stripped = content.lstrip(b" \t")
        if stripped.startswith(b"#"):
            out_chunks.append(newline)
            continue

        out = bytearray()
        in_single = False
        in_double = False
        escape = False

        for b in content:
            if escape:
                out.append(b)
                escape = False
                continue
            if b == 0x5C:  # backslash
                out.append(b)
                escape = True
                continue
            if not in_double and b == 0x27:  # '
                in_single = not in_single
                out.append(b)
                continue
            if not in_single and b == 0x22:  # "
                in_double = not in_double
                out.append(b)
                continue
            if not in_single and not in_double and b == 0x23:  # '#'
                break
            out.append(b)

        out = out.rstrip(b" \t")
        out_chunks.append(bytes(out) + newline)

    return b"".join(out_chunks)


def main() -> int:
    parser = argparse.ArgumentParser(description="Strip GDScript comments from .gd files.")
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
        data = path.read_bytes()
        stripped = strip_comments_from_bytes(data)
        if stripped != data:
            modified += 1
            if not args.dry_run:
                path.write_bytes(stripped)

    print(f"Processed {modified} file(s) under {target_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
