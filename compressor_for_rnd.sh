#! /bin/bash

module load sge

DIR_TO_PARSE=$1
REF_GENOME=$2

SCRIPT_REPO=/isilon/sequencing/VITO/GIT_REPO/Archive_Compressor_2016/COMPRESSION_SCRIPTS
DEFAULT_REF_GENOME=/isilon/sequencing/GATK_resource_bundle/1.5/b37/human_g1k_v37_decoy.fasta

if [[ ! $REF_GENOME ]]
	then
	REF_GENOME=$DEFAULT_REF_GENOME
fi

####Uses bgzip to compress vcf file and tabix to index.  Also, creates md5 values for both####
COMPRESS_AND_INDEX_VCF(){

	echo qsub -N COMPRESS_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/COMPRESS_AND_INDEX_VCF_$BASENAME.log $SCRIPT_REPO/compress_and_tabix_vcf.sh $FILE $DIR_TO_PARSE
}

####Uses samtools-1.3.1 to convert bam to cram and index and remove excess tags####  
BAM_TO_CRAM_CONVERSION_RND(){
	#Remove Tags + 5-bin Quality Score (RND Projects)
	 echo qsub -N BAM_TO_CRAM_CONVERSION_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_TO_CRAM_$BASENAME.log $SCRIPT_REPO/bam_to_cram_remove_tags_rnd.sh $FILE $DIR_TO_PARSE $REF_GENOME
}

####Uses samtools-1.3.1 to convert bam to cram and index and remove excess tags####  
BAM_TO_CRAM_CONVERSION_PRODUCTION(){
	#Remove Tags + 5-bin Quality Score (RND Projects)
	 echo qsub -N BAM_TO_CRAM_CONVERSION_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_TO_CRAM_$BASENAME.log $SCRIPT_REPO/bam_to_cram_remove_tags.sh $FILE $DIR_TO_PARSE $REF_GENOME
}

####Uses ValidateSam to report any errors found within the original BAM file####
BAM_VALIDATOR(){
	echo qsub -N BAM_VALIDATOR_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/BAM_VALIDATOR_$BASENAME.log $SCRIPT_REPO/bam_validation.sh $FILE $DIR_TO_PARSE	
}

####Uses ValidateSam to report any errors found within the cram files####
CRAM_VALIDATOR(){
	echo qsub -N CRAM_VALIDATOR_$UNIQUE_ID -hold_jid BAM_TO_CRAM_CONVERSION_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/CRAM_VALIDATOR_$BASENAME.log $SCRIPT_REPO/cram_validation.sh $FILE $DIR_TO_PARSE $REF_GENOME
}

####Parses through all CRAM_VALIDATOR files to determine if any errors/potentially corrupted cram files were created and creates a list in the top directory
VALIDATOR_COMPARER(){
	echo qsub -N VALIDATOR_COMPARE_$PROJECT_NAME -hold_jid "BAM_VALIDATOR_"$UNIQUE_ID",CRAM_VALIDATOR_"$UNIQUE_ID -o $DIR_TO_PARSE/LOGS/BAM_CRAM_VALIDATE_COMPARE.log $SCRIPT_REPO/bam_cram_validate_compare.sh $FILE $DIR_TO_PARSE
}

####Zips and md5s text and csv files####
ZIP_TEXT_AND_CSV_FILE(){
	echo qsub -N COMPRESS_$UNIQUE_ID -j y -o $DIR_TO_PARSE/LOGS/ZIP_FILE_$BASENAME.log $SCRIPT_REPO/zip_file.sh $FILE $DIR_TO_PARSE
}
	
####Compares MD5 between the original file and the zipped file (using zcat) to validate that the file was compressed successfully####
MD5_CHECK(){
	echo qsub -N MD5_CHECK_$UNIQUE_ID -hold_jid COMPRESS_$UNIQUE_ID  -j y -o $DIR_TO_PARSE/LOGS/MD5_CHECK$BASENAME.log $SCRIPT_REPO/md5_check.sh $FILE $DIR_TO_PARSE
}

PROJECT_NAME=$(basename $DIR_TO_PARSE)

mkdir -p $DIR_TO_PARSE/MD5_REPORTS/
mkdir -p $DIR_TO_PARSE/LOGS
mkdir -p $DIR_TO_PARSE/TEMP
mkdir -p $DIR_TO_PARSE/CRAM_CONVERSION_VALIDATION/
mkdir -p $DIR_TO_PARSE/BAM_CONVERSION_VALIDATION/

echo -e SAMPLE\\tCRAM_CONVERSION_SUCCESS\\tCRAM_ONLY_ERRORS\\tNUMBER_OF_CRAM_ONLY_ERRORS >| $DIR_TO_PARSE/cram_conversion_validation.list

# Pass variable (vcf/txt/cram) file path to function and call $FILE within function#
for FILE in $(find $DIR_TO_PARSE | egrep 'vcf$|csv$|txt$|bam$')
do
BASENAME=$(basename $FILE)
UNIQUE_ID=$(echo $BASENAME | sed 's/@/_/g') # If there is an @ in the qsub or holdId name it breaks
if [[ $FILE == *".vcf" ]]
then
	COMPRESS_AND_INDEX_VCF
	MD5_CHECK

elif [[ $FILE == *".bam" ]]; then
#	case $FILE in *02_CIDR_RND*)
	BAM_TO_CRAM_CONVERSION_RND
	BAM_VALIDATOR
	CRAM_VALIDATOR
	VALIDATOR_COMPARER
#	BUILD_VALIDATOR_COMPARER_HOLD_ID_JOB_LIST
#	;;
#	*00_CIDR_PRODUCTION*)
#	BAM_TO_CRAM_CONVERSION_PRODUCTION
#	BAM_VALIDATOR
#	CRAM_VALIDATOR
#	BUILD_VALIDATOR_COMPARER_HOLD_ID_JOB_LIST
#	;;
#	esac

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



