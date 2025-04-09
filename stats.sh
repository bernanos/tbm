#!/bin/bash

source ./project.sh
export FSLOUTPUTTYPE=NIFTI_GZ
export QUIT_EXT=NIFTI_GZ
set -eux
FSLQUEUE=global
WD=$PWD
PATH=/software/local/brain/TBM_scripts:$PATH

mapfile -t SCANS < subjects_stats.txt

mkdir -p $STATS_DIR/jacobians
mkdir -p $STATS_DIR/anat
mkdir -p $STATS_DIR/dwi

STATS_MASK=$STUDY_STATSMASK

function merge_and_setup() {
    DIR="$1"
    IN="$2"
    OUT="$3"
    shift 3
    SCANS=("$@")

    cd $REG_DIR/$DIR
    qi glm_setup --sort --groups=$WD/stats_groups.txt -v ${SCANS[@]/%/$IN} --design=$STATS_DIR/$DIR/${OUT}.design --out=$STATS_DIR/$DIR/${OUT}.nii.gz
    qi glm_contrasts $STATS_DIR/$DIR/${OUT}.nii.gz $STATS_DIR/$DIR/${OUT}.design $WD/contrasts.txt --out=$STATS_DIR/$DIR/${OUT}_ --verbose
    Text2Vest $STATS_DIR/$DIR/${OUT}.design $STATS_DIR/$DIR/${OUT}.mat
    cd $WD
}

# Use a global variable to hold the Job ID of the last randomise submission.
# Don't use the output of the function because that suppresses stdout
JOBID=""

function launch_randomise() {
    JOBID=$( randomise_parallel -i $STATS_DIR/$1/${2}.nii.gz \
                                -o $STATS_DIR/$1/r_${2} \
                                -m $STATS_MASK \
                                -d $STATS_DIR/$1/${2}.mat \
                                -t $STATS_DIR/ttest.con -f $STATS_DIR/ftest.fts \
                                -n 10000 -T -x --uncorrp | tail -n 1 )
}

function calc_brain_vols() {
    if [ -f $STATS_DIR/${STUDY_PREFIX}_brain_volumes.csv ]; then
        rm $STATS_DIR/${STUDY_PREFIX}_brain_volumes.csv
    fi

    if [ -f $STATS_DIR/${STUDY_PREFIX}_brainmask_volumes.csv ]; then
        rm $STATS_DIR/${STUDY_PREFIX}_brainmask_volumes.csv
    fi

    for SUBJ in ${SCANS[@]}; do
        V=$(ants ImageMath 3 dummy.nii.gz total \
            $REG_DIR/jacobians/${SUBJ}_composite_jacobian.nii.gz \
            $STUDY_MASK \
            | cut --delimiter=':' -f 3)
        echo $SUBJ,$V >> $STATS_DIR/${STUDY_PREFIX}_brain_volumes.csv

        V=$(fslstats $PROC_DIR/$SUBJ/anat/${SUBJ}_desc-aligned_artsmask.nii.gz -V | cut --delimiter=' ' -f 2)
        echo $SUBJ,$V >> $STATS_DIR/${STUDY_PREFIX}_brainmask_volumes.csv
    done
    rm dummy.nii.gz
}

function calc_roi_means() {
    LABELS="$STUDY_DCLABELS"
    MAPPING="$ATLAS_DIR/ABI_template/DCh_v2_mapping.csv"
    OUTPUT="$STATS_DIR/${STUDY_PREFIX}_DChv2_ROI_values.xlsx"

    fslmaths $LABELS \
        -mas $STUDY_STATSMASK \
        $LABELS

    SUBJ_LIST="subjects_stats.txt"
    GROUP_LIST="stats_groups.txt"

    # volumes
    INDIR="$REG_DIR/jacobians"
    POSTFIX="_composite_jacobian.nii.gz"
    calcROIstats.py -l $LABELS -m $MAPPING \
        -n $SUBJ_LIST -g $GROUP_LIST -i $INDIR \
        -f volume -p $POSTFIX -o $OUTPUT -t volume
    
    # T1
    INDIR="$REG_DIR/anat"
    POSTFIX="_T1map.nii.gz"
    calcROIstats.py -l $LABELS -m $MAPPING \
        -n $SUBJ_LIST -g $GROUP_LIST -i $INDIR \
        -f mean -p $POSTFIX -o $OUTPUT -t T1

    # dwi
    PARAMS='FA MD'
    INDIR="$REG_DIR/dwi"
    for PARAM in $PARAMS; do
        POSTFIX="_${PARAM}.nii.gz"
        calcROIstats.py -l $LABELS -m $MAPPING \
            -n $SUBJ_LIST -g $GROUP_LIST -i $INDIR \
            -f mean -p $POSTFIX -o $OUTPUT -t $PARAM
    done
}

######## do things ########

if [ ! -f $STATS_DIR/ttest.con ]; then
    Text2Vest $WD/contrasts.txt $STATS_DIR/ttest.con
fi
if [ ! -f $STATS_DIR/ftest.fts ]; then
    Text2Vest $WD/ftests.txt $STATS_DIR/ftest.fts
fi

merge_and_setup jacobians _composite_jacobian.nii.gz composite_volchange "${SCANS[@]}"
rm $STATS_DIR/jacobians/composite_volchange.nii.gz
merge_and_setup jacobians _composite_logjacobian.nii.gz composite_logjacobian "${SCANS[@]}"
rm $STATS_DIR/jacobians/composite_logjacobian_con1.nii.gz
launch_randomise jacobians composite_logjacobian

merge_and_setup jacobians _nonlin_jacobian.nii.gz nonlin_volchange "${SCANS[@]}"
rm $STATS_DIR/jacobians/nonlin_volchange.nii.gz
merge_and_setup jacobians _nonlin_logjacobian.nii.gz nonlin_logjacobian "${SCANS[@]}"
rm $STATS_DIR/jacobians/nonlin_logjacobian_con1.nii.gz
launch_randomise jacobians nonlin_logjacobian

merge_and_setup anat _desc-blurred_T1map.nii.gz T1map "${SCANS[@]}"
launch_randomise anat T1map

merge_and_setup dwi _desc-blurred_FA.nii.gz FA "${SCANS[@]}"
launch_randomise dwi FA

merge_and_setup dwi _desc-blurred_MD.nii.gz MD "${SCANS[@]}"
launch_randomise dwi MD

calc_brain_vols
calc_roi_means