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

set

IN_BAM=$1
MAIN_DIR=$2
SM_TAG=$(basename $IN_BAM .bam)

PICARD_DIR="/isilon/sequencing/VITO/Programs/picard/picard-tools-1.141/"

mkdir -p $MAIN_DIR/BAM_CONVERSION_VALIDATION/

START_BAM_VALIDATION=`date '+%s'`


java -jar $PICARD_DIR/picard.jar \
ValidateSamFile \
INPUT= $IN_BAM \
OUTPUT= $MAIN_DIR/BAM_CONVERSION_VALIDATION/$SM_TAG".original.bam.txt" \
MODE=SUMMARY \

END_BAM_VALIDATION=`date '+%s'`

echo $SM_TAG,VALIDATE_BAM,$START_BAM_VALIDATION,$END_BAM_VALIDATION \
>> /isilon/sequencing/VITO/COMPRESSOR.TEST.WALL.CLOCK.TIMES.csv
