# ThT-Antibody_Colocalisation
Process ONI Nanoimager images and determine the correlation between ThT and antibody signal

How to use: 

1. Run 1_ONI_FilePreProcessing.ijm in Fiji, this allows raw Nanoimager channels to be separated, calibrated and directly associated with the metadata

2. If using a beamsplitter, run 2_SplitChannel_Registration.py to auto-align your data using groundtruth Tetraspeck bead data 

3. To register images captured following stage return to a given FOV (i.e. pre/post ThT application), run 3_Manual_Landmark_Registration.ijm

4. Run 4_ColocalisationAnalysis.ijm, which uses the ComDet plugin to detect channel particle numbers and output their colocalisation

5. Concatanate the CSVs output in the previous step into a single data file using 5_ProcessCSVs.py
