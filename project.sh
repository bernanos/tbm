#!/bin/bash

#########################################################
# copy this file to the local project scripts directory #
#########################################################

## This bit is to get the modules system working
source /software/system/modules/latest/init/bash
module use /software/system/modules/NaN/generic
module load nan
module load fsl
module load ants
module load afni
module load quit/3.3b
module load rats
module load mrtrix/.dev
module load brkraw/0.3.3b
export FSLOUTPUTTYPE=NIFTI_GZ
export QUIT_EXT=NIFTI_GZ
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=4
#
## Now define a lot of variables
#
export ORIENTATION='tailprone'     
export ROOT_DIR="$( cd ..; pwd )"
export STUDY_PREFIX="$( basename $ROOT_DIR )"
export SCRIPT_DIR="$PWD"
export PRC_SCRIPT_DIR="/software/local/brain/processing_scripts/Mouse_4Head_exvivo"
export TBM_SCRIPT_DIR="/software/local/brain/TBM_scripts"
export BRUKER_DIR="$ROOT_DIR/bruker"
export RAW_DIR="$ROOT_DIR/rawdata"
export PROC_DIR="$ROOT_DIR/derivatives"
export SPLIT_DIR="$ROOT_DIR/split"
export REG_DIR="$ROOT_DIR/registered"
export TEMPLATE_DIR="$ROOT_DIR/template"
export STATS_DIR="$ROOT_DIR/stats"
export FIG_DIR="$ROOT_DIR/figures"
#
export STUDY_TEMPLATE0="$TEMPLATE_DIR/${STUDY_PREFIX}_template0.nii.gz"
export STUDY_MASK="$TEMPLATE_DIR/${STUDY_PREFIX}_brainmask.nii.gz"
export STUDY_REGMASK="$TEMPLATE_DIR/${STUDY_PREFIX}_regmask.nii.gz"
export STUDY_DCLABELS="$TEMPLATE_DIR/${STUDY_PREFIX}_DChABI_labels.nii.gz"
export DTI_TEMPLATE0="$TEMPLATE_DIR/${STUDY_PREFIX}_DTItemplate0.nii.gz"
export DTI_TEMPLATE1="$TEMPLATE_DIR/${STUDY_PREFIX}_DTItemplate1.nii.gz"
export DTI_TEMPLATE2="$TEMPLATE_DIR/${STUDY_PREFIX}_DTItemplate2.nii.gz"
export DTI_MASK="$TEMPLATE_DIR/${STUDY_PREFIX}_brainmask_DTI.nii.gz"
export DTI_REGMASK="$TEMPLATE_DIR/${STUDY_PREFIX}_regmask_DTI.nii.gz"
export DTI_DCLABELS="$TEMPLATE_DIR/${STUDY_PREFIX}_DChABI_labels_DTI.nii.gz"
#
export MOUSEEX_DIR="/data/project/brain/PHYSICS/BRAIN_templates/MouseEx/RAS"
export MOUSEEX_TEMP_DIR="$MOUSEEX_DIR/template_masked"
export MOUSEEX_TEMPLATE_T2w="$MOUSEEX_DIR/MouseEx_T2w_template_RAS.nii.gz"
export MOUSEEX_TEMPLATE_FA="$MOUSEEX_DIR/MouseEx_FA_template_RAS.nii.gz"
export MOUSEEX_TEMPLATE_MD="$MOUSEEX_DIR/MouseEx_MD_template_RAS.nii.gz"
export MOUSEEX_MASK="$MOUSEEX_DIR/MouseEx_brainmask_RAS.nii.gz"
export ATLAS_DIR="/nan/ceph/network/local/generic/brain/atlas/mouse"
export DSURQE_DIR="$ATLAS_DIR/Toronto/DSURQE"
export DSURQE="$DSURQE_DIR/DSURQE_100micron_average.nii.gz"
export DSURQE_MASK="$DSURQE_DIR/DSURQE_100micron_mask_rotY90.nii.gz"
export DSURQE160="$DSURQE_DIR/DSURQE_160micron_average.nii.gz"