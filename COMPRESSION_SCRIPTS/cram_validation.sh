# ---qsub parameter settings---
# --these can be overrode at qsub invocation--

# tell sge to execute in bash
#$ -S /bin/bash

# tell sge to submit any of these queue when available
#$ -q rnd.q

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

set

IN_BAM=$1
MAIN_DIR=$2
SM_TAG=$(basename $IN_BAM .bam)
CRAM_DIR=$(echo $IN_BAM | sed -r 's/BAM.*/CRAM/g')

PICARD_DIR="/isilon/sequencing/VITO/Programs/picard/picard-tools-1.141/"
REF_GENOME="/isilon/sequencing/VITO/DATA_FILES/human_g1k_v37_decoy.fasta"

mkdir -p $MAIN_DIR/CRAM_CONVERSION_VALIDATION/

START_CRAM_VALIDATION=`date '+%s'`


java -jar $PICARD_DIR/picard.jar \
ValidateSamFile \
INPUT= $CRAM_DIR/$SM_TAG".cram" \
OUTPUT= $MAIN_DIR/CRAM_CONVERSION_VALIDATION/$SM_TAG"_cram.txt" \
REFERENCE_SEQUENCE=$REF_GENOME \
MODE=SUMMARY \

END_CRAM_VALIDATION=`date '+%s'`

echo $CRAM_DIR/$SM_TAG".cram",VALIDATE_CRAM,$START_CRAM_VALIDATION,$END_CRAM_VALIDATION \
>> /isilon/sequencing/VITO/COMPRESSOR.TEST.WALL.CLOCK.TIMES.csv
