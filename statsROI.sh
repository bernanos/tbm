#!/bin/bash

source ./project.sh
export FSLOUTPUTTYPE=NIFTI_GZ
export QUIT_EXT=NIFTI_GZ
set -eux
FSLQUEUE=global
WD=$PWD
PATH=/software/local/brain/TBM_scripts:$PATH

LABELS="$STUDY_DCLABELS"
MAPPING="$ATLAS_DIR/ABI_template/DCh_v2_mapping.csv"
OUTPUT="$STATS_DIR/${STUDY_PREFIX}_DChv2_ROI_values.xlsx"

function do_ROI_stats() {
    mkdir -p $STATS_DIR/roi
    makeROIstatsMaps.py -l $LABELS -m $MAPPING \
        -d $OUTPUT -c $SCRIPT_DIR/contrasts.txt -o $STATS_DIR/roi \
        -s $STATS_DIR/${STUDY_PREFIX}_DChv2_ROI_stats.xlsx
}

function pval_breakdown() {
    MAPS=("composite_logjacobian" "nonlin_logjacobian" "T1map" "FA" "MD")
    PARS=("Absolute Volume" "Relative Volume" "T1" "FA" "MD")
    DIRS=("jacobians" "jacobians" "anat" "dwi" "dwi")
    length_maps=${#MAPS[@]}
    length_pars=${#PARS[@]}
    if [ $length_maps != $length_pars ]; then
        echo "array lengths are not equal!"
        exit 1
    fi
    for (( i=0; i<length_maps; i++ )); do
        ROIpvalBreakdown.py -l $LABELS -m $MAPPING \
            -p $STATS_DIR/${DIRS[$i]}/r_${MAPS[$i]}_tfce_corrp_fstat1.nii.gz -i \
            -o $STATS_DIR/${STUDY_PREFIX}_DChv2_ROI_pval_breakdown.xlsx -t "${PARS[$i]}"
    done

    plotROIpvalBreakdown.py \
        -i $STATS_DIR/${STUDY_PREFIX}_DChv2_ROI_pval_breakdown.xlsx \
        -o $FIG_DIR/${STUDY_PREFIX}_pctSigVox
}

######## do things ########

pval_breakdown
do_ROI_stats
