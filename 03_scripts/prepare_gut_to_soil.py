#!/usr/bin/env python3
import os
import glob
import zipfile

# 1. Process metadata.raw.tsv -> 01_data/metadata.tsv
raw_meta_path = "01_data/metadata.raw.tsv"
out_meta_path = "01_data/metadata.tsv"

with open(raw_meta_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

if lines:
    header = lines[0].strip().split("\t")
    new_header = []
    for col in header:
        if col.lower() in ["sample-id", "sample_id", "sampleid"]:
            new_header.append("sampleID")
        else:
            new_header.append(col.replace("-", "_").replace(" ", "_"))
    lines[0] = "\t".join(new_header) + "\n"

    # Prefix S_ to all sample IDs in data rows (lines 2+ unless line 1 is #q2:types)
    for i in range(1, len(lines)):
        if lines[i].startswith("#"):
            continue
        parts = lines[i].split("\t")
        if parts:
            # Prefix sample ID with S_ if it doesn't already start with a letter
            sid = parts[0]
            if sid and not sid[0].isalpha():
                parts[0] = f"S_{sid}"
            else:
                parts[0] = f"S_{sid}" if sid else sid
            lines[i] = "\t".join(parts)

with open(out_meta_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print(f"Processed metadata with S_ prefix saved to {out_meta_path}")

# 2. Generate samplesheet.template.tsv with S_ prefix for sample IDs
files = glob.glob("01_data/fastq/*.fastq.gz")
r1_dict = {}
r2_dict = {}

for f in files:
    filename = os.path.basename(f)
    sample_id = filename.split("_")[0]
    # Prefix sample ID with S_
    prefix_sid = f"S_{sample_id}" if not sample_id.startswith("S_") else sample_id
    if "_R1_" in filename:
        r1_dict[prefix_sid] = f
    elif "_R2_" in filename:
        r2_dict[prefix_sid] = f

matched = set(r1_dict.keys()).intersection(set(r2_dict.keys()))

lines = ["sample\tfastq_1\tfastq_2\n"]
for sid in sorted(matched):
    r1_rel = os.path.join("fastq", os.path.basename(r1_dict[sid]))
    r2_rel = os.path.join("fastq", os.path.basename(r2_dict[sid]))
    lines.append(f"{sid}\t{r1_rel}\t{r2_rel}\n")

with open("01_data/samplesheet.template.tsv", "w") as f:
    f.writelines(lines)

print(f"Generated samplesheet.template.tsv with {len(matched)} paired-end samples with S_ prefix.")
