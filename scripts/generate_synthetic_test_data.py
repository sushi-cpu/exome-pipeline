#!/usr/bin/env python3
"""
Generate minimal synthetic dataset for testing and validating the exome pipeline.
Produces:
  - resources/reference/mini_ref.fa (mini synthetic reference contig)
  - resources/reference/mini_ref.fa.fai
  - resources/reference/mini_ref.dict
  - resources/intervals/exome_targets.bed
  - resources/known_sites/known_sites.vcf
  - test_data/test_sample_R1.fastq.gz
  - test_data/test_sample_R2.fastq.gz
"""
import os
import gzip
import random

random.seed(42)

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF_DIR = os.path.join(BASE_DIR, "resources", "reference")
KNOWN_DIR = os.path.join(BASE_DIR, "resources", "known_sites")
BED_DIR = os.path.join(BASE_DIR, "resources", "intervals")
TEST_DATA_DIR = os.path.join(BASE_DIR, "test_data")

os.makedirs(REF_DIR, exist_ok=True)
os.makedirs(KNOWN_DIR, exist_ok=True)
os.makedirs(BED_DIR, exist_ok=True)
os.makedirs(TEST_DATA_DIR, exist_ok=True)

CHROM = "chr22_mini"
LENGTH = 10000
BASES = ["A", "C", "G", "T"]

# 1. Generate Reference FASTA
ref_seq = "".join(random.choices(BASES, weights=[0.25, 0.25, 0.25, 0.25], k=LENGTH))
ref_fa = os.path.join(REF_DIR, "mini_ref.fa")
with open(ref_fa, "w") as f:
    f.write(f">{CHROM}\n")
    for i in range(0, LENGTH, 80):
        f.write(ref_seq[i:i+80] + "\n")

# .fai index: NAME LENGTH OFFSET LINEBASES LINEWIDTH
# Header is len(f">{CHROM}\n") = 13 bytes
with open(os.path.join(REF_DIR, "mini_ref.fa.fai"), "w") as f:
    f.write(f"{CHROM}\t{LENGTH}\t{len(CHROM)+2}\t80\t81\n")

# .dict sequence dictionary
with open(os.path.join(REF_DIR, "mini_ref.dict"), "w") as f:
    f.write("@HD\tVN:1.6\tSO:unsorted\n")
    f.write(f"@SQ\tSN:{CHROM}\tLN:{LENGTH}\n")

# 2. Exome Target Intervals BED
bed_file = os.path.join(BED_DIR, "exome_targets.bed")
with open(bed_file, "w") as f:
    f.write(f"{CHROM}\t100\t2500\texon1\n")
    f.write(f"{CHROM}\t3000\t5500\texon2\n")
    f.write(f"{CHROM}\t6000\t9000\texon3\n")

# 3. Known sites VCF
known_vcf = os.path.join(KNOWN_DIR, "known_sites.vcf")
with open(known_vcf, "w") as f:
    f.write("##fileformat=VCFv4.2\n")
    f.write(f"##contig=<ID={CHROM},length={LENGTH}>\n")
    f.write('##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency">\n')
    f.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")
    for pos in [500, 1500, 3500, 4200, 7500]:
        ref_b = ref_seq[pos - 1]
        alt_b = "G" if ref_b != "G" else "A"
        f.write(f"{CHROM}\t{pos}\trs{pos}\t{ref_b}\t{alt_b}\t100\tPASS\tAF=0.05\n")

# Try to bgzip and tabix if available
try:
    import subprocess
    vcf_gz = known_vcf + ".gz"
    subprocess.run(["bgzip", "-c", known_vcf], stdout=open(vcf_gz, "wb"), check=True)
    subprocess.run(["tabix", "-p", "vcf", "-f", vcf_gz], check=True)
except Exception:
    pass

# 4. Generate Paired-end FASTQs
r1_gz = os.path.join(TEST_DATA_DIR, "test_sample_R1.fastq.gz")
r2_gz = os.path.join(TEST_DATA_DIR, "test_sample_R2.fastq.gz")

with gzip.open(r1_gz, "wt") as f1, gzip.open(r2_gz, "wt") as f2:
    for idx in range(1, 101):
        start = random.randint(100, LENGTH - 600)
        frag_len = random.randint(250, 400)
        read_len = 100
        
        frag = ref_seq[start:start+frag_len]
        r1_seq = frag[:read_len]
        
        # reverse complement for R2
        tr = str.maketrans("ACGTacgt", "TGCAtgca")
        r2_seq = frag[-read_len:].translate(tr)[::-1]
        
        qual = "I" * read_len  # Phred 40
        
        f1.write(f"@READ_{idx}/1\n{r1_seq}\n+\n{qual}\n")
        f2.write(f"@READ_{idx}/2\n{r2_seq}\n+\n{qual}\n")

print(f"Synthetic test data generated successfully in {BASE_DIR}")
