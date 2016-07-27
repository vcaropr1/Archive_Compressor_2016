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
MAIN_DIR=$2

BAM_DIR=$(dirname $IN_BAM)
BAM_MAIN_DIR=$(echo $BAM_DIR | sed -r 's/BAM.*//g')
CRAM_DIR=$(echo $BAM_DIR | sed -r 's/BAM.*//g')/CRAM
SM_TAG=$(basename $IN_BAM .bam) 
DATAMASH_EXE=/isilon/sequencing/Kurt/Programs/PATH/datamash
SAMTOOLS_EXE=/isilon/sequencing/VITO/Programs/samtools/samtools-1.3.1/samtools

CRAM_ONLY_ERRORS=$(grep -F -x -v -f $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG"_bam.txt" $MAIN_DIR/CRAM_CONVERSION_VALIDATION/$SM_TAG"_cram.txt")

# BAM_ONLY_ERRORS=$(grep -F -x -v -f $MAIN_DIR/CRAM_CONVERSION_VALIDATION/$SM_TAG"_cram.txt" $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG".original.bam.txt")

## Create two temp files for the output of flagstat for bam and cram file.  If the two files are the same AND the CRAM_ONLY_ERRORS variable is null will the output verify the conversion was sucessful.  If either of these fail, the error file will show this.  

 $SAMTOOLS_EXE flagstat $BAM_DIR/$SM_TAG.bam >| $MAIN_DIR/TEMP/$SM_TAG".bam.flagstat.out"
 $SAMTOOLS_EXE flagstat $CRAM_DIR/$SM_TAG.cram >| $MAIN_DIR/TEMP/$SM_TAG".cram.flagstat.out"

if [[ -z $(diff $MAIN_DIR/TEMP/$SM_TAG".bam.flagstat.out" $MAIN_DIR/TEMP/$SM_TAG".cram.flagstat.out" ) && -z $CRAM_ONLY_ERRORS ]]
then
 echo CRAM COMPRESSION WAS COMPLETED SUCCESSFULLY
echo -e $IN_BAM\\tPASS\\t$CRAM_ONLY_ERRORS | sed -r 's/[[:space:]]+/\t/g' >> $MAIN_DIR/cram_conversion_validation.list
rm -f $BAM_DIR/$SM_TAG.bam
rm -f $BAM_DIR/$SM_TAG.bai
else
 	echo CRAM COMPRESSION WAS UNSUCCESSFUL
	(echo BAM; cat $MAIN_DIR/TEMP/$SM_TAG".bam.flagstat.out"; echo -e \\nCRAM; cat $MAIN_DIR/TEMP/$SM_TAG".cram.flagstat.out") >| $MAIN_DIR/TEMP/$SM_TAG".combined.flagstat.out"
	echo -e $IN_BAM\\tFAIL\\t$CRAM_ONLY_ERRORS | sed -r 's/[[:space:]]+/\t/g' >> $MAIN_DIR/cram_conversion_validation.list
	mail -s "$IN_BAM Failed Cram conversion-Cram Flagstat Output" vcaropr1@jhmi.edu < $MAIN_DIR/TEMP/$SM_TAG".combined.flagstat.out"
fi

if [[ $(find  $BAM_MAIN_DIR/BAM -type f | wc -l) == 0 ]]
	then
	rm -rvf $BAM_MAIN_DIR/BAM
	rm -rvf $MAIN_DIR/TEMP/*
fi

 echo $CRAM_DIR/$SM_TAG".cram",BAM_CRAM_VALIDATION_COMPARE,$START_CRAM_VALIDATION,$END_CRAM_VALIDATION \
 >> $MAIN_DIR/COMPRESSOR.TEST.WALL.CLOCK.TIMES.csv

##Something to work on/think about.... Output to e-mail being side by side
#	paste  $MAIN_DIR/TEMP/$SM_TAG".bam.flagstat.out" $MAIN_DIR/TEMP/$SM_TAG".cram.flagstat.out" | awk 'BEGIN {FS="\t" ; print "BAM""\t""CRAM"} { printf "%-100s %s\n", $1, $2 }' >| $MAIN_DIR/TEMP/$SM_TAG".combined.flagstat.out"
