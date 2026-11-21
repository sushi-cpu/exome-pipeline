# Reference Genome Resources

Place your reference FASTA file and associated indexes in this directory:
- `GRCh38.fa` (or `hs38DH.fa` / `hg38.fa`)
- `GRCh38.fa.fai` (samtools index: `samtools faidx GRCh38.fa`)
- `GRCh38.dict` (sequence dictionary: `gatk CreateSequenceDictionary -R GRCh38.fa`)
- BWA / BWA-MEM2 index files (`.bwt`, `.pac`, `.ann`, `.amb`, `.sa`)

For large reference files located on shared or high-performance network storage, configure the external path directly in `exome.config` rather than copying large gigabyte datasets into the project directory.
