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

MAIN_DIR=$1
DATAMASH_EXE=/isilon/sequencing/Kurt/Programs/PATH/datamash

for f in $MAIN_DIR/CRAM_CONVERSION_VALIDATION/* 
do
	FILE=$(basename $f _cram.txt)
	grep "^ERROR" $f | awk '{OFS="\t"}{print "'$FILE'",$0}' | $DATAMASH_EXE -g 1 collapse 2 collapse 3 >> $MAIN_DIR/cram_files_potentially_corrupted.list
done

echo $CRAM_DIR/$SM_TAG".cram",BAM_CRAM_VALIDATION_COMPARE,$START_CRAM_VALIDATION,$END_CRAM_VALIDATION \
>> $MAIN_DIR/COMPRESSOR.TEST.WALL.CLOCK.TIMES.csv