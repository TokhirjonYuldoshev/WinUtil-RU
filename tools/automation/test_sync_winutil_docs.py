"""Offline safety and idempotency tests for WinUtil-RU documentation synchronization."""
import tempfile
from pathlib import Path
from unittest import TestCase
from unittest.mock import patch

import sync_winutil_docs as docs


REPO = docs.REPO
UPSTREAM = docs.UPSTREAM
COMMIT = "1" * 40
DIGEST = "sha256:" + "2" * 64


def valid_response(path):
    if path == "/repos/" + REPO + "/releases/latest":
        return {
            "tag_name": "26.10.07-RU.1",
            "draft": False,
            "prerelease": False,
            "target_commitish": COMMIT,
            "assets": [
                {"name": "winutil-RU.ps1", "digest": DIGEST, "size": 123},
                {"name": "release.json", "size": 111},
                {"name": "LICENSE", "size": 100},
            ],
        }
    if path == "/repos/" + UPSTREAM + "/releases/latest":
        return {"tag_name": "26.10.07", "draft": False, "prerelease": False}
    if path == "/repos/" + UPSTREAM + "/releases/tags/26.10.07":
        return {"tag_name": "26.10.07", "draft": False, "prerelease": False}
    if path == "/repos/" + REPO + "/commits/26.10.07-RU.1":
        return {"sha": COMMIT}
    raise ValueError("Unexpected GitHub API path: " + path)


class SnapshotTests(TestCase):
    @patch.object(docs, "api", side_effect=valid_response)
    def test_verified_metadata_is_extracted_without_guessing(self, _):
        info = docs.snapshot()
        self.assertEqual(info["tag"], "26.10.07-RU.1")
        self.assertEqual(info["base"], "26.10.07")
        self.assertEqual(info["commit"], COMMIT)
        self.assertEqual(info["digest"], "2" * 64)

    @patch.object(docs, "api")
    def test_bad_ru_tag_stops(self, mock):
        def bad(path):
            data = valid_response(path)
            if path == "/repos/" + REPO + "/releases/latest":
                data["tag_name"] = "../bad"
            return data
        mock.side_effect = bad
        with self.assertRaises(ValueError):
            docs.snapshot()

    @patch.object(docs, "api")
    def test_mismatch_release_commit_stops(self, mock):
        def bad(path):
            data = valid_response(path)
            if path.endswith("/releases/latest") and REPO in path:
                data["target_commitish"] = "3" * 40
            return data
        mock.side_effect = bad
        with self.assertRaises(ValueError):
            docs.snapshot()

    @patch.object(docs, "api")
    def test_missing_digest_stops(self, mock):
        def bad(path):
            data = valid_response(path)
            if path.endswith("/releases/latest") and REPO in path:
                data["assets"][0]["digest"] = ""
            return data
        mock.side_effect = bad
        with self.assertRaises(ValueError):
            docs.snapshot()

    def test_arbitrary_api_path_is_rejected(self):
        with self.assertRaises(ValueError):
            docs.api("/users/someone")


class AllowlistTests(TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        for name in docs.ALLOWED:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                "Historical proof remains.\n"
                "<!-- WINUTIL-RU-DOCSYNC:BEGIN stable=26.09.29-RU.1 upstream=26.09.29 -->\n"
                "OLD STATUS\n"
                "<!-- WINUTIL-RU-DOCSYNC:END -->\n"
                "More historical evidence.\n", encoding="utf-8"
            )
        (self.root / "protected-backend.ps1").write_text("SAFE", encoding="utf-8")
        self.info = {"tag": "26.10.07-RU.1", "base": "26.10.07",
                     "official": "26.10.07", "commit": COMMIT,
                     "digest": "2" * 64}

    def tearDown(self):
        self.temp.cleanup()

    def test_only_allowlisted_sections_change(self):
        changed = docs.update(self.root, self.info)
        self.assertEqual(set(changed), set(docs.ALLOWED))
        self.assertEqual(docs.update(self.root, self.info), [])
        for name in docs.ALLOWED:
            content = (self.root / name).read_text(encoding="utf-8")
            self.assertIn("Historical proof remains.", content)
            self.assertIn("More historical evidence.", content)
            self.assertIn("sha256", content.lower())
        self.assertEqual(
            (self.root / "protected-backend.ps1").read_text(), "SAFE"
        )

    def test_check_mode_never_writes(self):
        path = self.root / "README.md"
        content = path.read_bytes()
        self.assertEqual(set(docs.update(self.root, self.info, check=True)),
                         set(docs.ALLOWED))
        self.assertEqual(path.read_bytes(), content)

    def test_missing_marker_blocks_everything(self):
        (self.root / "README.en.md").write_text("No markers")
        with self.assertRaises(ValueError):
            docs.update(self.root, self.info)
