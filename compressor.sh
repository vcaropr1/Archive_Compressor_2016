#! /bin/bash

module load sge

DIR_TO_PARSE=$1
SCRIPT_REPO=/isilon/sequencing/VITO/GIT_REPO/Archive_Compressor_2016/COMPRESSION_SCRIPTS

####Uses bgzip to compress vcf file and tabix to index.  Also, creates md5 values for both####
COMPRESS_AND_INDEX_VCF(){

	echo qsub -N COMPRESS_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/COMPRESS_AND_INDEX_VCF_$BASENAME.log $SCRIPT_REPO/compress_and_tabix_vcf.sh $FILE $DIR_TO_PARSE
}

####Uses samtools-1.3.1 to convert bam to cram and index and remove excess tags####  
BAM_TO_CRAM_CONVERSION(){
	# Remove Tags
	echo qsub -N BAM_TO_CRAM_CONVERSION_$BASENAME -j y -o /isilon/sequencing/VITO/Junk_2/BAM_TO_CRAM_$BASENAME.log $SCRIPT_REPO/bam_to_cram_remove_tags.sh $FILE

	# Remove Tags + 8-bin Quality Score (RND Projects)
	# echo qsub -N BAM_TO_CRAM_CONVERSION_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_TO_CRAM_$BASENAME.log $SCRIPT_REPO/bam_to_cram_remove_tags_rnd.sh $FILE $DIR_TO_PARSE
}

####Uses ValidateSam to report any errors found within the original BAM file####
BAM_VALIDATOR(){
	echo qsub -N BAM_VALIDATOR_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_VALIDATOR_$BASENAME.log $SCRIPT_REPO/bam_validation.sh $FILE $DIR_TO_PARSE	
}

####Uses ValidateSam to report any errors found within the cram files####
CRAM_VALIDATOR(){
	echo qsub -N CRAM_VALIDATOR_$UNIQUE_ID -hold_jid BAM_TO_CRAM_CONVERSION_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/CRAM_VALIDATOR_$BASENAME.log $SCRIPT_REPO/cram_validation.sh $FILE $DIR_TO_PARSE
}

# NEED TO WORK ON ....Common ERROR:INVALID_TAG_NM in Bam validations.
# VALIDATOR_COMPARER(){
#	echo qsub -N VALIDATOR_COMPARE_$FILE -hold_jid "BAM_VALIDATOR_"$FILE","CRAM_VALIDATOR_$FILE -o /isilon/sequencing/VITO/Junk_2/BAM_CRAM_VALIDATE_COMPARE.log $SCRIPT_REPO/bam_cram_validate_compare.sh $DIR_TO_PARSE
#	echo $SCRIPT_REPO/bam_cram_validate_compare.sh $DIR_TO_PARSE
#	$SCRIPT_REPO/bam_cram_validate_compare.sh $DIR_TO_PARSE
# }

####Zips and md5s text and csv files####
ZIP_TEXT_AND_CSV_FILE(){
	echo qsub -N COMPRESS_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/ZIP_FILE_$BASENAME.log $SCRIPT_REPO/zip_file.sh $FILE $DIR_TO_PARSE
}
	
####Compares MD5 between the original file and the zipped file (using zcat) to validate that the file was compressed successfully####
MD5_CHECK(){
	echo qsub -N MD5_CHECK_$UNIQUE_ID -hold_jid COMPRESS_$UNIQUE_ID  -j y -o $DIR_TO_PARSE/LOGS/MD5_CHECK$BASENAME.log $SCRIPT_REPO/md5_check.sh $FILE $DIR_TO_PARSE
}

mkdir -p $DIR_TO_PARSE/MD5_REPORTS/
mkdir -p $DIR_TO_PARSE/LOGS
mkdir -p $DIR_TO_PARSE/TEMP
mkdir -p $DIR_TO_PARSE/CRAM_CONVERSION_VALIDATION/
mkdir -p $DIR_TO_PARSE/BAM_CONVERSION_VALIDATION/

# Pass variable (vcf/txt/cram) file path to function and call $FILE within function#
for FILE in $(du -a $DIR_TO_PARSE | egrep 'vcf$|csv$|txt$|bam$' | awk '{FS="\t"} {print $2}')
do
BASENAME=$(basename $FILE)
UNIQUE_ID=$(echo $BASENAME | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks
if [[ $FILE == *".vcf" ]]
then
	COMPRESS_AND_INDEX_VCF
	MD5_CHECK

elif [[ $FILE == *".bam" ]]; then
	BAM_TO_CRAM_CONVERSION
	BAM_VALIDATOR
	CRAM_VALIDATOR
#	VALIDATOR_COMPARER


elif [[ $FILE == *".txt" ]]; then
	ZIP_TEXT_AND_CSV_FILE
	MD5_CHECK
	

elif [[ $FILE == *".csv" ]]; then
	ZIP_TEXT_AND_CSV_FILE
	MD5_CHECK

else 
	echo $FILE_NAME not being compressed >> $DIR_TO_PARSE/compression_jobs.list

fi
done
