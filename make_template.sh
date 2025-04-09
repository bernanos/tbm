#!/bin/bash

source ./project.sh
set -eux
WD=$(pwd)

mkdir -p $TEMPLATE_DIR
ANTSDIR="/nan/ceph/network/local/generic/brain/processing_scripts"
TEMP_SCANS=$TEMPLATE_DIR/MMtemplate_scans.csv

function create_list() {
	SUBJECTS=$( cat $SCRIPT_DIR/subjects_template.txt )

	for SUBJ in $SUBJECTS; do
		FILE1="$PROC_DIR/$SUBJ/anat/${SUBJ}_desc-aligned_T2w.nii.gz"
		FILE2="$PROC_DIR/$SUBJ/anat/${SUBJ}_desc-aligned_UNIT1.nii.gz"
		FILE3="$PROC_DIR/$SUBJ/dwi/${SUBJ}_dti_desc-aligned_FA.nii.gz"
		FILE4="$PROC_DIR/$SUBJ/dwi/${SUBJ}_dti_desc-aligned_MD.nii.gz"

		printf "$FILE1,$FILE2,$FILE3,$FILE4\n" >> $TEMP_SCANS
	done
}

if [ -f $TEMP_SCANS ]; then
	rm $TEMP_SCANS
fi
create_list

cd $TEMPLATE_DIR
echo "Starting template construction"
ants $ANTSDIR/my_antsMultivariateTemplateConstruction2.sh \
	-d 3 -a 2 -c 5 -u 72:00:00 -v 5gb -i 3 -k 4 \
	-p "source $SCRIPT_DIR/project.sh" \
	-f 8x4x2x1 -s 3x2x1x0vox -q 100x75x50x25 \
	-y 0 -r 1 -n 0 -o ${STUDY_PREFIX}_ \
	$TEMP_SCANS
cd $WD