#!/usr/bin/env bash
set -euo pipefail

ampliseq_version="2.18.0"
nf_core_tools_version="4.0.3"
user_work_root="/work/${USER}"
pipeline_dir="${user_work_root}/nf-core_download/ampliseq-${ampliseq_version}"
workflow_dir="${pipeline_dir}/2_18_0"
reference_dir="${user_work_root}/reference_databases/ampliseq/silva-138.2"
assets_marker="${pipeline_dir}/.offline-assets-ready"
container_manifest="${pipeline_dir}/.offline-container-manifest.tsv"
legacy_cache_dir="${user_work_root}/containers/singularity_cache"
cache_version="ampliseq-${ampliseq_version}_nfcore-${nf_core_tools_version}"

export UV_CACHE_DIR="${UV_CACHE_DIR:-${user_work_root}/uv/cache}"

module purge
module load biology/Nextflow/26.04.6 singularity/4.3.7

# The NCHC Nextflow module exports a shared cache path. Override it only after
# loading modules. Pinning the cache layout and nf-core/tools version prevents
# the same image being downloaded again under a different filename convention.
export NXF_SINGULARITY_CACHEDIR="${legacy_cache_dir}/${cache_version}"
mkdir -p "$NXF_SINGULARITY_CACHEDIR" "$UV_CACHE_DIR" "$reference_dir"

for required_command in uv nextflow singularity wget gzip; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        echo "錯誤：找不到必要指令：$required_command" >&2
        exit 1
    fi
done

# Verify image integrity and remove broken symlinks or corrupt small files (< 1MB)
shopt -s nullglob
for legacy_image in "${legacy_cache_dir}"/*.img; do
    cache_image="${NXF_SINGULARITY_CACHEDIR}/$(basename "$legacy_image")"
    if [[ ! -e "$cache_image" && ! -L "$cache_image" ]]; then
        if [[ -s "$legacy_image" ]] && [[ $(stat -c%s "$legacy_image" 2>/dev/null || echo 0) -gt 1048576 ]]; then
            ln -s "$legacy_image" "$cache_image"
        fi
    fi
done

for img in "${NXF_SINGULARITY_CACHEDIR}"/*.img; do
    if [[ ! -e "$img" ]] || [[ $(stat -c%s "$img" 2>/dev/null || echo 0) -lt 1048576 ]]; then
        echo "警告：發現無效或損毀之 Singularity 映像檔，自動清除：$img" >&2
        rm -f "$img"
    fi
done
shopt -u nullglob

verify_container_manifest() {
    [[ -s "$container_manifest" ]] || return 1

    local image_name expected_size image_path actual_size image_count=0
    while IFS=$'\t' read -r image_name expected_size; do
        [[ -n "$image_name" ]] || continue
        image_path="${NXF_SINGULARITY_CACHEDIR}/${image_name}"
        if [[ ! -e "$image_path" ]]; then
            echo "警告：容器 manifest 中的映像不存在：$image_path" >&2
            return 1
        fi
        actual_size="$(stat -Lc%s "$image_path" 2>/dev/null || echo 0)"
        if [[ "$actual_size" -lt 1048576 || "$actual_size" != "$expected_size" ]]; then
            echo "警告：容器映像大小與 manifest 不符：$image_path" >&2
            return 1
        fi
        ((image_count += 1))
    done < "$container_manifest"

    (( image_count > 0 ))
}

write_container_manifest() {
    local temporary_manifest="${container_manifest}.tmp"
    local image image_size image_count=0
    : > "$temporary_manifest"

    shopt -s nullglob
    for image in "${NXF_SINGULARITY_CACHEDIR}"/*.img; do
        if [[ -e "$image" ]]; then
            image_size="$(stat -Lc%s "$image")"
            printf '%s\t%s\n' "$(basename "$image")" "$image_size" >> "$temporary_manifest"
            ((image_count += 1))
        fi
    done
    shopt -u nullglob

    if (( image_count == 0 )); then
        echo "錯誤：nf-core download 完成後仍找不到任何 Singularity image" >&2
        rm -f "$temporary_manifest"
        return 1
    fi
    sort -o "$temporary_manifest" "$temporary_manifest"
    mv "$temporary_manifest" "$container_manifest"
}

marker_is_current=false
if [[ -f "$assets_marker" ]] &&
   grep -qxF "ampliseq=${ampliseq_version}" "$assets_marker" &&
   grep -qxF "nf_core_tools=${nf_core_tools_version}" "$assets_marker" &&
   grep -qxF "container_cache=${NXF_SINGULARITY_CACHEDIR}" "$assets_marker" &&
   [[ -f "${workflow_dir}/main.nf" ]] &&
   verify_container_manifest
then
    marker_is_current=true
fi

if [[ "$marker_is_current" != true ]]; then
    echo "下載 nf-core/ampliseq ${ampliseq_version} 與 Singularity images..."
    staging_parent="$(mktemp -d "/tmp/ampliseq-${ampliseq_version}.XXXXXX")"
    staging_dir="${staging_parent}/download"
    trap 'rm -rf "$staging_parent"' EXIT

    uv tool run --from "nf-core==${nf_core_tools_version}" nf-core pipelines download ampliseq \
        --revision "$ampliseq_version" \
        --outdir "$staging_dir" \
        --compress none \
        --download-configuration no \
        --container-system singularity \
        --container-cache-utilisation amend \
        --parallel-downloads 4

    if [[ ! -f "${staging_dir}/2_18_0/main.nf" ]]; then
        echo "錯誤：暫存下載中找不到 2_18_0/main.nf" >&2
        exit 1
    fi

    mkdir -p "$pipeline_dir"
    cp -a "${staging_dir}/." "$pipeline_dir/"
    write_container_manifest
    marker_temporary="${assets_marker}.tmp"
    {
        echo "ampliseq=${ampliseq_version}"
        echo "nf_core_tools=${nf_core_tools_version}"
        echo "container_cache=${NXF_SINGULARITY_CACHEDIR}"
    } > "$marker_temporary"
    mv "$marker_temporary" "$assets_marker"

    rm -rf "$staging_parent"
    trap - EXIT
else
    echo "Pipeline、Singularity images 與版本標記皆有效，略過下載。"
fi

download_reference() {
    local url="$1"
    local destination="$2"
    local partial="${destination}.part"

    if [[ -s "$destination" ]] && gzip -t "$destination"; then
        echo "參考檔已存在且 gzip 完整：$destination"
        return 0
    fi
    rm -f "$destination"

    wget --continue --output-document "$partial" "$url"
    if ! gzip -t "$partial"; then
        echo "錯誤：下載的參考檔不是有效 gzip：$partial" >&2
        return 1
    fi
    mv "$partial" "$destination"
}

download_reference \
    "https://zenodo.org/records/14169026/files/silva_nr99_v138.2_toSpecies_trainset.fa.gz" \
    "${reference_dir}/silva_nr99_v138.2_toSpecies_trainset.fa.gz"

download_reference \
    "https://zenodo.org/records/14169026/files/silva_v138.2_assignSpecies.fa.gz" \
    "${reference_dir}/silva_v138.2_assignSpecies.fa.gz"

if [[ ! -f "${workflow_dir}/main.nf" ]]; then
    echo "錯誤：找不到下載後的 2_18_0/main.nf" >&2
    exit 1
fi

echo "離線執行資產已準備完成："
echo "  Pipeline: $workflow_dir"
echo "  Containers: $NXF_SINGULARITY_CACHEDIR"
echo "  SILVA: $reference_dir"
