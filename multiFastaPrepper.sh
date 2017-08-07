#!/bin/sh

##########################################################################################
#                         multiFastaPrepper v0.1.0, August 2017                          #
# Shell script, for Pinus gene tree-species tree purifying selection project, that       #
# converts a set of fasta DNA alignments into Phylip and NEXUS files (in prep for        #
# downstream analysis in RAxML using MAGNET) and outputs text summary of lengths (bp) of #
# of each locus (gene/partition)                                                         #
#                                                                                        #
# Last update: August 7, 2017, Richmond, VA                                              #
# Dr. Justin Bagley, Postdoctoral Scholar                                                #
# Plant Evolutionary Genetics Lab, Department of Biology, Virginia Commonwealth          #
# University                                                                             #
# E-mail: jcbagley@vcu.edu                                                               #
##########################################################################################


echo "
##########################################################################################
#                         multiFastaPrepper v0.1.0, August 2017                          #
##########################################################################################
"

######################################## START ###########################################
echo "INFO      | $(date) | STEP #1: SETUP. "
###### Set new path/dir environmental variable to user specified path, then create useful
##--shell functions and variables:
	MY_PATH=`pwd -P`
	echo "INFO      | $(date) |          Setting working directory to: $MY_PATH "

##--Move into user specified path (solves problem of executing analysis for non-local
##--working dir):
	cd $MY_PATH


echo "INFO      | $(date) | STEP #2: DO FILE CONVERSIONS FROM FASTA TO PHYLIP AND NEXUS AND ORGANIZE THE FILES "
###### CHECK/MAKE SUB-FOLDERS FOR ORIG AND CONVERTED FILES; CONVERT FASTAS TO PHYLIP AND NEXUS
###### FILES, AND STORE EACH FILE TYPE IN CORRESPONDING NEW SUB-DIRECTORY.
##--Make directories for each file type--original .fasta files, plus .fasta that have been
##--converted to phylip (.phy) and NEXUS (.nex) format. First, check whether the corresponding
##--folder exists; if not, make the folder. Do this for phy, nex, and orig. fasta folders,
##--so if starting in fresh wd, will create 3 sub-folders.
if [[ -z "$(find . -name "phy" -type d)" ]]; then
	mkdir phy
fi
if [[ -z "$(find . -name "nex" -type d)" ]]; then
	mkdir nex
fi
if [[ -z "$(find . -name "orig_fasta" -type d)" ]]; then
	mkdir orig_fasta
fi

echo "INFO      | $(date) |          Converting starting .fasta files to Phylip (.phy) and NEXUS (.nex) format."
	(
	for i in ./*.fasta; do
		echo "$i";
		
		MY_FASTA_BASENAME="$(basename -s '.fasta' $i)"
		# echo $MY_FASTA_BASENAME

		##--Use two Perl scripts to do the file conversions. The original scripts were written by Nayoki Takebayashi
		##--(http://raven.iab.alaska.edu/~ntakebay/teaching/programming/perl-scripts/perl-scripts.html) and by
		##--Shannon Hedtke (https://sites.google.com/site/shannonhedtke/Scripts). These scripts must be in your path
		##--and thus available from the command line interface. Download them, put them in bin, use chmod to give
		##--execute privledges, and you should be good.
		fasta2phylip.pl "$i" > "$MY_FASTA_BASENAME".phy
		mv ./*.phy ./phy/;
		convertfasta2nex.pl "$i" > "$MY_FASTA_BASENAME".nex
		mv ./"$MY_FASTA_BASENAME".nex ./nex/;

		mv "$i" ./orig_fasta/;		## Move each original fasta file into the "orig_fasta" folder created above (Lines 42 to 43).

	done
)

	MY_NUM_CONVERTED_PHYS="$( ls ./phy/* | wc -l)"
	echo "INFO      | $(date) |          $MY_NUM_CONVERTED_PHYS fasta files were converted to Phylip format. "

	MY_NUM_CONVERTED_NEXS="$( ls ./nex/* | wc -l)"
	echo "INFO      | $(date) |          $MY_NUM_CONVERTED_NEXS fasta files were converted to NEXUS format. "



echo "INFO      | $(date) | STEP #3: CALCULATE AND SAVE INFORMATION ON THE LENGTH OF EACH LOCUS IN THE DATASET (OUTPUTS "
echo "INFO      | $(date) |          FILES AND A SUMMARY TABLE WITH THE NAME OF EACH FASTA AND THE LENGTH (BP) OF THE "
echo "INFO      | $(date) |          CORRESPONDING LOCUS)."

########## PSEUDOCODE for getting the lengths of each of the loci:
## 1) Copy all fasta files into separate "list" dir (or dir x, with some other name)
## 2) Prep files for step #3 by going into "list" and loop through all the files and do the following:
##	- a.) first, remove lines with ">" symbols at start of line by searching and replacing '\>.*$\n' with *nothing*
##	- b.) second, remove all lines except for the first line by searching and replacing '\n.*' with *nothing*
## 3) Loop through each modified fasta created in step #2 above and count the number of characters in each locus, 
##   then output that value to a.) a regular list (using redirection) and b.) a table containing the locus name
##   followed by a tab and then the number of bp/characters in the alignment for that locus (including gaps, 
##   expected to be represented by '-' dash marks.

###### ACTUAL CODE:
mkdir list
(
	for i in $(find ./orig_fasta/ -name "*.fasta" -type f); do 
		echo "$i";
		
		cp "$i" ./list/;
		cd ./list/;
		
		MY_FASTA_BASENAME="$(basename $i)"
		i=$MY_FASTA_BASENAME
		
		### Note: following sed idea was from: https://stackoverflow.com/questions/8206280/delete-all-lines-beginning-with-a-from-a-file
		sed -i '' '/^\>/d' "$i";

		## Use sed to get only the first line of each (modified) fasta file: 
		## Note: idea from https://unix.stackexchange.com/questions/260506/how-to-delete-all-the-lines-in-a-unix-file-except-first-and-last-line.
		sed -i '' -n '1p' "$i";

		## Need one more step with perl to remove any blank lines or newlines from final fasta file.
		## This essentially just functions to remove the final carriage return and new line from
		## each file (which remain after the sed line just preceding this one).
		## Note: idea from https://stackoverflow.com/questions/3134791/how-do-i-remove-newlines-from-a-text-file).
		perl -p -i -e 's/\R//g;' "$i";

		echo "$i" >> ../filenames.txt
		wc -c "$i" | sed 's/\ .\/[A-Za-z0-9\_\-\.]*//g' >> ../locusLengths.txt
		cd ..;
	done
)

## Process the files created in the loop above to make final table of filenames + locus
## lengths in bp. Save, rather than remove, the individual filenames.txt and locusLengths.txt
## files for checking after the run. Uncomment first rm line below if you don't want to save
## copies of these files.
	NUM_FILES_WITH_LOCUSLENGTHS="$(wc -l ./locusLengths.txt | sed 's/\.\/.*$//g')"
	echo "INFO      | $(date) |          Making table with information on size (bp) for $NUM_FILES_WITH_LOCUSLENGTHS loci... "
	
	paste ./filenames.txt ./locusLengths.txt > ./table.txt
	sed -i '' 's/[\ ]*//g' ./table.txt
	## rm ./filenames.txt ./locusLengths.txt

	echo "filename" > filename_heading.txt
	echo "locusLength" > locusLength_heading.txt 
	paste ./filename_heading.txt ./locusLength_heading.txt > ./header.txt
	rm ./filename_heading.txt ./locusLength_heading.txt

	echo "INFO      | $(date) |          This table is saved in a file named 'locusLengthTable.txt'. "
	cat ./header.txt ./table.txt > ./locusLengthTable.txt
	rm ./header.txt ./table.txt



## The goal of creating a "list" folder populated with fasta files *in STEP #2 above* was 
## to create a physical sort of dictionary of files from which we could draw filenames and 
## use as raw material, to make in-place modifications of the fastas without changing, or 
## potentially "hurting", the original fasta files. 

## And, since we've already edited the original fasta files and used the modified fastas in
## the list dir to calculate and tabulate the lengths of all of the loci, and the modified
## fastas are no longer useful themselves since each one contains only 1 line (the first line),
## we can also delete the list folder and all of its contents using recursive rm:
rm -rf ./list/*;
rm -rf ./list/;


echo "INFO      | $(date) | Done prepping Pinus gene tree-species tree candidate gene data using "$0". "
echo "INFO      | $(date) | Bye.
"
#
#
#
######################################### END ############################################

exit 0
