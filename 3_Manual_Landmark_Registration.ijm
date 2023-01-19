// This script aids landmark based registration of images
// It uses a channel for alignment that is not required for analysis


///// USER INPUTS ////////////////
dir_pre = "..."; // File path to pre-ThT data
dir_post = "..."; // File path to post-ThT data (most contain same folder names as pre-ThT directory
dir_save = "..."; // File path to desired save location

FOV_num = 64; // Number of FOVs per condition
alignCh = "AF647-trans"; // Suffix identifier of channel to use for landmark alignment
preCh = "AF488";
postCh = "ThT";

///// MAIN CODE //////////////////

// Loop through each folder in the directory
folderList = getFileList(dir_pre);
for (i = 0; i < lengthOf(folderList); i++) {
	if (File.isDirectory(dir_pre + folderList[i])) {
		
		// Make a save directory
		File.makeDirectory(dir_save + folderList[i]);
		
		// Identify filename prefix
		fileList = getFileList(dir_pre + folderList[i]);
		prefix = substring(fileList[0], 0, indexOf(fileList[0], "0_channels"));
		
		// Loop through each FOV
		for (j = 0; j < FOV_num; j++) {
								
			open(dir_pre + folderList[i] + prefix + j + "_channels_t0_posZ0_" + alignCh + ".tif"); //Alignment channel pre
			rename("Pre");
			setSlice(1);
			run("Enhance Contrast", "saturated=0.3");
			
			print(dir_post + folderList[i] + prefix + j + "_channels_t0_posZ0_" + alignCh + ".tif");
			open(dir_post + folderList[i] + prefix + j + "_channels_t0_posZ0_" + alignCh + ".tif"); //Alignment channel post
			rename("Post");
			setSlice(1);
			run("Enhance Contrast", "saturated=0.3");
			
			// Prompt user to provide landmarks			
			Dialog.create("Checkpont");
			labels = newArray("yes", "no");
			Dialog.addRadioButtonGroup("Align?", labels, 1, 2, "yes");
			Dialog.show();
			align = Dialog.getRadioButton();
			
			if (align == "yes") {
				setTool("point");
				waitForUser("Mark same landmark position in both images");
				
				// Obtain coordinates of the marked positions
				selectWindow("Pre");
				Roi.getCoordinates(pre_x, pre_y);
				selectWindow("Post");
				Roi.getCoordinates(post_x, post_y);
				
				// compute xy displacement
				disp_x = pre_x[0] - post_x[0];
				disp_y = pre_y[0] - post_y[0];
				
				// close windows
				run("Close All");
				
				// open channels of interest
				open(dir_pre + folderList[i] + prefix + j + "_channels_t0_posZ0_" + preCh + ".tif"); //Save pre-ThT channel
				img = substring(getTitle(), 0, indexOf(getTitle(), "."));
				saveAs("Tiff", dir_save + folderList[i] + img + "_aligned.tif");
				close();
				
				open(dir_post + folderList[i] + prefix + j + "_channels_t0_posZ0_" + postCh + ".tif"); //Align and save post-ThT channel
				img = substring(getTitle(), 0, indexOf(getTitle(), "."));
				run("Translate...", "x=" + disp_x + " y=" + disp_y + " interpolation=None stack");
				saveAs("Tiff", dir_save + folderList[i] + img + "_aligned.tif");
				close();			
				
			} else {
				run("Close All");
			}

		}
	}
}
