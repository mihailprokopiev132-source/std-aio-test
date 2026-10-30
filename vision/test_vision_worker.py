import tempfile
import unittest
from pathlib import Path

import cv2
import numpy as np

from vision_worker import detect, load_templates, publish


class VisionWorkerTests(unittest.TestCase):
    def test_detect_finds_exact_template_position(self):
        rng = np.random.default_rng(17)
        template = rng.integers(0, 256, size=(18, 22), dtype=np.uint8)
        frame = np.zeros((100, 140, 3), dtype=np.uint8)
        frame[31:49, 47:69] = cv2.cvtColor(template, cv2.COLOR_GRAY2BGR)

        hits = detect(frame, [("known_marker", template)], 0.99)

        self.assertTrue(hits)
        self.assertEqual(hits[0][0], "known_marker")
        self.assertEqual((hits[0][1], hits[0][2]), (47, 31))
        self.assertGreaterEqual(hits[0][5], 0.99)

    def test_load_templates_ignores_invalid_names_and_flat_images(self):
        with tempfile.TemporaryDirectory() as temp:
            folder = Path(temp)
            good = np.random.default_rng(5).integers(0, 255, (12, 14), dtype=np.uint8)
            cv2.imwrite(str(folder / "valid_marker.png"), good)
            cv2.imwrite(str(folder / "flat.png"), np.zeros((12, 14), dtype=np.uint8))
            cv2.imwrite(str(folder / "bad name.png"), good)

            templates = load_templates(folder)

            self.assertEqual([name for name, _ in templates], ["valid_marker"])

    def test_publish_writes_complete_tsv_frame(self):
        with tempfile.TemporaryDirectory() as temp:
            output = Path(temp) / "runtime" / "vision.tsv"
            publish(output, "OK", (100, 200), (640, 360),
                    [("state_match", 20, 30, 40, 50, 0.95)])

            lines = output.read_text(encoding="utf-8").splitlines()
            self.assertEqual(lines[0].split("\t")[0], "FRAME")
            self.assertEqual(lines[1], "STATUS\tOK")
            self.assertEqual(lines[2].split("\t")[:6],
                             ["HIT", "state_match", "20", "30", "40", "50"])


if __name__ == "__main__":
    unittest.main()
