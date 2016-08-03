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

# TEST TO SEE IF EMAIL IS SENT IF JOB IS SUSPENDED OR ABORTED
#$ -m a

# TEST TO SEE IF EMAIL COMES TO ME
#$ -M vcaropr1@cidr.jhmi.edu

# export all variables, useful to find out what compute node the program was executed on
# redirecting stderr/stdout to file as a log.

# Reference genome used for creating BAM file. Needs to be indexed with samtools faidx (would have ref.fasta.fai companion file)
set

IN_BAM=$1
DIR_TO_PARSE=$2
REF_GENOME=$3

BAM_DIR=$(dirname $IN_BAM)
BAM_MAIN_DIR=$(echo $BAM_DIR | sed -r 's/BAM.*//g')
CRAM_DIR=$(echo $BAM_DIR | sed -r 's/BAM.*//g')/CRAM
GATK_DIR=/isilon/sequencing/CIDRSeqSuiteSoftware/gatk/GATK_3/GenomeAnalysisTK-3.5-0
JAVA_1_7=/isilon/sequencing/Kurt/Programs/Java/jdk1.7.0_25/bin
SAMTOOLS_EXEC=/isilon/sequencing/VITO/Programs/samtools/samtools-develop/samtools
SM_TAG=$(basename $IN_BAM .bam) 
BAM_FILE_SIZE=$(du -ab $IN_BAM | awk '{print $1}')

#BQSR path and files seem to very slightly... Also some files have been ran mutliple times.  This pulls the directory above the BAM folder to search from and sort the output in directory structure to take the top one
BQSR_FILE=$(find $BAM_MAIN_DIR -depth -name $SM_TAG".bqsr" -or -name  ${SM_TAG}*P*.bqsr | head -n1)

mkdir -p $CRAM_DIR
mkdir -p $DIR_TO_PARSE/TEMP

START_CRAM=`date '+%s'`

BIN_QUALITY_SCORES_REMOVE_TAGS_AND_CRAM(){
$JAVA_1_7/java -jar $GATK_DIR/GenomeAnalysisTK.jar \
-T PrintReads \
-R $REF_GENOME \
-I $IN_BAM \
-BQSR $BQSR_FILE \
-dt NONE \
-SQQ 10 \
-SQQ 20 \
-SQQ 30 \
-SQQ 40 \
-EOQ \
-nct 6 \
-o $DIR_TO_PARSE/TEMP/$SM_TAG"_binned.bam"

$SAMTOOLS_EXEC view -C $DIR_TO_PARSE/TEMP/$SM_TAG"_binned.bam" -x BI -x BD -x BQ -o $CRAM_DIR/$SM_TAG".cram" -T $REF_GENOME -@ 4

# Use samtools-1.3.1 devel to create an index file for the recently created cram file with the extension .crai
$SAMTOOLS_EXEC index $CRAM_DIR/$SM_TAG".cram"
mv $CRAM_DIR/$SM_TAG".cram.crai" $CRAM_DIR/$SM_TAG".crai"

# rm -f  $DIR_TO_PARSE/TEMP/$SM_TAG"_binned.bam"
# rm -f  $DIR_TO_PARSE/TEMP/$SM_TAG"_binned.bai"
}

REMOVE_TAGS_AND_CRAM_NO_BQSR(){
$SAMTOOLS_EXEC view -C $IN_BAM -x BI -x BD -x BQ -o $CRAM_DIR/$SM_TAG".cram" -T $REF_GENOME -@ 4

# Use samtools-1.3.1 devel to create an index file for the recently created cram file with the extension .crai
$SAMTOOLS_EXEC index $CRAM_DIR/$SM_TAG".cram"
mv $CRAM_DIR/$SM_TAG".cram.crai" $CRAM_DIR/$SM_TAG".crai"
}



if [[ -e $BQSR_FILE ]]
	then
	BIN_QUALITY_SCORES_REMOVE_TAGS_AND_CRAM
else
	REMOVE_TAGS_AND_CRAM_NO_BQSR
fi

CRAM_FILE_SIZE=$(du -ab $CRAM_DIR/$SM_TAG".cram" | awk '{print $1}')

md5sum $CRAM_DIR/$SM_TAG".cram" >> $DIR_TO_PARSE/MD5_REPORTS/cram_md5.list
md5sum $CRAM_DIR/$SM_TAG".crai" >> $DIR_TO_PARSE/MD5_REPORTS/cram_md5.list

END_CRAM=`date '+%s'`

echo $IN_BAM,CRAM,$BAM_FILE_SIZE,$CRAM_FILE_SIZE,$START_CRAM,$END_CRAM \
>> $DIR_TO_PARSE/cram_compression_times.csv
