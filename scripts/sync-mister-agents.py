#!/usr/bin/env python3
"""Regenerate worker bodies from the canonical fenced role preambles.

Agent frontmatter is runtime configuration and is preserved byte for byte.
No Git commands, dependencies, or Codex TOML copies are involved.
"""

import argparse
import re
import sys
from pathlib import Path


ROLES = {
    "Engineer": "engineer.md",
    "Mechanic": "mechanic.md",
    "Explorer": None,  # Claude uses its built-in Explore agent.
    "Reviewer": "reviewer.md",
    "Inspector": "inspector.md",
    "Git operator": "git-operator.md",
}
SOURCE = Path("skills/the-mister/references/plan-and-orders.md")


def preambles(source):
    """Fail on missing, duplicate, or malformed canonical blocks."""
    try:
        section = source.split("## Preambles\n", 1)[1].split("\n## Full template", 1)[0]
    except IndexError as exc:
        raise ValueError("missing Preambles section") from exc
    result = {}
    headings = list(re.finditer(r"^\*\*([^*]+)\*\*[^\n]*\n", section, re.MULTILINE))
    for index, heading in enumerate(headings):
        role = heading.group(1)
        if role not in ROLES:
            raise ValueError(f"unknown canonical role: {role}")
        if role in result:
            raise ValueError(f"duplicate canonical role: {role}")
        end = headings[index + 1].start() if index + 1 < len(headings) else len(section)
        block = section[heading.end():end]
        match = re.fullmatch(r"\s*```\n(.+?)\n```\s*", block, re.DOTALL)
        if not match or not match.group(1).strip():
            raise ValueError(f"missing or malformed preamble: {role}")
        result[role] = match.group(1) + "\n"
    missing = ROLES.keys() - result.keys()
    if missing:
        raise ValueError("missing canonical roles: " + ", ".join(sorted(missing)))
    return result


def generated_agents(root):
    """Validate every input before producing any file changes."""
    roles = preambles((root / SOURCE).read_text(encoding="utf-8"))
    result = []
    for role, filename in ROLES.items():
        if filename is None:
            continue
        path = root / "agents" / filename
        current = path.read_bytes()
        header = re.match(rb"\A---\r?\n.*?\r?\n---(?:\r?\n|\Z)", current, re.DOTALL)
        if header is None:
            raise ValueError(f"missing YAML frontmatter: {path}")
        # Preserve all bytes in the header, including delimiter line endings.
        separator = b"\n" if header.group().endswith(b"\n") else b"\n\n"
        expected = header.group() + separator + roles[role].encode("utf-8")
        result.append((path, current, expected))
    return result


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="report drift without writing")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1],
                        help="repository root (default: script's parent repository)")
    args = parser.parse_args(argv)
    try:
        candidates = generated_agents(args.root)
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    changed = [(path, expected) for path, current, expected in candidates if current != expected]
    if args.check:
        for path, _ in changed:
            print(f"drift: {path.relative_to(args.root)}", file=sys.stderr)
        if changed:
            print("Run python3 scripts/sync-mister-agents.py to regenerate worker bodies.",
                  file=sys.stderr)
            return 1
        print("Mister worker bodies match canonical preambles.")
        return 0
    for path, expected in changed:
        path.write_bytes(expected)
        print(f"updated: {path.relative_to(args.root)}")
    if not changed:
        print("Mister worker bodies already match canonical preambles.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
