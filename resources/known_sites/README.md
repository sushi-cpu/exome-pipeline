# Known Sites Variant Annotations

Store known polymorphic sites for GATK Base Quality Score Recalibration (BQSR):
- dbSNP (e.g. `Homo_sapiens_assembly38.dbsnp138.vcf.gz`)
- 1000 Genomes (e.g. `1000G_phase1.snps.high_confidence.hg38.vcf.gz`)
- Mills and 1000G Gold Standard indels (e.g. `Mills_and_1000G_gold_standard.indels.hg38.vcf.gz`)

All VCF files must be:
1. Block-gzipped using `bgzip`
2. Tabix indexed (`tabix -p vcf <file>.vcf.gz`)
3. Aligned to the exact same reference coordinate build as your reference FASTA.
