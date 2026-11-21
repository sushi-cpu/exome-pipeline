# Exome Target Capture Intervals

Place the target capture bed file matching your exome enrichment kit (e.g., Agilent SureSelect, Twist Human Core Exome, Illumina TruSeq):
- `exome_targets.bed`

Format:
- 0-based BED3 or BED4 (chrom, start, end, [name])
- Ensure chromosome naming matches the reference FASTA (`chr1` vs `1`).
