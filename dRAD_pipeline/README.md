# Bioinformatics Pipeline for dRAD tag Data

## Software you will Need
*  ![Stacks](http://catchenlab.life.illinois.edu/stacks/)
*  ![CAP3](http://seq.cs.iastate.edu/cap3.html)
*  ![BWA](http://bio-bwa.sourceforge.net/)
*  ![SAMtools](http://www.htslib.org/)
*  ![VcfTools](http://vcftools.sourceforge.net/man_latest.html)

For this pipeline, you do _not_ need to have MySQL installed (Stacks is designed to run with it, but does not need it).

##### Other Resources
*   ![Basic Unix Commands](http://mally.stanford.edu/~sr/computing/basic-unix.html)
*   ![Vi](http://www.cs.colostate.edu/helpdocs/vi.html) - useful for editing code within the terminal, if you are working in a cluster environment. 

##### General Info.

All of the `perl` scripts written for this pipeline are coded so that if the name of the script is entered in the command line with no other arguments, then the script will print the `USAGE` with an explanation of the required input options.  For example:
```perl
$ perl 1_trimFastq.pl 
1_trimFastq.pl <infile.fastq> <outfile.fastq> <length>
	infile.fastq = The input fastq file
	outfile.fastq = The name of a fastq file for the trimmed output
	length = The length to trim all reads to
```
There are a *couple* of exceptions, where a script is designed to automatically run on all files in the current directory when it is called.  These scripts are pointed out whenever they appear in these instructions. 

## Pipeline Overview
<img src=RADpipeline.png width=600 height=650 />

* De-multiplex and clean up reads to get individual sequences
* Collapse sequences from the same dRAD site to get individual tag sequences
* Create a “Consensus Reference” sequences based on the tags from all individuals
* Align the individual sequence data back to the “Reference” genome
* Call the SNPs for each individual and merge across all individuals

### 1.   Demultiplexing and Trimming
Use `process_radtags` from the ![Stacks](http://catchenlab.life.illinois.edu/stacks/) package to sort the raw data into individual files based on barcode.
* Create a directory for the output called "Pools_Dir" and a file with a list of the barcode sequences with sample names called  "5bp.pools".  The format for the barcode file should be 1 line per barcode, with the barcode given first, then the corresponding sample name separated by a tab.
* Specify the restriction enzyme used to cut by the barcode site (in this example -e ecoRI), and the type of quality score used in the raw data file (this will depend on the machine used to sequence the data, in this case it is –E phred33).
* Retain reads with a single error in the barcode or cut-site, and correct the error (-r); remove reads where the quality threshold drops below the cut-off (-q 10) in a given window size (-w .11).  This will also remove reads with a low quality mate (for paired end data).

Single End Example:
```perl
process_radtags -f 'raw.data.txt' -o Pools_Dir/ -b '5bp.pools' -e ecoRI -E phred33 -r -q -w .11
```

Paired End Example:
```perl
process_radtags -1 'raw_data_1.txt' -2 'raw_data_2.txt' -o Pools_Dir/ -b '5bp.pools' -e ecoRI -E phred33 -r -q -w .11
```
As of the writing of these instructions, `process_radtags` required barcodes to be of the same length.  This means if you have barcodes of differing lengths, you will need to make a separate file for each of them, and run `process_radtags` multiple times.  After doing this, you need to merge the sorted files together for each individual, and then trim all reads to be the same length:
```perl
Pools_Dir$ perl mergeRename.pl 'barcode.pools' SE/PE
Pools_Dir$ perl trimFastq.pl 'Individual_1.fq' 'Individual_1_t.fq' 94
```
### 2.  Find Individual Tag Sequences
After trimming ALL of the individual fastq files to be the same length, use `ustacks` (part of Stacks) to find all unique and nearly unique (99% identical) reads for EACH individual.  Specify the file type (`-t fastq`), the individual fastq file to process (`-f Indiv.fq`), the directory for the output file (`-o Output_Dir`), and a database ID (`-i 1`) (Note that you do not actually need this, but the program will not run without an id specified).  In this step, require a minimum depth of 1 (a higher coverage cutoff will be used in a later step; for now, the goal is to get all tags)(`-m 1`), and allow only 1 mismatch between reads to call a stack (`-M 1 –N1`).  Finally, specify the number of processors (`-p 15`).
```perl
ustacks -t fastq -f  'Indiv_1_t.fq' -o Output_Dir/ -i 1 -m 1 -M 1 -N 1 -p 15
```
Save only the tags.tsv file (you can ignore the snps.tsv and alleles.tsv files since SNPs will be called with a different program later), and process them such that you save the read depth for each consensus tag and convert the tag file into fasta format.  Run the perl script that does this _IN THE FOLDER WITH THE TSV FILES!_
```perl
Tags_Dir$ perl get_stacks_depth.pl
```
Now filter out reads with excessive depth (since these might be PCR duplicates instead of distinct tag sites).  Do this for EACH individual file:
```perl
Tags_Dir$ perl  filter_by_depth.pl 'Indiv_1_stacks.fasta' 1 50 'Indiv_1_filter.fasta'
```
To determine what counts as "excessive" depth for your data, you can look at a histogram of the output from `get_stacks_depth.pl`.
If you have a lot of individual files, here is an example of a `bash` loop that will automatically go through all of them:
```bash
for file in Tags_Dir/*_stacks.fasta
do
	export samplename=`basename $file _stacks.fasta`
	export outname="$samplename.filter.fasta"
	perl filter_by_depth.pl $file 1 50 $outname
```
### 3.  Filter for Paralogs
For EACH “uniqued” and depth-filtered fasta file, run CAP3 with 90% identity to identify and remove any possible paralogs within the individual files.  
```perl
cap3 'Indiv_1_filter.fasta' -p 90 -o 90 
```
Save ONLY the reads without multiple hits; these are in the `cap3.singlets` files.  After running this script on all individuals, run a script _IN THE FOLDER WITH THESE FILES_ to process the singlets files into correctly formatted fasta files:
```perl
Singlets_Dir$ perl fixFasta.pl
```
### 4.  Create the consensus “reference” sequence.
Start by combining all of the “fixed” individual fasta files into 1 file using the unix command `cat`:
```bash
cat *.fixed.fasta >Combined.fasta  
```
Run `ustacks` again to get the necessary tsv files for creating the catalog, then run `cstacks` on the `ustacks` output.  For `cstacks`, specify a batch number to be incorporated into the names of all `cstacks` output files (`-b 604`), an output directory for the cstacks files (`-o Output_Dir`), a maximum of 10 mismatches between tags (`-n 10`), the prefix for all of the `ustacks` output files (this can include the path; `-s Ustacks_prefix`), the database ID number from the ustacks run (`-S 601`) and the number of processors (`-p 45`):
```perl
ustacks -t fasta -f 'Combined.fasta' -o /Output/ -i 101 -m 1 -M 10 -p 15
```
*This will take about 24 hours-best to run on a cluster*
```perl
cstacks -b 604 -o /Output_Dir/ -n 10 -s "Ustacks_prefix" -S 101 -p 45
```
*This should run pretty quickly, but still best on cluster*

Again, save only the tags file from the `cstacks` output (and not the SNPs or alleles files).  The final step is to convert the tags file into a fasta file:
```perl
perl tags2fasta.pl 'catalog.tags.tsv' 'Consensus.fasta'
```
### 5.  Align the individual .fastq files from Step 1 to the new consensus "reference" sequence.
This step uses ![BWA](http://bio-bwa.sourceforge.net/bwa.shtml), and is best done on a cluster so that all individuals can be aligned simultaneously.  Here is an example of the steps in bwa (note that indexing of the reference only needs to be done ONCE).

###### Single-End example:
```bash
bwa index -p ref_prefix -a is Consensus.fasta 
bwa aln -n 10 ref_prefix Indiv_1.fq >Indiv_1.sai
bwa samse ref_prefix Indiv_1.sai Indiv_1.fq >Indiv_1.sam
```
###### Paired-End example
```bash
bwa index -p ref_prefix -a is Consensus.fasta 
bwa aln -n 10 ref_prefix Indiv_1.fq_1 >Indiv_1.sai_1
bwa aln -n 10 ref_prefix Indiv_1.fq_2 >Indiv_1.sai_2
bwa sampe ref_prefix Indiv_1.sai_1 Indiv_1.sai_2 Indiv_1.fq_1 Indiv_1.fq_2 >Indiv_1.sam
```
You can also use `bwa mem` for this step; see the BWA manual for details.

### 6.  Use samtools to process the SAM format files.
Samtools will convert the SAM format files into BAM format and sort them.  Note that the reference sequence only needs to be indexed once, but each individual BAM file must be indexed separately.
```bash
samtools faidx Ref.fasta
samtools view -O BAM Indiv_1.sam -o Indiv_1.bam 
samtools sort -o Indiv_1_sorted.bam -O BAM Indiv_1.bam
samtools index Indiv_1_sorted.bam
```
## Update!
Steps 7-11 outline the process that was originally used to process the data in the ![Molecular Ecology manuscript](http://onlinelibrary.wiley.com/doi/10.1111/mec.14116/abstract), but if you are running this pipeline now I would strongly recommend skipping steps 7-11 (which relied on a *much* older version of `samtools`) and proceeding with steps 6a-6c.

### 6a. Call Variants with Samtools and Bcftools.
*These commands come from the Samtools version 1.5 "best practices" page.*

Start by adding read group information tags to your individual BAM files, to be sure that the individual sample information is retained during the merging steps later.  The ID tag should be the BAM file name (minus the .bam extension), the SM tag should be the sample name (this is what will show up as the label for the sample in the VCF file later).
```bash
samtools addreplacerg -r “ID:Indiv_1_sorted” -r “SM:Indiv_1” -o Indiv_1_wRg.bam Indiv_1_sorted.bam
```
Next, run `mpileup` on ALL of your individual BAM files to get a BCF file that contains all of the positions in the genome:
```bash
samtools mpileup -go All_sites.bcf -f Ref.fasta *_wRg.bam
```
If you are not familiar with command line scripting, the `*` character is a wild card, so the above command will automatically run on all files ending in "_Rg.bam".
Once you have a .bcf file, run `bcftools` to find only the variant sites, and produce the raw VCF file:
```bash
bcftools call -vmO z -o All.vcf.gz All.bcf
```
### 6b.  Filter the VCF file with Vcftools
You can download the latest version of Vcftools ![here](http://vcftools.sourceforge.net/man_latest.html).  Vcftools offers many different filtering options; the ones used for this pipeline are the max. number of alleles (`--max-alleles 2`), the quality threshold (`--minQ 20`), and the minimum and maximum read depths per individual (`--minDP 5 --maxDP 50`).
```bash
vcftools --gvcf All.vcf.gz --max-alleles 2 --minQ 20 --minDP 5 --maxDP 50 --recode --out Filtered.vcf
```

### 6c. Convert the VCF file to the .snps format
This step is optional, but if you'd like to use the scripts from the analysis pipeline associated with ![the paper](http://onlinelibrary.wiley.com/doi/10.1111/mec.14116/abstract), then you will need to convert to the .snps format, which I created to make differentiating between populations more straightforward.
```perl
perl vcf2snps.pl 'Filtered.vcf' 'Filtered.snps' 'populations.txt'
```
The "populations.txt" file is a tab-delimited file with 1 row per sample and 2 columns: column 1 should be a numeric population code, and column should be the sample name.

## Original SNP Calling Steps
### 7.  Create a merged coverage file
This file will contain coverage information for every possible site in the reference “genome” based on the individual pileup files generated by `samtools`. (Note that this step can be a bit slow, since files are being merged one at a time).
```perl
perl makeRefpileup.pl 'Ref.fasta' 'Ref.pileup'
samtools mpileup -f Ref.fasta Indiv_1_sorted.bam >Indiv_1.pileup

perl run_covMerge.pl 'Ref.pileup' /Population_Pileup_Dir/
```
Run `covMerge` separately for each population to make it easier to keep track of files and sample order.  Be sure to check the path to `covMerge.pl` in the `run_covMerge.pl` script!
The last ‘.cov’ file made should contain the combined info. for all individuals in the population.
```perl
paste Pop_1.cov Pop_2.cov >All_Pops.cov 
perl cleanup_cov.pl 'All_Pops.cov' 'Final_Cleaned.cov'
```
### 8.  Call SNPs in each Individual.
Now you will use the vcfutils and bcfutils tools in the SAMtools package to call SNPs for EACH individual.  Use a quality threshold of 20 (-Q 20), and depth cut-off of 50 (-D 50), and a minimum of 1 alternate allele (-a 1).  It is easiest to use a script that will run on an entire population directory at once:
```perl
perl runVCFutils.pl /Population_BAM_Dir/ 'Ref.fasta'
```
The above script is running the following samtools commands:
 ```perl
samtools mpileup -uD –f Ref.fasta $bamfile | bcftools view -bvcg - >$bcffile
bcftools view $bcffile | vcfutils.pl varFilter -Q 20 -D50 -a 1 >$vcffile
```
### 9.  Convert the VCF format files into “genotype” files.
These new files will have homozygous and heterozygous SNP calls (rather than the binary VCF format).  These files will be made individually, but you should run the script within the directory with ALL of the VCF files:
```perl
Population_VCF$ perl ../Scripts/vcf2genotype.pl 
```
### 10.  Get the combined list of SNP sites for all individuals.
These scripts first determine all possible SNP sites, and then get a collective genotypes file (now with a single genotype call per individual) for all individuals at every site:
```perl
perl getSNPpositions.pl 'All.sitelist' <NumIndivs> /VCF_Dir1/ /VCF_Dir2/ … /VCF_DirN/
perl ../Scripts/filterSNPs.pl 'All.sitelist' 'All.genotypes'
```
### 11.  Create the final SNP file.
Finally, merge the collective genotypes file with the merged coverage file from step 7, to fill in reference base information for individuals with X’s:
```perl
sort -n All.genotypes >All_sorted.genotypes
sort -n Final_Cleaned.cov >All_Pops_sorted.cov
perl mergeSNPcov.pl 'All_sorted.genotypes' 'All_sorted.cov' 'All.snps' <NumInd>
```

## A few additional Notes:
Once you have created the BAM files in step 6, you can really proceed with any SNP calling program of your choice, as they will all recognize the BAM format.  BUT, if you did not align to an assembled reference genome, but instead used the consensus tags as your reference as part of the *de novo* pipeline, the I would **strongly** recommend that you continue to use `samtools` and `bcftools` for SNP calling.

Other SNP callers that I have used, such as GATK, seem to have a hard time when there are a large number of "contigs" in the reference genome (regardless of how many total base pairs these add up to).  It seems to be something to do with a position indexing step in those programs, but with ~400K tags in the consensus sequence, GATK will seemingly never get past the reference processing step and runs out of time and/or memory before it ever starts calling SNPs.

