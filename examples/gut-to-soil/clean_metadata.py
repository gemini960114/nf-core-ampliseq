#!/usr/bin/env python3
"""Clean metadata categories for the optional Gut-to-Soil Tutorial 4."""

from __future__ import annotations

import csv
import sys
from pathlib import Path


METADATA_PATH = Path(__file__).resolve().parent / "data" / "metadata.tsv"
SINGLETON_MAP = {
    "Inside Transfer Bucket": "Other Controls",
    "Inside Composting Bucket": "Other Controls",
    "SunMar Microbe Mix": "Other Controls",
}
COLUMNS_TO_CLEAR = {
    "Observed_Sample_Color",
    "Observed_Sample_Contents",
    "Observed_Sample_Smell",
    "Observed_Sample_Moisture",
    "sample_uuid",
}


def clean_metadata(path: Path) -> int:
    if not path.is_file():
        raise FileNotFoundError(f"找不到 metadata：{path}")

    with path.open("r", encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter="\t"))
    if not rows:
        raise ValueError(f"metadata 是空檔案：{path}")

    header = rows[0]
    if not header or header[0] not in {"sampleID", "sample-id"}:
        raise ValueError("metadata 第一欄必須是 sampleID 或 sample-id")
    if "SampleType" not in header:
        raise ValueError("metadata 缺少必要欄位 SampleType")

    sample_type_index = header.index("SampleType")
    clear_indexes = [
        header.index(column) for column in COLUMNS_TO_CLEAR if column in header
    ]
    cleaned = [header]
    data_rows = 0

    for line_number, row in enumerate(rows[1:], start=2):
        if not row or not any(row):
            continue
        if len(row) != len(header):
            raise ValueError(
                f"metadata 第 {line_number} 行有 {len(row)} 欄，預期 {len(header)} 欄"
            )
        if row[0].startswith("#"):
            cleaned.append(row)
            continue
        if not row[0]:
            raise ValueError(f"metadata 第 {line_number} 行缺少 Sample ID")

        row[sample_type_index] = SINGLETON_MAP.get(
            row[sample_type_index], row[sample_type_index]
        )
        for index in clear_indexes:
            row[index] = ""
        cleaned.append(row)
        data_rows += 1

    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8", newline="") as handle:
        csv.writer(handle, delimiter="\t", lineterminator="\n").writerows(cleaned)
    temporary.replace(path)
    return data_rows


def main() -> int:
    rows = clean_metadata(METADATA_PATH)
    print(f"已清理 {METADATA_PATH}（{rows} 筆資料）。")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (FileNotFoundError, ValueError) as error:
        print(f"錯誤：{error}", file=sys.stderr)
        raise SystemExit(1) from error
