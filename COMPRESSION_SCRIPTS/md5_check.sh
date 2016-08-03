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

DIR_TO_PARSE=$1

MD5_COMPARISON (){

ORIGINAL_MD5=$(md5sum $FILE | awk '{print $1}')
	ZIPPED_MD5=$(zcat $FILE".gz" | md5sum | awk '{print $1}')

	echo $(zcat $FILE".gz" | md5sum | awk '{print $1}') $FILE".gz" >> $DIR_TO_PARSE/MD5_REPORTS/compressed_md5list.list
	echo $(md5sum $FILE | awk '{print $1}') $FILE >> $DIR_TO_PARSE/MD5_REPORTS/original_md5list.list

		if [[ $ORIGINAL_MD5 = $ZIPPED_MD5 ]]; then
		echo $FILE compressed successfully >> $DIR_TO_PARSE/compression_jobs.list
 		rm -rvf $FILE
		else
			echo $FILE did not compress successfully >> $DIR_TO_PARSE/compression_jobs.list
			mail -s "$FILE Failed compression" vcaropr1@jhmi.edu < $DIR_TO_PARSE/compression_jobs.list
		fi

}


for FILE in $(find $DIR_TO_PARSE | egrep 'vcf$|csv$|txt$|log$|intervals$' | grep -v MD5_CHECK.log)
do
	if [[ -e $FILE".gz" ]]
	then
		MD5_COMPARISON
	else
		gzip -f -c $FILE >| $FILE.gz
		MD5_COMPARISON 
	fi
done

gzip -f $DIR_TO_PARSE/LOGS/MD5_CHECK.log