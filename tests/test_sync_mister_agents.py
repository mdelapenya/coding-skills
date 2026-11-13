"""Exercise generation behavior in an isolated fixture, without modifying the repo."""

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/sync-mister-agents.py"
SPEC = importlib.util.spec_from_file_location("sync_mister_agents", SCRIPT)
SYNC = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(SYNC)


class SyncMisterAgentsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / SYNC.SOURCE
        self.source.parent.mkdir(parents=True)
        self.source.write_text("## Preambles\n\n" + "\n\n".join(
            f"**{role}** (fixture):\n\n```\nCanonical {role}.\n```"
            for role in SYNC.ROLES
        ) + "\n\n## Full template\n", encoding="utf-8")
        (self.root / SYNC.AGENTS).mkdir(parents=True)
        self.headers = {}
        for role, filename in SYNC.ROLES.items():
            if filename is None:
                continue
            # Header content belongs to the runtime, never to the generator.
            header = (f'---\nname: {role.lower()}\nmodel: haiku\n'
                      'tools: Read, Bash\ncustom: "keep: this"\n---\n').encode()
            self.headers[filename] = header
            (self.root / SYNC.AGENTS / filename).write_bytes(header + b"\nStale body.\n")

    def run_sync(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), "--root", str(self.root), *args],
                              capture_output=True, text=True, check=False)

    def snapshot(self):
        return {p.name: (p.read_bytes(), p.stat().st_mtime_ns)
                for p in (self.root / SYNC.AGENTS).iterdir()}

    def test_regeneration_preserves_frontmatter_and_is_idempotent(self):
        result = self.run_sync()
        self.assertEqual(result.returncode, 0, result.stderr)
        for role, filename in SYNC.ROLES.items():
            if filename:
                self.assertEqual((self.root / SYNC.AGENTS / filename).read_bytes(),
                                 self.headers[filename] + f"\nCanonical {role}.\n".encode())
        first = self.snapshot()
        self.assertEqual(self.run_sync().returncode, 0)
        self.assertEqual(self.snapshot(), first, "no-op regeneration must not rewrite files")
        self.assertEqual(self.run_sync("--check").returncode, 0)

    def test_check_reports_drift_without_writing(self):
        before = self.snapshot()
        result = self.run_sync("--check")
        self.assertEqual(result.returncode, 1)
        for filename in self.headers:
            self.assertIn(f"drift: {(SYNC.AGENTS / filename).as_posix()}", result.stderr)
        self.assertEqual(self.snapshot(), before)

    def test_canonical_change_requires_regeneration(self):
        self.assertEqual(self.run_sync().returncode, 0)
        self.source.write_text(self.source.read_text().replace("Canonical Engineer.", "New policy."))
        result = self.run_sync("--check")
        self.assertEqual(result.returncode, 1)
        self.assertIn("engineer.md", result.stderr)
        self.assertNotIn("mechanic.md", result.stderr)
        self.assertEqual(self.run_sync().returncode, 0)
        self.assertIn(b"New policy.", (self.root / SYNC.AGENTS / "engineer.md").read_bytes())
        self.assertEqual(self.run_sync("--check").returncode, 0)

    def test_missing_role_fails_before_any_write(self):
        self.source.write_text(self.source.read_text().replace(
            "**Inspector** (fixture):\n\n```\nCanonical Inspector.\n```", ""))
        before = self.snapshot()
        result = self.run_sync()
        self.assertEqual(result.returncode, 1)
        self.assertIn("missing canonical roles: Inspector", result.stderr)
        self.assertEqual(self.snapshot(), before)

    def test_missing_explorer_is_invalid_even_without_a_shipped_agent(self):
        self.source.write_text(self.source.read_text().replace(
            "**Explorer** (fixture):\n\n```\nCanonical Explorer.\n```", ""))
        self.assertEqual(self.run_sync("--check").returncode, 1)

    def test_duplicate_role_is_rejected(self):
        self.source.write_text(self.source.read_text().replace("## Full template", (
            "**Engineer** (duplicate):\n\n```\nDifferent policy.\n```\n\n## Full template")))
        result = self.run_sync()
        self.assertEqual(result.returncode, 1)
        self.assertIn("duplicate canonical role", result.stderr)

    def test_missing_agent_and_bad_frontmatter_fail_before_writing(self):
        inspector = self.root / SYNC.AGENTS / "inspector.md"
        inspector.unlink()
        before = self.snapshot()
        self.assertEqual(self.run_sync().returncode, 1)
        self.assertEqual(self.snapshot(), before)
        inspector.write_text("No header\n")
        before = self.snapshot()
        result = self.run_sync()
        self.assertEqual(result.returncode, 1)
        self.assertIn("missing YAML frontmatter", result.stderr)
        self.assertEqual(self.snapshot(), before)

    def test_crlf_frontmatter_is_preserved_byte_for_byte(self):
        path = self.root / SYNC.AGENTS / "engineer.md"
        header = self.headers[path.name].replace(b"\n", b"\r\n")
        path.write_bytes(header + b"\r\nold\r\n")
        self.assertEqual(self.run_sync().returncode, 0)
        self.assertEqual(path.read_bytes(), header + b"\nCanonical Engineer.\n")
        self.assertEqual(self.run_sync("--check").returncode, 0)

    def test_malformed_fence_and_unknown_role_are_rejected(self):
        original = self.source.read_text()
        self.source.write_text(original.replace("Canonical Mechanic.\n```", "Canonical Mechanic."))
        self.assertEqual(self.run_sync().returncode, 1)
        self.source.write_text(original.replace("**Mechanic**", "**Unconfigured worker**"))
        result = self.run_sync()
        self.assertEqual(result.returncode, 1)
        self.assertIn("unknown canonical role", result.stderr)

    def test_header_without_final_newline_regenerates_idempotently(self):
        path = self.root / SYNC.AGENTS / "engineer.md"
        header = self.headers[path.name].rstrip(b"\n")
        path.write_bytes(header)
        self.assertEqual(self.run_sync().returncode, 0)
        self.assertEqual(path.read_bytes(), header + b"\n\nCanonical Engineer.\n")
        self.assertEqual(self.run_sync("--check").returncode, 0)


if __name__ == "__main__":
    unittest.main()
