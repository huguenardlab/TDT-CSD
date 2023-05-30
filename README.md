# TDT-CSD
Matlab code for reading and analyzing Linear MEA LFP data from TDT data files, including CSD
It makes assumptions about the format of the TDT file structure, including continous data in waves, and episodic data in SWPS, along with stimulus data.

Included in this reposotiory are several packages available elsewhere, including pvpmod, uipickfiles, and inputsdlg.

tdtcsd_new is the main code that will prompt you to open a TDT tank directory, usually ending with a run number, such as run-2

tdtcsd_prep will crawl through a directory tree, and will create a matlab file for each run, with episodes saved, rather than the continuous data obtained during the initial recording.  Then when tdtcsd_new is called it will load the smaller and more convenient matlab file if available.  
