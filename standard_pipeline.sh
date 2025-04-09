#!/bin/bash

#########################################################
# copy this file to the local project scripts directory #
#########################################################

CODE_DIR=/software/local/brain
PATH=$CODE_DIR/slurm:$CODE_DIR/processing_scripts/Mouse_4Head_exvivo:$CODE_DIR/TBM_scripts:$PATH
source ./project.sh
set -eux
nb0=4

#############################
## run each block of code separately and in order
#############################

# split T2w images and rigidly align to DSURQE ('aligned') space
JID1=$( s_array_submit.sh -i scan_list.txt split_T2w.job )

# generate DTI maps, rigidly align to T2w image, split and apply above transforms to move to DSURQE ('aligned') space 
JID2=$( s_array_submit.sh -i scan_list.txt process_dti.job $nb0 )

# generate UNIT1 image and T1 map, rigidly align to T2w image, split and apply above transforms to move to DSURQE ('aligned') space 
JID3=$( s_array_submit.sh -i scan_list.txt process_MP2RAGE.job )

##### BEFORE CONTINUING #####
## check that heads have been properly split and aligned
## check DWI outputs: co-registration to T2w; DTI maps
## check MP2RAGE outputs: co-registration to T2w; UNIT1 and T1map
#############################

# create subject brain masks, both in native space and DSURQE ('aligned') space
JID4=$( s_array_submit.sh -i subjects.txt artsBrainExtraction_subject.job )

##### BEFORE CONTINUING #####
## check quality of subject brain masks
#############################

# create multi-modal study-specific templates
make_template.sh

# create template mask and a dilated version of the mask for registration ('regmask')
JID5=$( s_job_submit.sh artsBrainExtraction_template.job )

##### BEFORE CONTINUING #####
## check quality of template images and masks
#############################

# multi-model registration of unmasked subject images to unmasked study templates
# using 'regmasks' to restrict calculation of similarity metric to brain and immediate surroundings
JID6=$( s_array_submit.sh -i subjects.txt register2template.job )

# register masked T2w template to the Allen atlas template
JID7=$( s_job_submit.sh registerTemplate2ABI.job )

##### BEFORE CONTINUING #####
## check registrations between subjects and templates
## check registrations between templates and atlas
#############################
# IF NECESSARY - MODIFY TEMPLATE BRAIN MASK TO CREATE STATS MASK
# e.g. erode with ants ImageMath
# ELSE - UNCOMMENT AND EXECUTE THE FOLLOWING LINE
# cp $STUDY_MASK $STUDY_STATSMASK
#############################

# create jacobian determinant maps
TFM_DIR="$REG_DIR/anat"
TFMS="-t ${TFM_DIR}/"'${SUBJ}'"_totemplate_1Warp.nii.gz -t ${TFM_DIR}/"'${SUBJ}'"_totemplate_0GenericAffine.mat"
JID8=$( s_array_submit.sh -i subjects.txt registerWriteJacobians.job "$STUDY_TEMPLATE0" "composite" "$TFMS" )
TFM="-t ${TFM_DIR}/"'${SUBJ}'"_totemplate_1Warp.nii.gz"
JID9=$( s_array_submit.sh -i subjects.txt registerWriteJacobians.job "$STUDY_TEMPLATE0" "nonlin" "$TFM" )

##### BEFORE CONTINUING #####
## check jacobian images
#############################

# perform voxel-wise stats using FSL randomise and calculate ROI volumes and means
# subjects to include in stats are listed in subjects_stats.txt
# corresponding stats groups are listed in stats_groups.txt
# contrasts and f-tests to run are in contrasts.txt and ftests.txt
stats.sh

##### BEFORE CONTINUING #####
## check stats images
#############################

# do ROI-wise group comparisons and get ROI-wise breakdown of voxel-wise results
statsROI.sh