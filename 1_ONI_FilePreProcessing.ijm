// PRE-PROCESS IMAGES ACQUIRED ON THE ONI NANOIMAGER /////////////////////////////////////////////////////////////////////////////////////
// Written by RSaleeb, last edit 09-Apr-2021

// Parses ome-xml metadata description and adds tags to tiff header for future referencing via 'image info' panel
// Separates channels, calibrates scale and saves as .tiff in specified location, if file is >4GB, seperates into substacks for saving


// User Inputs ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

leftCh = true; // indicate if data captured on left chip (i.e. 400-630 nm emission)
leftChSuffix = "AF488"; // Suffix to be added to saved file name
rightCh = true; // indicate if data captured on right chip (i.e. 640 nm plus emission)
rightChSuffix = "AF647"; // Suffix to be added to saved file name

leftChStart = 21; 
leftChEnd = 40;
rightChStart = 1;
rightChEnd = 20;

setBatchMode("hide");

// Main script ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

rawDir = getDir("Data directory");
saveDir = getDir("Save directory");

expList = getFileList(rawDir); // List of experiment folders

for (i = 0; i < lengthOf(expList); i++) {
	File.makeDirectory(saveDir + "/" + expList[i]);
	posList = getFileList(rawDir + "/" + expList[i]); // List of position folders
	
	for (j = 0; j < lengthOf(posList); j++) {
		fileList = getFileList(rawDir + "/" + expList[i] + "/" + posList[j]); // List of files in position folder

		for (k = 0; k < lengthOf(fileList); k++) {
			if (endsWith(fileList[k], "_acq.nim")) {				
				// Load metadata
				metadataFileName =  fileList[k];
				filestring = rawDir + "/" + expList[i] + "/" + posList[j] + "/" + metadataFileName;
				
				metadata = File.openAsString(filestring);
				
				// Parse general image metadata into variables
				exposure = parseInt(substring(metadata, indexOf(metadata, "Exposure_ms") + 13, indexOf(metadata, "FormatVersion") - 2));
				totalFrames = substring(metadata, indexOf(metadata, "Frames") + 8, indexOf(metadata, "FramesPerSecond") - 2);
				framesPerSecond = parseInt(substring(metadata, indexOf(metadata, "FramesPerSecond") + 17, indexOf(metadata, "InstrumentSerial") - 2));
				instrumentSerial = substring(metadata, indexOf(metadata, "InstrumentSerial") + 18, indexOf(metadata, "LaserProgramLength") - 2);
				objectiveNA = substring(metadata, indexOf(metadata, "Objective_NA") + 14, indexOf(metadata, "PixelSize_um") - 2);
				pixelSize = substring(metadata, indexOf(metadata, "PixelSize_um") + 14, indexOf(metadata, "ROI") - 2);
				softwareVersion = substring(metadata, indexOf(metadata, "SoftwareVersion") + 18, indexOf(metadata, "-") - 1);
				user = substring(metadata, indexOf(metadata, "UserName") + 10, indexOf(metadata, "laserProgram") - 2);
				tirfAngle = substring(metadata, indexOf(metadata, "IlluminationAngle_deg") + 23, indexOf(metadata, "IlluminationAngle_deg") + 27);
				stageXYZ = substring(metadata, indexOf(metadata, "StagePos_um") + 14, indexOf(metadata, "TemperatureC") - 3);
				temperature = substring(metadata, indexOf(metadata, "TemperatureC") + 14, indexOf(metadata, "TransilluminationPowerPercent") - 2);
				tlPercentage = substring(metadata, indexOf(metadata, "TransilluminationPowerPercent") + 31, indexOf(metadata, "temperatureTimestamp_us") - 2);
				focusOffset = substring(metadata, indexOf(metadata, "zFocusOffset_um") + 17, indexOf(metadata, "zFocusOffset_um") + 20);
			}
		}

		for (k = 0; k < lengthOf(fileList); k++) {
			
			if (endsWith(fileList[k], "posZ0.tif")) {
				title = substring(fileList[k], 0, indexOf(fileList[k], "."));
				if (endsWith(fileList[k], "locImage.tif")) {
					break;
				}
				print("Processing: " + title);
				
				// Process left channel
				if (leftCh == true) {
		
					run("Bio-Formats Importer", "open=[" + rawDir + "/" + expList[i] + "/" + posList[j] + "/" + fileList[k] + "] color_mode=Default crop rois_import=[ROI manager] specify_range view=Hyperstack stack_order=XYCZT t_begin=" + leftChStart + " t_end=" + leftChEnd + " t_step=1 x_coordinate_1=0 y_coordinate_1=0 width_1=428 height_1=684");
					rename(title);
					
					// Create metadata tags
					Property.set("Exposure: ", exposure);
					Property.set("Total frames acquired: ", totalFrames);
					Property.set("Frames per second: ", framesPerSecond);
					Property.set("Instrument: ", "ONI Nanoimager");
					Property.set("Instrument serial number: ", instrumentSerial);
					Property.set("Software version: ONI, ", softwareVersion);
					Property.set("User: ", user);
					Property.set("Objective lens NA: ", objectiveNA);
					Property.set("Effective pixel size: ", pixelSize);
					Property.set("TIRF illumination angle: ", tirfAngle);
					Property.set("Stage position (x,y,z): ", stageXYZ);
					Property.set("Instrument temperature: ", temperature);
					Property.set("Transillumination Percentage Power: ", tlPercentage);
					Property.set("Focus offset: ", focusOffset);
					
					// Count number of programmed steps
					tempstr = metadata;
					ctr = 0;
					
					// Parse number of frames per step
					while (1 == 1) {
						if (tempstr.contains("Repeats")) {
							ctr++;
							tempstr = substring(tempstr, indexOf(tempstr, "Repeats") + 9);
							frameNumber = substring(tempstr, 0, indexOf(tempstr, "states") - 2);
							Property.set("State" + ctr + "_Frames", frameNumber);
							states = substring(tempstr, indexOf(tempstr, "states") + 11, indexOf(tempstr, "}]}"));
					
							// Count number of states in each programmed step
							ctr2 = 0;
							
							while (1 == 1) {
								if (states.contains("group")) {
									ctr2++;
									if (substring(states, indexOf(states, "record") + 8, indexOf(states, "values") - 2) == "true") {
										Property.set("State" + ctr + "_Step" + ctr2 + "_status", "saved");
									}
									else {
										Property.set("State" + ctr + "_Step" + ctr2 + "_status", "not saved");
									}
									states = substring(states, indexOf(states, "values") + 9);
									laserPowers = substring(states, 0, indexOf(states, "]"));
									Property.set("State" + ctr + "_Step" + ctr2 + "_laser powers [405, 488, 561, 638]", laserPowers)
								}
								else {
									break;
								}
							}
						}
						else {
							break;
						}
					}
	

					rename(title + "_" + leftChSuffix);

	
	
					// Check image size in megabytes and split stack into 4GB files if larger than this (otherwise big tiff errors will occur)
					images = getList("image.titles");
					imageNumber = images.length;
	
					for (img = 0; img < imageNumber; img++) {
						selectWindow(images[img]);
						size = (getValue("image.size") / 1000000); //Converts to MB 
						substackNumber = Math.ceil(size / 4000); //Calculate minimum number of substacks to maintain file size beneath 4GB

						Stack.getDimensions(width, height, channels, slices, frames);
						// Calibrate image scale
						Stack.setXUnit("micron");
						run("Properties...", "channels=" + channels + " slices=" + slices + " frames=" + frames + " pixel_width=" + pixelSize + " pixel_height=" + pixelSize + " voxel_depth=1 frame=[" + (1 / framesPerSecond) + " sec]");			
			
						// If stack needs to be split, determine lowest divisor
						if (substackNumber > 1) {
							
							divisible = false;
							
							while (divisible == false) {
								if (frames % substackNumber == 0) {
									divisible = true;
								}
								else {
									substackNumber += 1;
								}
							}	
	
							substackSize = frames / substackNumber;
	
							for (substack = 1; substack < substackNumber; substack++) {
								selectWindow(images[img]);
								run("Make Substack...", "slices=1-" + substackSize + " delete");
								saveAs("Tiff", saveDir + expList[i] + images[img] + "_" + (substack));
								close();
							}
							
							selectWindow(images[img]);
							saveAs("Tiff", saveDir + expList[i] + images[img] + "_" + (substackNumber));
							close();		
	
						// If the file does not exceed 4GB, save as is
						} else {
							saveAs("Tiff", saveDir + expList[i] + images[img]);
							close();
						}
				
					}
				}

				run("Collect Garbage");

				// Process right channel
				if (rightCh == true) {
		
					run("Bio-Formats Importer", "open=[" + rawDir + "/" + expList[i] + "/" + posList[j] + "/" + fileList[k] + "] color_mode=Default crop rois_import=[ROI manager] specify_range view=Hyperstack stack_order=XYCZT t_begin=" + rightChStart + " t_end=" + rightChEnd + " t_step=1 x_coordinate_1=428 y_coordinate_1=0 width_1=428 height_1=684");
					rename(title);
					Stack.getDimensions(width, height, channels, slices, frames);
					
					// Create metadata tags
					Property.set("Exposure: ", exposure);
					Property.set("Total frames acquired: ", totalFrames);
					Property.set("Frames per second: ", framesPerSecond);
					Property.set("Instrument: ", "ONI Nanoimager");
					Property.set("Instrument serial number: ", instrumentSerial);
					Property.set("Software version: ONI, ", softwareVersion);
					Property.set("User: ", user);
					Property.set("Objective lens NA: ", objectiveNA);
					Property.set("Effective pixel size: ", pixelSize);
					Property.set("TIRF illumination angle: ", tirfAngle);
					Property.set("Stage position (x,y,z): ", stageXYZ);
					Property.set("Instrument temperature: ", temperature);
					Property.set("Transillumination Percentage Power: ", tlPercentage);
					Property.set("Focus offset: ", focusOffset);
					
					// Count number of programmed steps
					tempstr = metadata;
					ctr = 0;
					
					// Parse number of frames per step
					while (1 == 1) {
						if (tempstr.contains("Repeats")) {
							ctr++;
							tempstr = substring(tempstr, indexOf(tempstr, "Repeats") + 9);
							frameNumber = substring(tempstr, 0, indexOf(tempstr, "states") - 2);
							Property.set("State" + ctr + "_Frames", frameNumber);
							states = substring(tempstr, indexOf(tempstr, "states") + 11, indexOf(tempstr, "}]}"));
					
							// Count number of states in each programmed step
							ctr2 = 0;
							
							while (1 == 1) {
								if (states.contains("group")) {
									ctr2++;
									if (substring(states, indexOf(states, "record") + 8, indexOf(states, "values") - 2) == "true") {
										Property.set("State" + ctr + "_Step" + ctr2 + "_status", "saved");
									}
									else {
										Property.set("State" + ctr + "_Step" + ctr2 + "_status", "not saved");
									}
									states = substring(states, indexOf(states, "values") + 9);
									laserPowers = substring(states, 0, indexOf(states, "]"));
									Property.set("State" + ctr + "_Step" + ctr2 + "_laser powers [405, 488, 561, 638]", laserPowers)
								}
								else {
									break;
								}
							}
						}
						else {
							break;
						}
					}
					
					// Calibrate image scale
					Stack.setXUnit("micron");
					run("Properties...", "channels=" + channels + " slices=" + slices + " frames=" + frames + " pixel_width=" + pixelSize + " pixel_height=" + pixelSize + " voxel_depth=1 frame=[" + (1 / framesPerSecond) + " sec]");			

					selectWindow(title);
					size = (getValue("image.size") / 1000000); //Converts to MB and divides by 2 as the image channels will be split, halving file size of each 
					substackNumber = Math.ceil(size / 4000); //Calculate minimum number of substacks to maintain file size beneath 4GB

					// If stack needs to be split, determine lowest divisor
					if (substackNumber > 1) {
						
						divisible = false;
						
						while (divisible == false) {
							if (frames % substackNumber == 0) {
								divisible = true;
							}
							else {
								substackNumber += 1;
							}
						}	

						substackSize = frames / substackNumber;

						for (substack = 0; substack < substackNumber; substack++) {
							selectWindow(title);
							run("Make Substack...", "slices=1-" + substackSize + " delete");
							saveAs("Tiff", saveDir + expList[i] + title + "_" + rightChSuffix + "_" + (substack));
							close();
						}		

						selectWindow(title);
						saveAs("Tiff", saveDir + expList[i] + title + "_" + rightChSuffix + "_" + (substackNumber));;
						close();		

					// If the file does not exceed 4GB, save as is
					} else {
						saveAs("Tiff", saveDir + expList[i] + title + "_" + rightChSuffix);
						close();
					}
				
				}
				run("Collect Garbage");
			}
		}
	}
}

print("Complete.");




