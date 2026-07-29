from __future__ import annotations

import csv
import importlib.util
import re
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


gut_prepare = load_module(
    "gut_prepare", "examples/gut-to-soil/prepare_gut_to_soil.py"
)
gut_clean = load_module(
    "gut_clean", "examples/gut-to-soil/clean_metadata.py"
)


class OptionalGutToSoilTests(unittest.TestCase):
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

            count = gut_prepare.normalize_metadata(source, destination)

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

    def test_collect_fastq_pairs_rejects_incomplete_pair(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "sample_1_L001_R1_001.fastq.gz").touch()

            with self.assertRaisesRegex(ValueError, "不完整"):
                gut_prepare.collect_fastq_pairs(directory)

    def test_clean_metadata_preserves_qiime_directive(self):
        with tempfile.TemporaryDirectory() as temporary:
            metadata = Path(temporary) / "metadata.tsv"
            metadata.write_text(
                "sampleID\tSampleType\tsample_uuid\n"
                "#q2:types\tcategorical\tcategorical\n"
                "S_1\tInside Transfer Bucket\tunique\n",
                encoding="utf-8",
            )

            rows = gut_clean.clean_metadata(metadata)

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
            "examples/gut-to-soil/download_data.sh",
            "examples/gut-to-soil/submit_ampliseq.slurm",
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
        self.assertIn("--single_end", script)
        self.assertIn('--qiime_adonis_formula "body_site"', script)
        self.assertNotIn("--trunclenr", script)

    def test_optional_gut_to_soil_is_isolated(self):
        script = (
            ROOT / "examples/gut-to-soil/submit_ampliseq.slurm"
        ).read_text(encoding="utf-8")
        downloader = (
            ROOT / "examples/gut-to-soil/download_data.sh"
        ).read_text(encoding="utf-8")
        tutorial = (ROOT / "tutorial_4_gut_to_soil_optional.md").read_text(
            encoding="utf-8"
        )

        self.assertNotIn("#SBATCH --account=", script)
        self.assertIn("--trunclenr 250", script)
        self.assertIn('--qiime_adonis_formula "SampleType"', script)
        self.assertIn("examples/gut-to-soil/data", script)
        self.assertIn('results/gut-to-soil', script)
        self.assertIn('work/gut-to-soil', script)
        self.assertIn("examples/gut-to-soil/data", tutorial)
        self.assertIn("examples/gut-to-soil", tutorial)
        self.assertNotIn('rm -f 01_data/fastq', downloader)
        self.assertIn("metadata_sha256=", downloader)
        self.assertIn("demux_sha256=", downloader)

        with (
            ROOT / "examples/gut-to-soil/data/samplesheet.template.tsv"
        ).open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle, delimiter="\t"))
        with (
            ROOT / "examples/gut-to-soil/data/metadata.tsv"
        ).open(encoding="utf-8", newline="") as handle:
            metadata_rows = list(csv.DictReader(handle, delimiter="\t"))
        self.assertEqual(list(rows[0]), ["sample", "fastq_1", "fastq_2"])
        self.assertEqual(len(rows), 104)
        metadata_ids = {
            row["sampleID"]
            for row in metadata_rows
            if row["sampleID"] and not row["sampleID"].startswith("#")
        }
        self.assertTrue({row["sample"] for row in rows}.issubset(metadata_ids))

    def test_samplesheet_generator_accepts_isolated_paired_data(self):
        with tempfile.TemporaryDirectory() as temporary:
            data_dir = Path(temporary)
            fastq_dir = data_dir / "fastq"
            fastq_dir.mkdir()
            for name in ("sample_R1.fastq.gz", "sample_R2.fastq.gz"):
                (fastq_dir / name).touch()
            (data_dir / "samplesheet.template.tsv").write_text(
                "sample\tfastq_1\tfastq_2\n"
                "sample\tfastq/sample_R1.fastq.gz\t"
                "fastq/sample_R2.fastq.gz\n",
                encoding="utf-8",
            )

            subprocess.run(
                [
                    "bash",
                    str(ROOT / "03_scripts/prepare_samplesheet.sh"),
                    "--data-dir",
                    str(data_dir),
                ],
                check=True,
                capture_output=True,
                text=True,
            )

            generated = (data_dir / "samplesheet.tsv").read_text(
                encoding="utf-8"
            )
            self.assertIn(str(fastq_dir / "sample_R1.fastq.gz"), generated)
            self.assertIn(str(fastq_dir / "sample_R2.fastq.gz"), generated)

    def test_removed_pipeline_parameter_is_not_documented(self):
        paths = (
            "README.md",
            "tutorial_2_16S_manual_guide.md",
            "tutorial_3_16S_ai_prompt_guide.md",
        )
        for relative_path in paths:
            content = (ROOT / relative_path).read_text(encoding="utf-8")
            with self.subTest(path=relative_path):
                self.assertNotIn("--metadata_category_pairwise", content)

    def test_teaching_docs_distinguish_datasets_and_generated_results(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        syllabus = (ROOT / "course_syllabus.md").read_text(encoding="utf-8")
        tutorial_4 = (
            ROOT / "tutorial_4_gut_to_soil_optional.md"
        ).read_text(encoding="utf-8")

        self.assertIn("Moving Pictures（預設）", readme)
        self.assertIn("Gut-to-Soil（Tutorial 4，選修）", readme)
        self.assertIn("34 | 34 | Single-end", readme)
        self.assertIn("104 | 208 | Paired-end", readme)
        self.assertIn("MST109178", readme)
        self.assertIn("參考執行結果", readme)
        self.assertIn("不包含在剛 clone 的 repository", readme)
        self.assertNotRegex(readme, r"\]\(results/")

        self.assertIn("評量方式與作業", syllabus)
        self.assertIn("選修 paired-end 延伸練習", syllabus)
        self.assertNotIn("ASVs (772 特徵)", syllabus)
        self.assertRegex(
            tutorial_4,
            re.compile(
                r"## 1\..*## 2\..*## 3\..*## 4\.",
                flags=re.DOTALL,
            ),
        )

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
        self.assertIn("slurm-ampliseq-guide", project_rules)
        self.assertNotIn("\nsbatch ", preflight)
        self.assertNotIn("\nscancel ", preflight)

        ampliseq_skill = (
            ROOT / ".agents/skills/slurm-ampliseq-guide/SKILL.md"
        ).read_text(encoding="utf-8")
        self.assertIn("name: slurm-ampliseq-guide", ampliseq_skill)
        self.assertIn("34-sample Moving Pictures", ampliseq_skill)

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

        self.assertEqual(list(samplesheet_rows[0]), ["sample", "fastq_1"])
        self.assertEqual(len(sample_ids), 34)
        self.assertEqual(len(sample_ids), len(set(sample_ids)))
        self.assertTrue(set(sample_ids).issubset(metadata_ids))
        self.assertTrue(
            all(
                (ROOT / "01_data" / row["fastq_1"]).is_file()
                for row in samplesheet_rows
            )
        )


if __name__ == "__main__":
    unittest.main()
