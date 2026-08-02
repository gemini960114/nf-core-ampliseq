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
biostrings_image_name="bioconductor-biostrings-2.58.0--r40h037d062_0.img"
biostrings_cache_alias_name="depot.galaxyproject.org-singularity-bioconductor-biostrings-2.58.0--r40h037d062_0.img"

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

# Reject obvious download errors cheaply. Full `singularity inspect` validation
# is reserved for new or changed images so repeated runs stay fast.
container_is_plausible() {
    local image="$1"
    [[ -e "$image" ]] &&
        [[ $(stat -Lc%s "$image" 2>/dev/null || echo 0) -gt 1048576 ]]
}

container_is_valid() {
    local image="$1"
    container_is_plausible "$image" &&
        singularity inspect "$image" >/dev/null 2>&1
}

# Verify image integrity and remove broken symlinks or corrupt small files.
shopt -s nullglob
for legacy_image in "${legacy_cache_dir}"/*.img; do
    cache_image="${NXF_SINGULARITY_CACHEDIR}/$(basename "$legacy_image")"
    if [[ ! -e "$cache_image" && ! -L "$cache_image" ]]; then
        if [[ -s "$legacy_image" ]] && [[ $(stat -Lc%s "$legacy_image" 2>/dev/null || echo 0) -gt 1048576 ]]; then
            ln -s "$legacy_image" "$cache_image"
        fi
    fi
done

# Remove obsolete registry aliases created by an older revision of this script.
# Keep the Biostrings alias because Nextflow derives that exact cache key from
# the retired Galaxy Depot URI embedded in ampliseq 2.18.0.
for registry_alias in \
    "${NXF_SINGULARITY_CACHEDIR}"/depot.galaxyproject.org-singularity-*.img \
    "${NXF_SINGULARITY_CACHEDIR}"/quay.io-*.img \
    "${NXF_SINGULARITY_CACHEDIR}"/community.wave.seqera.io-library-*.img \
    "${NXF_SINGULARITY_CACHEDIR}"/community-cr-prod.seqera.io-docker-registry-v2-*.img
do
    if [[ $(basename "$registry_alias") == "$biostrings_cache_alias_name" ]]; then
        continue
    fi
    if [[ -L "$registry_alias" ]]; then
        rm -f "$registry_alias"
    fi
done

for img in "${NXF_SINGULARITY_CACHEDIR}"/*.img; do
    if ! container_is_plausible "$img"; then
        echo "警告：發現無效或損毀之 Singularity 映像檔，自動清除：$img" >&2
        rm -f "$img"
    fi
done
shopt -u nullglob

# Point a Nextflow cache key at an already validated image without duplicating
# the image contents. Refuse to replace a regular file automatically.
ensure_container_alias() {
    local source="$1"
    local alias="$2"

    if ! container_is_valid "$source"; then
        echo "錯誤：無法為無效的 Singularity image 建立 alias：$source" >&2
        return 1
    fi

    if [[ -e "$alias" && ! -L "$alias" ]]; then
        if container_is_valid "$alias"; then
            return 0
        fi
        echo "錯誤：Nextflow cache alias 路徑被無效的一般檔案占用：$alias" >&2
        return 1
    fi

    if [[ -L "$alias" ]]; then
        rm -f "$alias"
    fi
    ln -s "$(basename "$source")" "$alias"
}

# ampliseq 2.18.0 still refers to a Galaxy Depot URL that now returns a 153-byte
# 404 page. Build the same pinned Biocontainers image from its OCI source, then
# create the exact URI-derived cache alias that Nextflow expects.
repair_retired_container_urls() {
    local target="${NXF_SINGULARITY_CACHEDIR}/${biostrings_image_name}"
    local cache_alias="${NXF_SINGULARITY_CACHEDIR}/${biostrings_cache_alias_name}"
    local partial="${target}.part"
    local source="docker://quay.io/biocontainers/bioconductor-biostrings:2.58.0--r40h037d062_0"

    if ! container_is_valid "$target"; then
        echo "修復已失效的 Galaxy Depot image：$source"
        rm -f "$partial"
        if ! singularity pull "$partial" "$source"; then
            rm -f "$partial"
            return 1
        fi
        if ! container_is_valid "$partial"; then
            echo "錯誤：替代來源未產生有效的 Singularity image：$source" >&2
            rm -f "$partial"
            return 1
        fi
        mv "$partial" "$target"
    fi

    ensure_container_alias "$target" "$cache_alias"
}

# Check that every image recorded by the previous successful run still exists.
# Size is deliberately re-baselined after a valid image is repaired.
verify_container_inventory() {
    [[ -s "$container_manifest" ]] || return 1

    local image_name expected_size image_path actual_size image_count=0
    while IFS=$'\t' read -r image_name expected_size; do
        [[ -n "$image_name" ]] || continue
        image_path="${NXF_SINGULARITY_CACHEDIR}/${image_name}"
        if [[ ! -e "$image_path" ]]; then
            case "$image_name" in
                depot.galaxyproject.org-singularity-*|quay.io-*|community.wave.seqera.io-library-*|community-cr-prod.seqera.io-docker-registry-v2-*)
                    continue
                    ;;
            esac
        fi
        if ! container_is_plausible "$image_path"; then
            echo "警告：容器 manifest 中的映像不存在或無效：$image_path" >&2
            return 1
        fi
        actual_size="$(stat -Lc%s "$image_path")"
        if [[ "$actual_size" != "$expected_size" ]] && ! container_is_valid "$image_path"; then
            echo "警告：容器映像大小已改變且無法通過檢查：$image_path" >&2
            return 1
        fi
        ((image_count += 1))
    done < "$container_manifest"

    (( image_count > 0 ))
}

verify_all_cached_containers() {
    local image image_count=0

    shopt -s nullglob
    for image in "${NXF_SINGULARITY_CACHEDIR}"/*.img; do
        if ! container_is_valid "$image"; then
            echo "錯誤：下載結果不是有效的 Singularity image：$image" >&2
            shopt -u nullglob
            return 1
        fi
        ((image_count += 1))
    done
    shopt -u nullglob

    (( image_count > 0 ))
}

write_container_manifest() {
    local temporary_manifest="${container_manifest}.tmp"
    local image image_size image_count=0
    : > "$temporary_manifest"

    shopt -s nullglob
    for image in "${NXF_SINGULARITY_CACHEDIR}"/*.img; do
        # Cache aliases are recreated deterministically and must not make one
        # physical image appear multiple times in the offline inventory.
        if [[ -L "$image" ]]; then
            continue
        fi
        if ! container_is_plausible "$image"; then
            echo "錯誤：拒絕將無效容器寫入 manifest：$image" >&2
            rm -f "$temporary_manifest"
            shopt -u nullglob
            return 1
        fi
        image_size="$(stat -Lc%s "$image")"
        printf '%s\t%s\n' "$(basename "$image")" "$image_size" >> "$temporary_manifest"
        ((image_count += 1))
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
# Seed the exact Nextflow cache key before nf-core download. This also makes a
# clean installation independent of the retired Galaxy Depot endpoint.
repair_retired_container_urls

if [[ -f "$assets_marker" ]] &&
   grep -qxF "ampliseq=${ampliseq_version}" "$assets_marker" &&
   grep -qxF "nf_core_tools=${nf_core_tools_version}" "$assets_marker" &&
   grep -qxF "container_cache=${NXF_SINGULARITY_CACHEDIR}" "$assets_marker" &&
   [[ -f "${workflow_dir}/main.nf" ]] &&
   verify_container_inventory
then
    # Recreate a normalized manifest after validating the old inventory. This
    # drops obsolete registry aliases and records repaired image sizes.
    write_container_manifest
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
    repair_retired_container_urls
    verify_all_cached_containers
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
