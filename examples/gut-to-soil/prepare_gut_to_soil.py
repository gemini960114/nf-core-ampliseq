#!/usr/bin/env python3
"""Prepare the isolated Gut-to-Soil Tutorial 4 dataset."""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path


DATA_DIR = Path(__file__).resolve().parent / "data"
RAW_METADATA = DATA_DIR / "metadata.raw.tsv"
OUTPUT_METADATA = DATA_DIR / "metadata.tsv"
FASTQ_DIR = DATA_DIR / "fastq"
SAMPLESHEET_TEMPLATE = DATA_DIR / "samplesheet.template.tsv"
FASTQ_PATTERN = re.compile(
    r"^(?P<sample>.+)_\d+_L\d{3}_R(?P<read>[12])_\d{3}\.fastq\.gz$"
)


def prefixed_sample_id(sample_id: str) -> str:
    sample_id = sample_id.strip()
    if not sample_id:
        raise ValueError("metadata 中出現空白 Sample ID")
    return sample_id if sample_id.startswith("S_") else f"S_{sample_id}"


def normalize_metadata(source: Path, destination: Path) -> int:
    if not source.is_file():
        raise FileNotFoundError(
            f"找不到原始 metadata：{source}\n"
            "請先將 sample-metadata.tsv 下載為 01_data/metadata.raw.tsv。"
        )

    with source.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter="\t"))

    if not rows:
        raise ValueError(f"原始 metadata 是空檔案：{source}")

    header = [
        "sampleID"
        if column.lower() in {"sample-id", "sample_id", "sampleid", "id"}
        else column.replace("-", "_").replace(" ", "_")
        for column in rows[0]
    ]
    if header[0] != "sampleID":
        raise ValueError(
            f"metadata 第一欄無法辨識為 Sample ID：{rows[0][0]!r}"
        )

    normalized = [header]
    seen: set[str] = set()
    for line_number, row in enumerate(rows[1:], start=2):
        if not row or not any(row):
            continue
        if row[0].startswith("#"):
            normalized.append(row)
            continue
        if len(row) != len(header):
            raise ValueError(
                f"metadata 第 {line_number} 行有 {len(row)} 欄，預期 {len(header)} 欄"
            )
        row[0] = prefixed_sample_id(row[0])
        if row[0] in seen:
            raise ValueError(f"metadata 出現重複 Sample ID：{row[0]}")
        seen.add(row[0])
        normalized.append(row)

    temporary = destination.with_suffix(destination.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as handle:
        csv.writer(handle, delimiter="\t", lineterminator="\n").writerows(normalized)
    temporary.replace(destination)
    return len(seen)


def collect_fastq_pairs(fastq_dir: Path) -> dict[str, tuple[Path, Path]]:
    reads: dict[str, dict[str, Path]] = {}
    ignored: list[str] = []

    for path in sorted(fastq_dir.glob("*.fastq.gz")):
        match = FASTQ_PATTERN.match(path.name)
        if not match:
            ignored.append(path.name)
            continue
        sample_id = prefixed_sample_id(match.group("sample"))
        read = match.group("read")
        if read in reads.setdefault(sample_id, {}):
            raise ValueError(
                f"{sample_id} 有多個 R{read} FASTQ；目前 samplesheet 不支援多 lane："
                f"{reads[sample_id][read].name}, {path.name}"
            )
        reads[sample_id][read] = path

    if ignored:
        print(
            f"警告：忽略 {len(ignored)} 個不符合 Illumina R1/R2 命名格式的 FASTQ。",
            file=sys.stderr,
        )

    incomplete = {
        sample: sorted({"1", "2"} - set(sample_reads))
        for sample, sample_reads in reads.items()
        if set(sample_reads) != {"1", "2"}
    }
    if incomplete:
        details = ", ".join(
            f"{sample} 缺 R{'/R'.join(missing)}"
            for sample, missing in sorted(incomplete.items())
        )
        raise ValueError(f"發現不完整的 paired-end FASTQ：{details}")

    pairs = {
        sample: (sample_reads["1"], sample_reads["2"])
        for sample, sample_reads in reads.items()
    }
    if not pairs:
        raise ValueError(f"在 {fastq_dir} 找不到任何完整 R1/R2 FASTQ 配對")
    return pairs


def write_samplesheet_template(
    pairs: dict[str, tuple[Path, Path]], destination: Path
) -> None:
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(["sample", "fastq_1", "fastq_2"])
        for sample_id, (read_1, read_2) in sorted(pairs.items()):
            writer.writerow(
                [
                    sample_id,
                    f"fastq/{read_1.name}",
                    f"fastq/{read_2.name}",
                ]
            )
    temporary.replace(destination)


def main() -> int:
    metadata_count = normalize_metadata(RAW_METADATA, OUTPUT_METADATA)
    pairs = collect_fastq_pairs(FASTQ_DIR)
    write_samplesheet_template(pairs, SAMPLESHEET_TEMPLATE)
    print(
        f"已產生 {OUTPUT_METADATA}（{metadata_count} 筆 metadata）與 "
        f"{SAMPLESHEET_TEMPLATE}（{len(pairs)} 對 paired-end samples）。"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, ValueError) as error:
        print(f"錯誤：{error}", file=sys.stderr)
        raise SystemExit(1) from error
