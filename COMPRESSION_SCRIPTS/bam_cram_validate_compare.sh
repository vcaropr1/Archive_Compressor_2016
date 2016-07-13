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
VALIDATION_DIR=$MAIN_DIR/TEMP/CRAM_CONVERSION_VALIDATION/
# BAM_VALDIATION_DIR=$MAIN_DIR/CRAM_CONVERSION_VALIDATION/BAM_VALIDATION/
# CRAM_VALDIATION_DIR=$MAIN_DIR/CRAM_CONVERSION_VALIDATION/CRAM_VALIDATION/
# VALIDATION_DIR=$MAIN_DIR/CRAM_CONVERSION_VALIDATION/

PARSE_ERROR_LOG(){
  ERROR_LIST=`grep "^ERROR" $i | sed 's/ /\t/g' |  awk '{OFS="\t"} {split($1,ERROR,":"); print "'$FILE'",ERROR[2]}'`

 # for i in /isilon/sequencing/VITO/Seq_Proj/Amos_BaitTest_CustomOnly/TEMP/CRAM_CONVERSION_VALIDATION/*_orig_bam ; do grep "^ERROR" $i  |  awk '{OFS="\t"} {split($1,ERROR,":"); print "'$(basename $i _orig_bam)'",ERROR[2]}' ; done
 # ERROR_LIST=`grep "^ERROR" $i | awk '{OFS="\t"} {print "'$FILE'",$0}'`
 # ERROR_LIST=`grep "^ERROR:" $i |awk '{split($1,ERROR,":")}{print ERROR[2]}' | datamash -s -g 1 transpose | sed 's/\t/,/g'`

}

touch $VALIDATION_DIR/cram_validation_file.txt
touch $VALIDATION_DIR/bam_validation_file.txt
# touch $VALIDATION_DIR/cram_to_bam_validation_file.txt
touch $VALIDATION_DIR/joined_cram_validation_file.txt
echo -e FILE\\tBAM_ERRORS\\tBAM_ERROR_COUNT\\tCRAM_ERRORS\\tCRAM_ERROR_COUNT\\tCONVERSION_SUCCESS >| $VALIDATION_DIR/joined_cram_validation_file.txt
# touch $VALIDATION_DIR/orig_bam_validation_file.txt
# touch $VALIDATION_DIR/cram_validation_file.txt
# touch $VALIDATION_DIR/cram_to_bam_validation_file.txt


# Merging all the Validate Files into one and check
	# Step to merge all Bam

# Loop will check all original bam validations to see if no errors or if errors were found

for i in $VALIDATION_DIR/*_orig_bam;
do
	FILE=$(basename $i _orig_bam)
if grep -q "No errors found" $i; then
	echo blah
	echo -e $FILE\\tNONE >> $VALIDATION_DIR/bam_validation_file.txt
else
	echo $FILE origianl bam is invalid
#	PARSE_ERROR_LOG
#	echo $ERROR_LIST >> $VALIDATION_DIR/bam_validation_file.txt
grep "^ERROR" $i | sed 's/ /\t/g' |  awk '{OFS="\t"} {split($1,ERROR,":"); print "'$FILE'",ERROR[2]}' >> $VALIDATION_DIR/bam_validation_file.txt
fi
done


# for i in $VALIDATION_DIR/*_orig_bam; \
# do cat $i \
# | grep -v "No errors found" \
# | sed 's/:/ /g' \
# | grep "ERROR" \
# | awk 'BEGIN{OFS="\t"} {print ("'$(basename $i | sed 's/_.*//g')'",$2,$3)}' >> $VALIDATION_DIR/orig_bam_validation_file.txt; \
# done

# for i in $BAM_VAL_DIR/*; do cat $i | grep -v "ERROR:INVALID_TAG_NM" | sed 's/:/ /g' | grep "ERROR" | awk 'BEGIN{OFS="\t"} {print ("'$(basename $i)'",$0)}' ;done
for i in $VALIDATION_DIR/*_cram;
do
	FILE=$(basename $i _cram)
if grep -q "No errors found" $i; then
	echo blah
	echo -e $FILE\\tNONE >> $VALIDATION_DIR/cram_validation_file.txt
else
	echo $FILE cram is invalid
	grep "^ERROR" $i | sed 's/ /\t/g' |  awk '{OFS="\t"} {split($1,ERROR,":"); print "'$FILE'",ERROR[2]}' >> $VALIDATION_DIR/cram_validation_file.txt
fi
done

	# Step to merge all Cram
# for i in $VALIDATION_DIR/*_cram; \
# do cat $i \
# | grep -v "No errors found" \
# | sed 's/:/ /g' \
# | grep "ERROR" \
# | awk 'BEGIN{OFS="\t"} {print ("'$(basename $i)'",$2,$3)}' >> $VALIDATION_DIR/cram_validation_file.txt; \
# done
# 

# for i in $VALIDATION_DIR/*_cram_to_bam;
# do
# 	FILE=$(basename $i _cram_to_bam)
# if grep -q "No errors found" $i; then
# 	echo blah
# 	echo -e $i\\tBAM_FROM_CRAM\\tPASS\\t$NONE >> $VALIDATION_DIR/cram_validation_file.txt
# else
# 	echo $FILE bam from cram indexing is invalid
# 	PARSE_ERROR_LOG
# 	echo -e $i\\tBAM_FROM_CRAM\\tFAILED\\t$ERROR_LIST >> $VALIDATION_DIR/cram_validation_file.txt
# fi
# done
# # Step to merge all Cram_to_Bam
# for i in $VALIDATION_DIR/*_cram_to_bam; \
# do cat $i \
# | grep -v "No errors found" \
# | sed 's/:/ /g' \
# | grep "ERROR" \
# | awk 'BEGIN{OFS="\t"} {print ("'$(basename $i)'",$2,$3)}' >> $VALIDATION_DIR/cram_to_bam_validation_file.txt; \
# done
# 
# 
# # join bam and cram merged files based on SM_TAG and add header
# join -j 1 $VALIDATION_DIR/bam_validation_file.txt $VALIDATION_DIR/cram_validation_file.txt $VALIDATION_DIR/cram_to_bam_validation_file.txt \
# | awk 'BEGIN{OFS="\t";print "SM_TAG","BAM_ERROR_TYPE","BAM_ERROR_TYPE_COUNT","CRAM_ERROR_TYPE","CRAM_ERROR_TYPE_COUNT"}{print $0}' \
# > $VALIDATION_DIR/"bam_and_cram_validation_compare_file.txt"
# 
# awk ' BEGIN{OFS="\t"} NR>1{if($2!=$4) print($1,"Error"); else print($1,"Conversion Successful")}' $VALIDATION_DIR/"bam_and_cram_validation_compare_file.txt" >| $VALIDATION_DIR/"conversion_success_validation.txt"
