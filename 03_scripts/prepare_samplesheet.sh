#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
template="${project_dir}/01_data/samplesheet.template.tsv"
samplesheet="${project_dir}/01_data/samplesheet.tsv"
fastq_dir="${project_dir}/01_data/fastq"
temporary_file="$(mktemp "${samplesheet}.XXXXXX")"

trap 'rm -f "$temporary_file"' EXIT

awk -v fastq_dir="$fastq_dir" '
BEGIN {
    FS = OFS = "\t"
}
NR == 1 {
    if ($1 != "sample" || $2 != "fastq_1") {
        print "錯誤：samplesheet 第一列必須以 sample 和 fastq_1 開頭" > "/dev/stderr"
        exit 1
    }
    print
    next
}
{
    path_parts = split($2, path, "/")
    $2 = fastq_dir "/" path[path_parts]
    print
}
' "$template" > "$temporary_file"

while IFS=$'\t' read -r sample fastq_1 _; do
    [[ "$sample" == "sample" ]] && continue
    if [[ ! -f "$fastq_1" ]]; then
        echo "錯誤：找不到 $sample 的 FASTQ：$fastq_1" >&2
        exit 1
    fi
done < "$temporary_file"

mv "$temporary_file" "$samplesheet"
trap - EXIT

echo "已更新 samplesheet：$samplesheet"
echo "FASTQ 絕對路徑：$fastq_dir"
