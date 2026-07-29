#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

usage() {
    echo "用法：$0 [--data-dir <DATA_DIRECTORY>]" >&2
}

data_dir="${project_dir}/01_data"
if (( $# > 0 )); then
    if (( $# != 2 )) || [[ "$1" != "--data-dir" ]]; then
        usage
        exit 2
    fi
    if [[ ! -d "$2" ]]; then
        echo "錯誤：資料目錄不存在：$2" >&2
        exit 1
    fi
    data_dir="$(cd "$2" && pwd -P)"
fi

template="${data_dir}/samplesheet.template.tsv"
samplesheet="${data_dir}/samplesheet.tsv"
fastq_dir="${data_dir}/fastq"

if [[ ! -f "$template" ]]; then
    echo "錯誤：找不到 samplesheet 範本：$template" >&2
    exit 1
fi
if [[ ! -d "$fastq_dir" ]]; then
    echo "錯誤：找不到 FASTQ 目錄：$fastq_dir" >&2
    exit 1
fi

temporary_file="$(mktemp "${samplesheet}.XXXXXX")"

trap 'rm -f "$temporary_file"' EXIT

awk -v fastq_dir="$fastq_dir" '
BEGIN {
    FS = OFS = "\t"
}
NR == 1 {
    if ($1 != "sample" || $2 != "fastq_1" ||
        (NF != 2 && !(NF == 3 && $3 == "fastq_2"))) {
        print "錯誤：samplesheet 必須是 sample、fastq_1，或加上 fastq_2" > "/dev/stderr"
        exit 1
    }
    print
    next
}
{
    path_parts1 = split($2, path1, "/")
    $2 = fastq_dir "/" path1[path_parts1]
    if (NF == 3) {
        path_parts2 = split($3, path2, "/")
        $3 = fastq_dir "/" path2[path_parts2]
    }
    print
}
' "$template" > "$temporary_file"

while IFS=$'\t' read -r sample fastq_1 fastq_2 _; do
    [[ "$sample" == "sample" ]] && continue
    if [[ ! -f "$fastq_1" ]]; then
        echo "錯誤：找不到 $sample 的 FASTQ 1：$fastq_1" >&2
        exit 1
    fi
    if [[ -n "$fastq_2" && ! -f "$fastq_2" ]]; then
        echo "錯誤：找不到 $sample 的 FASTQ 2：$fastq_2" >&2
        exit 1
    fi
done < "$temporary_file"

mv "$temporary_file" "$samplesheet"
trap - EXIT

echo "已更新 samplesheet：$samplesheet"
echo "FASTQ 絕對路徑：$fastq_dir"
