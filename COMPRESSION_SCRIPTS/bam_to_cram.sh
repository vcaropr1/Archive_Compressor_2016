# ---qsub parameter settings---
# --these can be overrode at qsub invocation--

# tell sge to execute in bash
#$ -S /bin/bash

# tell sge to submit any of these queue when available
#$ -q rnd.q,prod.q,test.q

# tell sge that you are in the users current working directory
#$ -cwd

# tell sge to export the users environment variables
#$ -V

# tell sge to submit at this priority setting
#$ -p -1020

# tell sge to output both stderr and stdout to the same file
#$ -j y

# export all variables, useful to find out what compute node the program was executed on
# redirecting stderr/stdout to file as a log.

IN_BAM=$1
BAM_DIR=$(dirname $IN_BAM)
CRAM_DIR=$(echo $BAM_DIR | sed -r 's/BAM.*//g')/CRAM
REF_GENOME=/isilon/sequencing/GATK_resource_bundle/bwa_mem_0.7.5a_ref/human_g1k_v37_decoy.fasta # Reference genome used for creating BAM file. Needs to be indexed with samtools faidx (would have ref.fasta.fai companion file)
SM_TAG=$(basename $IN_BAM .bam) 
BAM_FILE_SIZE=$(du -a $IN_BAM | awk '{print $1}')

START_CRAM=`date '+%s'`

mkdir -p $CRAM_DIR

SAMTOOLS_EXEC=/isilon/sequencing/VITO/Programs/samtools/samtools-1.3.1/samtools
# For further information: http://www.htslib.org/doc/samtools.html

##CMD FOR FOROUD LANDERS ONLY
$SAMTOOLS_EXEC view -C $IN_BAM -o $CRAM_DIR/$SM_TAG".cram" -T $REF_GENOME

# Use samtools-1.3.1 devel to create an index file for the recently created cram file with the extension .crai
$SAMTOOLS_EXEC index $CRAM_DIR/$SM_TAG".cram"

CRAM_FILE_SIZE=$(du -a $SM_TAG".cram" | awk '{print $1}')

md5sum $CRAM_DIR/$SM_TAG".cram" >> $CRAM_DIR/"cram_md5.list"
md5sum $CRAM_DIR/$SM_TAG".cram.crai" >> $CRAM_DIR/"cram_md5.list"

END_CRAM=`date '+%s'`

 echo $IN_BAM,CRAM,$BAM_FILE_SIZE,$CRAM_FILE_SIZE,$START_CRAM,$END_CRAM \
 >> /isilon/sequencing/VITO/cram_compression_times.csv