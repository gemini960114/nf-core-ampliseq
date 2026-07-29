from __future__ import annotations

import csv
import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_module(name: str, relative_path: str):
    path = ROOT / relative_path
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Cannot import {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


prepare = load_module("prepare_gut_to_soil", "03_scripts/prepare_gut_to_soil.py")
clean = load_module("clean_metadata", "03_scripts/clean_metadata.py")


class MetadataTests(unittest.TestCase):
    def test_normalize_metadata_is_idempotent_for_s_prefix(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            source = directory / "metadata.raw.tsv"
            destination = directory / "metadata.tsv"
            source.write_text(
                "sample-id\tbody-site\n"
                "#q2:types\tcategorical\n"
                "123\tsoil\n"
                "S_existing\tgut\n",
                encoding="utf-8",
            )

            count = prepare.normalize_metadata(source, destination)

            self.assertEqual(count, 2)
            self.assertEqual(
                destination.read_text(encoding="utf-8").splitlines(),
                [
                    "sampleID\tbody_site",
                    "#q2:types\tcategorical",
                    "S_123\tsoil",
                    "S_existing\tgut",
                ],
            )

    def test_collect_fastq_pairs_supports_underscores(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            for name in (
                "sample_with_underscore_1_L001_R1_001.fastq.gz",
                "sample_with_underscore_2_L001_R2_001.fastq.gz",
            ):
                (directory / name).touch()

            pairs = prepare.collect_fastq_pairs(directory)

            self.assertEqual(list(pairs), ["S_sample_with_underscore"])

    def test_collect_fastq_pairs_rejects_incomplete_pair(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "sample_1_L001_R1_001.fastq.gz").touch()

            with self.assertRaisesRegex(ValueError, "不完整"):
                prepare.collect_fastq_pairs(directory)

    def test_clean_metadata_preserves_qiime_directive(self):
        with tempfile.TemporaryDirectory() as temporary:
            metadata = Path(temporary) / "metadata.tsv"
            metadata.write_text(
                "sampleID\tSampleType\tsample_uuid\n"
                "#q2:types\tcategorical\tcategorical\n"
                "S_1\tInside Transfer Bucket\tunique\n",
                encoding="utf-8",
            )

            rows = clean.clean_metadata(metadata)

            self.assertEqual(rows, 1)
            self.assertEqual(
                metadata.read_text(encoding="utf-8").splitlines(),
                [
                    "sampleID\tSampleType\tsample_uuid",
                    "#q2:types\tcategorical\tcategorical",
                    "S_1\tOther Controls\t",
                ],
            )


class ProjectContractTests(unittest.TestCase):
    def test_bash_scripts_parse(self):
        scripts = (
            "02_config/setup_environment.sh",
            ".agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh",
            "03_scripts/prepare_assets.sh",
            "03_scripts/prepare_samplesheet.sh",
            "03_scripts/submit_ampliseq.slurm",
        )
        for script in scripts:
            with self.subTest(script=script):
                subprocess.run(
                    ["bash", "-n", str(ROOT / script)],
                    check=True,
                    capture_output=True,
                    text=True,
                )

    def test_slurm_script_fails_fast_and_has_no_account(self):
        script = (ROOT / "03_scripts/submit_ampliseq.slurm").read_text(
            encoding="utf-8"
        )
        self.assertIn("set -euo pipefail", script)
        self.assertIn("#SBATCH --time=", script)
        self.assertNotIn("#SBATCH --account=", script)
        self.assertNotIn("--metadata_category_pairwise", script)

    def test_removed_pipeline_parameter_is_not_documented(self):
        paths = (
            "README.md",
            "Gut-to-Soil-16S.md",
            "03_scripts/Gut-to-Soil-16S.md",
            "tutorial_2_16S_manual_guide.md",
            "tutorial_3_16S_ai_prompt_guide.md",
        )
        for relative_path in paths:
            content = (ROOT / relative_path).read_text(encoding="utf-8")
            with self.subTest(path=relative_path):
                self.assertNotIn("--metadata_category_pairwise", content)

    def test_nano4_skill_and_project_rules_are_connected(self):
        skill = (
            ROOT / ".agents/skills/nano4-slurm-operations/SKILL.md"
        ).read_text(encoding="utf-8")
        project_rules = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
        preflight = (
            ROOT
            / ".agents/skills/nano4-slurm-operations/scripts/slurm-preflight.sh"
        ).read_text(encoding="utf-8")

        self.assertIn("name: nano4-slurm-operations", skill)
        self.assertIn("MST109178", skill)
        self.assertIn("nano4-slurm-operations", project_rules)
        self.assertIn("slurm_ampliseq_guide", project_rules)
        self.assertNotIn("\nsbatch ", preflight)
        self.assertNotIn("\nscancel ", preflight)

    def test_nextflow_configs_isolate_task_temp(self):
        for relative_path in (
            "nextflow.config",
            "02_config/nextflow_singularity.config",
        ):
            config = (ROOT / relative_path).read_text(encoding="utf-8")
            with self.subTest(config=relative_path):
                self.assertIn("executor = 'local'", config)
                self.assertIn("runOptions  = '-B /tmp:/tmp'", config)
                self.assertIn('export TMPDIR="$PWD/.nxf-tmp"', config)

    def test_samplesheet_and_metadata_ids_match(self):
        with (ROOT / "01_data/samplesheet.template.tsv").open(
            encoding="utf-8", newline=""
        ) as handle:
            samplesheet_rows = list(csv.DictReader(handle, delimiter="\t"))
        with (ROOT / "01_data/metadata.tsv").open(
            encoding="utf-8", newline=""
        ) as handle:
            metadata_rows = list(csv.DictReader(handle, delimiter="\t"))

        sample_ids = [row["sample"] for row in samplesheet_rows]
        metadata_ids = {
            row["sampleID"]
            for row in metadata_rows
            if row["sampleID"] and not row["sampleID"].startswith("#")
        }

        self.assertEqual(len(sample_ids), 104)
        self.assertEqual(len(sample_ids), len(set(sample_ids)))
        self.assertTrue(all(sample.startswith("S_") for sample in sample_ids))
        self.assertTrue(set(sample_ids).issubset(metadata_ids))


if __name__ == "__main__":
    unittest.main()
