#!/usr/bin/env python3
import os

meta_path = "01_data/metadata.tsv"

with open(meta_path, "r", encoding="utf-8") as f:
    lines = [line.rstrip("\r\n").split("\t") for line in f]

header = lines[0]
sample_type_idx = header.index("SampleType")

# Singleton map for SampleType
singleton_map = {
    "Inside Transfer Bucket": "Other Controls",
    "Inside Composting Bucket": "Other Controls",
    "SunMar Microbe Mix": "Other Controls"
}

# Update rows
new_lines = []
new_lines.append("\t".join(header))

for row in lines[1:]:
    if not row or not row[0]:
        continue
    if row[0].startswith("#"):
        new_lines.append("\t".join(row))
        continue

    # Update SampleType if singleton
    if len(row) > sample_type_idx:
        stype = row[sample_type_idx]
        if stype in singleton_map:
            row[sample_type_idx] = singleton_map[stype]

    # Clean unique/singleton-heavy columns that cause QIIME2 beta-group-significance errors:
    # Set Observed_Sample_Color, Observed_Sample_Contents, Observed_Sample_Smell, sample_uuid to empty/NA if present
    for col_name in ["Observed_Sample_Color", "Observed_Sample_Contents", "Observed_Sample_Smell", "Observed_Sample_Moisture", "sample_uuid"]:
        if col_name in header:
            cidx = header.index(col_name)
            if len(row) > cidx:
                row[cidx] = ""

    new_lines.append("\t".join(row))

with open(meta_path, "w", encoding="utf-8") as f:
    f.write("\n".join(new_lines) + "\n")

print("Successfully cleaned metadata.tsv: singletons in SampleType merged to 'Other Controls' and unique metadata columns cleaned.")
