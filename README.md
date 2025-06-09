# NIRAF_Data_Analysis

NIRAF Data Analysis
Created by: Jenna Grieshop
Date created: 5/16/2023

Purpose: Interactive script to calculate average intensity at specific
samping points (spacing) with specific bin (window) sizes from the fovea.

Requirements: 
  - LUT file containing subject ID, nominal scale in umpp, gray
    level offset from device (different for each subject), axial length, 
    eye (OS/OD).
  - Input rgb or grayscale tif files containing the subject ID and eye in the name.

Inputs: Script prompts user to select LUT file, then prompts to select
folder containing data files, then prompts for spacing and window sizes.
User is then asked to select the fovea for each image.

An image contrast tool will populate moments after the image appears.
If interacting between the contrast tool and the image too quickly, warnings may appear.
These do not interfere with the functionality of the script.

The script uses the foveal coordinates to create a 5px wide region across
the image horizontally through the fovea. It then averages the 5 pixels 
for the average intensity at each pixel location across the image. Then 
it changes the orientation of all the left eye images to match the right
eye and it begins averaging the values in each window for each sampling 
point location.

Outputs: A csv file for each subject (containing bin center from fovea in
mm (T(-) N(+)), average pixel intensity, and items in bin (# of pixel 
locations contributing to the average)) will be generated in the location
of the LUT file, another csv containing the fovea x and y coordinates for 
all subjects is generated in the same location.

Note: If the window size will overlap with the selections made
it will give a warning and another chance to set the sampling and window
size.

# NIRAF_Data_Compilation

NIRAF Data Compilation
Created by: Jenna Grieshop
Date created: 4/30/2024

Purpose: Script to analyze results from the NIRAF_Data_Extraction.m script
This script organizes data from all subjects into two csv files. 

Inputs: Folder with subjects' NIRAF Data Extraction results only NOT
including the summary results that are also created by the previous
script. Do not have any other files in the folder before running.

Outputs: saves to the input folder - NOTE: if rerunning please remove
these files before hand.

NIRAF_Data_Compilation_ALL_Data_date:
Has a summary of all the data - each location, if the subjects' data
contributed to the location (1 - yes, 0 - no), average intensity at that
location, and the number of subjects' data that is included in the
average.

NIRAF_Data_Compilation_COMMON_Data_date:
Lists all common locations across all subjects. Each common location is
listed for each subject, and the average value for that subject and
location is also listed. This is mainly created for statistical purposes.


