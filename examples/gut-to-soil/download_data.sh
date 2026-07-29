#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
project_dir="$(cd "${script_dir}/../.." && pwd -P)"
data_dir="${script_dir}/data"
fastq_dir="${data_dir}/fastq"
metadata_url="https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/sample-metadata.tsv"
demux_url="https://gut-to-soil-tutorial.readthedocs.io/en/2026.4/data/gut-to-soil/demux.qza"
metadata_sha256="58ef2e8d198ce89e74c3a9b40f06d88066ec2f76918f857635dc4cd2a3f23a1a"
demux_sha256="2e96e8a091e6b4ecf4635a10b18d3c4af2d2c4b98fd2772faeaf5bfe5f50b4a3"
temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/gut-to-soil.XXXXXX")"

trap 'rm -rf -- "$temporary_dir"' EXIT

for required_command in curl unzip sha256sum gzip python3; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "錯誤：找不到必要指令：$required_command" >&2
        exit 1
    fi
done

verify_sha256() {
    local path="$1"
    local expected="$2"
    local actual
    actual="$(sha256sum "$path" | awk '{print $1}')"
    if [[ "$actual" != "$expected" ]]; then
        echo "錯誤：SHA-256 不符：$path" >&2
        echo "預期：$expected" >&2
        echo "實際：$actual" >&2
        exit 1
    fi
}

mkdir -p "$fastq_dir"

echo "下載 Gut-to-Soil metadata 與 demux.qza..."
curl -L --fail --silent --show-error \
    -o "${temporary_dir}/metadata.raw.tsv" "$metadata_url"
curl -L --fail --silent --show-error \
    -o "${temporary_dir}/demux.qza" "$demux_url"

verify_sha256 "${temporary_dir}/metadata.raw.tsv" "$metadata_sha256"
verify_sha256 "${temporary_dir}/demux.qza" "$demux_sha256"

mkdir -p "${temporary_dir}/fastq"
unzip -q -j "${temporary_dir}/demux.qza" '*/data/*.fastq.gz' \
    -d "${temporary_dir}/fastq"

downloaded_count="$(
    find "${temporary_dir}/fastq" -maxdepth 1 -type f -name '*.fastq.gz' |
        wc -l
)"
if [[ "$downloaded_count" -ne 208 ]]; then
    echo "錯誤：demux.qza 應包含 208 個 FASTQ，實際為 ${downloaded_count}" >&2
    exit 1
fi
find "${temporary_dir}/fastq" -maxdepth 1 -type f -name '*.fastq.gz' \
    -print0 | xargs -0 gzip -t

existing_count="$(
    find "$fastq_dir" -maxdepth 1 -type f -name '*.fastq.gz' | wc -l
)"
if [[ "$existing_count" -eq 0 ]]; then
    cp "${temporary_dir}/fastq/"*.fastq.gz "$fastq_dir/"
elif [[ "$existing_count" -eq 208 ]]; then
    if ! diff -u \
        <(
            find "${temporary_dir}/fastq" -maxdepth 1 -type f \
                -name '*.fastq.gz' -printf '%f\n' | sort
        ) \
        <(
            find "$fastq_dir" -maxdepth 1 -type f \
                -name '*.fastq.gz' -printf '%f\n' | sort
        ) >/dev/null
    then
        echo "錯誤：現有 FASTQ 檔名與固定的 Gut-to-Soil 資料不一致" >&2
        exit 1
    fi
    find "$fastq_dir" -maxdepth 1 -type f -name '*.fastq.gz' \
        -print0 | xargs -0 gzip -t
else
    echo "錯誤：${fastq_dir} 已有 ${existing_count} 個 FASTQ；請先確認內容" >&2
    exit 1
fi

cp "${temporary_dir}/metadata.raw.tsv" "${data_dir}/metadata.raw.tsv"
python3 "${script_dir}/prepare_gut_to_soil.py"
python3 "${script_dir}/clean_metadata.py"
bash "${project_dir}/03_scripts/prepare_samplesheet.sh" \
    --data-dir "$data_dir"

echo "Gut-to-Soil 已準備完成：104 組 paired-end samples。"
echo "資料目錄：$data_dir"
