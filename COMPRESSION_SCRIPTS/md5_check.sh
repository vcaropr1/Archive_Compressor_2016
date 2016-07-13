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

set

FILE=$1
DIR_TO_PARSE=$2
ORIGINAL_MD5=$(md5sum $FILE | awk '{print $1}')
ZIPPED_MD5=$(zcat $FILE".gz" | md5sum | awk '{print $1}')

if [[ $ORIGINAL_MD5 = $ZIPPED_MD5 ]]; then
	echo $FILE compressed successfully >> $DIR_TO_PARSE/compression_jobs.list
#	rm -f $FILE
	mv $FILE $DIR_TO_PARSE/TEMP/
else
	echo $FILE did not compress successfully >> $DIR_TO_PARSE/compression_jobs.list
fi

