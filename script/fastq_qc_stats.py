#!/usr/bin/env python3
import sys
import os
import gzip

def analyze_fastq(file_path):
    if not os.path.exists(file_path):
        print(f"Error: File '{file_path}' does not exist.", file=sys.stderr)
        sys.exit(1)

    is_gz = file_path.endswith('.gz')
    open_fn = gzip.open if is_gz else open

    total_reads = 0
    total_length = 0
    gc_count = 0

    with open_fn(file_path, 'rt') as f:
        line_num = 0
        for line in f:
            line_num += 1
            mod = line_num % 4
            if mod == 2:  # 序列資料列
                seq = line.strip().upper()
                total_reads += 1
                total_length += len(seq)
                gc_count += seq.count('G') + seq.count('C')

    if total_reads == 0:
        print("Warning: No reads found in the FASTQ file.", file=sys.stderr)
        return

    avg_len = total_length / total_reads
    gc_content = (gc_count / total_length * 100) if total_length > 0 else 0.0

    print("========================================")
    print("        FASTQ QC Statistics Report      ")
    print("========================================")
    print(f"File Path          : {file_path}")
    print(f"Total Reads        : {total_reads:,}")
    print(f"Total Bases        : {total_length:,} bp")
    print(f"Average Read Length: {avg_len:.2f} bp")
    print(f"GC Content (%)     : {gc_content:.2f}%")
    print("========================================")

if __name__ == "__main__":
    target_file = sys.argv[1] if len(sys.argv) > 1 else "data/test_sample.fastq"
    analyze_fastq(target_file)