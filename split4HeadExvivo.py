#!/software/local/brain/python/bin/python

from pathlib import Path
import argparse
import numpy as np
import nibabel as nib
from skimage import filters, measure, morphology

parser = argparse.ArgumentParser(
    description="Splits standard 4-mouse-head ex vivo image "
    "acquired at the BRAIN Centre, King's College London"
)
parser.add_argument(
    "input",
    help="file name of the image you want to split",
    type=Path
)
parser.add_argument(
    "mask",
    help="file name of the output or pre-existing binary mask image",
    type=Path
)
parser.add_argument(
    "label",
    help="file name of the output or pre-existing label image",
    type=Path
)
parser.add_argument(
    "-o", "--orient",
    help="subject orientation (in Paravision)",
    type=str,
    default='tailprone',
    choices=['tailprone', 'headprone']
)
parser.add_argument(
    "-v", "--vd_axis",
    help="which RAS axis is the ventrodorsal axis?",
    type=str,
    default='IS',
    choices=['AP', 'IS']
)
parser.add_argument(
    "-s", "--scaled",
    help="voxel dimensions have been scaled up 10x",
    action='store_true'
)
args = parser.parse_args()
fname = args.input.absolute()
maskname = args.mask.absolute()
labelname = args.label.absolute()
orientation = args.orient
scaled = args.scaled

### load image ###
img = nib.load(fname)
img_data = img.get_fdata()

if labelname.exists():
    final_labels = nib.load(labelname).get_fdata().astype(np.int16)
else:
    if not maskname.exists():
        ### mask image ###
        img1d = np.reshape(img_data, np.prod(img_data.shape))
        thresh = filters.threshold_otsu(img1d)
        if img_data.ndim > 3:
            img3d = img_data[:,:,:,0]
        else:
            img3d = img_data
        mask = morphology.remove_small_holes(img3d > thresh)

        mask_img = nib.Nifti1Image(mask.astype(np.int16), img.affine)
        nib.save(mask_img, maskname)
    else:
        mask = nib.load(maskname).get_fdata()
        mask = np.array(mask > 0)

    ### remove small objects ###
    voxvol = np.prod(img.header['pixdim'][1:4])
    if scaled:
        voxvol /= 1000
    mask = morphology.binary_opening(mask, morphology.ball(3))
    mask = morphology.remove_small_objects(mask, np.around(400 / voxvol), connectivity=3)

    ### mask to label image ###
    labels = measure.label( morphology.dilation(mask, morphology.ball(3)).astype(np.int16) )
    maskprops = measure.regionprops(labels)
    final_labels = np.zeros_like(labels)

    for count, maskprop in enumerate(maskprops):
        ### assign position numbers to labels ###
        centroid = nib.affines.apply_affine(img.affine, maskprop.centroid)
        C_LR = centroid[0]
        if args.vd_axis == 'AP':
            C_VD = -1 * centroid[1]
        elif args.vd_axis == 'IS':
            C_VD = centroid[2]

        if orientation == 'tailprone':
            if C_LR < 0 and C_VD > 0:
                idx = 1
            elif C_LR > 0 and C_VD > 0:
                idx = 2
            elif C_LR > 0 and C_VD < 0:
                idx = 3
            elif C_LR < 0 and C_VD < 0:
                idx = 4
        elif orientation == 'headprone':
            if C_LR < 0 and C_VD > 0:
                idx = 2
            elif C_LR > 0 and C_VD > 0:
                idx = 1
            elif C_LR > 0 and C_VD < 0:
                idx = 4
            elif C_LR < 0 and C_VD < 0:
                idx = 3
        
        final_labels[labels == count + 1] = idx
    
    label_img = nib.Nifti1Image(final_labels.astype(np.int16), img.affine)
    nib.save(label_img, labelname)

### split and save individual objects ###
maskprops = measure.regionprops(final_labels)
for maskprop in maskprops:
    bbox = maskprop.bbox
    out_img = img_data[bbox[0]:bbox[3], bbox[1]:bbox[4], bbox[2]:bbox[5]]
    out_hdr = img.header
    new_offsets = nib.affines.apply_affine(img.affine, bbox[0:3])
    out_hdr['qoffset_x'] = new_offsets[0]
    out_hdr['qoffset_y'] = new_offsets[1]
    out_hdr['qoffset_z'] = new_offsets[2]
    if out_hdr['sform_code'] > 0:
        out_hdr['srow_x'][3] = new_offsets[0]
        out_hdr['srow_y'][3] = new_offsets[1]
        out_hdr['srow_z'][3] = new_offsets[2]
    outname = Path(fname.parent,
                fname.name.replace(
                    ''.join(fname.suffixes),
                    f'_{maskprop.label}.nii.gz'
                    )
                )
    output = nib.Nifti1Image(out_img, affine=None, header=out_hdr)
    nib.save(output, outname)    