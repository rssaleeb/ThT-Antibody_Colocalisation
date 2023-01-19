// Purpose - detect number, intensity and size of protein species on a pull-down surface and compute real/chance signal coincidence between channels

// USER INPUTS ///////////////////////////////////////////////

dir = "..."; // Path to aligned image files

Ch1ID = "AF488_aligned.tif"; // Provide filename suffix for Ch1
Ch2ID = "ThT_aligned.tif"; // Provide filename suffix for Ch2

FOV_num = 2; // Number of fields of view per condition
stopSlice = 10; // Max projection of frames used for analysis, define here the number of frames to include

// Set threshold particle size (number of pixels) for species detection
Ch1_particlesize = 4;
Ch2_particlesize = 4;

// Set threshold intensity (SD above mean of ComDet-filtered image) for species detection
Ch1_threshold = 5;
Ch2_threshold = 5;




// MAIN CODE ////////////////////////////////////////////////

// Set up working environment
setBatchMode("hide");
run("Clear Results");

// Create list of all subfolders
folderList = getFileList(dir);

//Create save directory
File.makeDirectory(dir + "Analysis/");

// For each subfolder
for (i = 0; i < lengthOf(folderList); i++) {
	
	// Create matching save subdirectory
	File.makeDirectory(dir + "Analysis/" + folderList[i]);

	// For each FOV within the folder (excluding the results folder)
	for (j = 0; j < FOV_num; j++) {
	
		if (folderList[i] != "Analysis/") {	
			
			// Open each channel and Z-project	
			fileList = getFileList(dir + folderList[i]);
			filePrefix = substring(fileList[0], 0, indexOf(fileList[0], "0_channels"));
			
			run("Bio-Formats Importer", "open=[" + dir + folderList[i] + filePrefix + j + "_channels_t0_posZ0_" + Ch1ID + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
			rename("Ch1");
			run("Z Project...", "stop=" + stopSlice +" projection=[Max Intensity]");
			close("Ch1");
			
			run("Bio-Formats Importer", "open=[" + dir + folderList[i] + filePrefix + j + "_channels_t0_posZ0_" + Ch2ID + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	   		rename("Ch2");
	   		run("Z Project...", "stop=" + stopSlice +" projection=[Max Intensity]");
	   		close("Ch2");
	
			// Merge and rename channels
	   		run("Merge Channels...", "c2=MAX_Ch1 c3=MAX_Ch2 create");
	   		rename("merge");

	   		// Detect particles and compute channel colocalisation using the ComDet plug-in
	   		run("Detect Particles", "calculate max=2 plot rois=Ovals add=Nothing summary=Reset ch1i ch1a=" + Ch1_particlesize + " ch1s=" + Ch1_threshold + " ch2i ch2a=" + Ch2_particlesize + " ch2s=" + Ch2_threshold); 
			
			// Save results and close results windows
			selectWindow("merge");
			saveAs("Tiff", "" + dir + "Analysis/" + folderList[i] + "posXY" + j + "_particle_analysis.tif"); // This file contains the image file with detected particles indicated in overlay
			close("posXY" + j + "_particle_analysis.tif");
			
			selectWindow("Summary");
			saveAs("Results", dir + "Analysis/" + folderList[i] + "posXY" + j + "_particle_analysis.csv"); // This file contains the total number of particles detected and the channel coincidence
			close("posXY" + j + "_particle_analysis.csv");
			
			run("Clear Results");
			run("Close All");
		}

	}

}
