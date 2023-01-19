#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Purpose: C
"""


# USER INPUTS ####################

# Provide file path to analysed data:
path = r'/Volumes/RSaleeb_2TB/2022-12-21_ExenitideSamples_SiMPull/Aligned/Analysis/'


# MAIN CODE ######################

# Import required libraries
import csv
import pandas as pd
import os


# Initialise empty dataframes to contain compiled data
dataSummary = pd.DataFrame()

# Iterate over folders and files
for folder in os.listdir(path):

    if not folder == '.DS_Store':
        for file in os.listdir(path + folder):

            # Identify data associated with a single FOV
            if file.endswith('particle_analysis.csv') and not file.startswith('._'):
                print(folder + file)

                # Initialise CSV reader
                with open(path + folder + '/' + file) as f:
                    freader = csv.reader(f)


                    # Check the number of rows in the CSV
                    f_row_count = sum(1 for row in freader)

                    
                    # Reset the CSV reader to read the first row after the column headers
                    f.seek(0)
                    next(freader)

                    # Skip the FOV if the CSV row count does not equal 2 (indicates erroneous data)
                    if (f_row_count == 2):
                        for row in freader:
                            
                            # Check if the FOV produced no detections (5 column data) or at least one detection (7 column data)
                            if len(row) == 7 or len(row) == 5:
                                
                                # Read in the CSV file and rename the columns
                                if len(row) == 7:
                                    appendRow = pd.DataFrame(row).transpose()
                                    appendRow.columns=['Slice', 'Frame', 'AF647_detections', 'AF488_detections', 'Coincident_detections', 'Percent_AF647_coincident', 'Percent_AF488_coincident']

                                
                                elif len(row) == 5:
                                    appendRow = pd.DataFrame(columns = ['Slice', 'Frame', 'AF647_detections', 'AF488_detections', 'Coincident_detections', 'Percent_AF647_coincident', 'Percent_AF488_coincident'])
                                    appendRow.loc[0] = [1, 1, 0, 0, 0, 0, 0]
                                    
                                # Add and populate file/folder name columns
                                appendRow.insert(0, 'File', [file])
                                appendRow.insert(0, 'Folder', [folder])

                                # Add the row on to the bottom of the summary data table
                                dataSummary = pd.concat((dataSummary, appendRow), axis = 0)
                           
                            else:
                                print("ERROR - Incorrect table size, data excluded.")
                                

# Rename column headers in data summary
dataSummary.columns=['Folder', 'File', 'Slice', 'Frame', 'AF647_detections', 'AF488_detections', 'Coincident_detections', 'Percent_AF647_coincident', 'Percent_AF488_coincident']

# Convert datatype of numberic columns to float
dataSummary[['AF647_detections', 'AF488_detections', 'Coincident_detections', 'Percent_AF647_coincident', 'Percent_AF488_coincident']] = dataSummary[['AF647_detections', 'AF488_detections', 'Coincident_detections', 'Percent_AF647_coincident', 'Percent_AF488_coincident']].apply(pd.to_numeric, errors='coerce')

# Save dataframes as CSVs
dataSummary.to_csv(path + 'All_Data.csv', index=False)
