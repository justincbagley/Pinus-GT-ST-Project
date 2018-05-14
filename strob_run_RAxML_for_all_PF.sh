#!/bin/bash

#  Copyright ©2018 Justinc C. Bagley. For further information, see README and license    #
#  available in the Pinus-GT-ST-Project repository (https://github.com/justincbagley/ \  #
#  Pinus-GT-ST-Project/ Last update: May 13, 2018. For questions, please email           #
#  jcbagley@vcu.edu.                                                                     #

## Script for conditionally setting up and running basic, full BS and ML search run in
## SSE3 HPC MPI version of RAxML v8 (Stamatakis 2014) in the 'raxml' subdirectory of each
## model run folder (e.g. ./M9_10/, is model M9 run 10) for strob_clade.

## USAGE: ./strob_run_RAxML_for_all_PF.sh <email>

## Alignment file: strob_clade_simData.phy
## PF partitions file: strob_clade_simData.PF.partitions


######################################## START ###########################################
echo "INFO      | $(date) | Starting strob_run_RAxML_for_all_PF analysis... "
echo "INFO      | $(date) | STEP #1: SETUP AND USER INPUT. "
###### Set paths, environmental variables, and filetypes as different variables:
	MY_PATH=`pwd -P`
#echo "INFO      | $(date) |          Setting working directory to: $MY_PATH "
	CR=$(printf '\n')
	calc () { 
	bc -l <<< "$@"; 
}

###### Set environmental variable for user input:
MY_EMAIL_ACCOUNT=$1


echo "INFO      | $(date) | STEP #2: LOOP THROUGH RAxML FOLDERS, CONDITIONALLY SET UP AND RUN RAxML IF FILE STRUCT & QUEUE RESOURCES AVAILABLE. "
(
	for i in ./*/; do
		cd "$i";
		MY_SET_FOLDERNAME="$(basename $j)"
		echo "INFO      | $(date) | ##----------   $MY_SET_FOLDERNAME"   ----------##; 
	
		for j in ./*/; do
			cd "$j";
			MY_FOLDERNAME="$(basename $j)"
			echo "INFO      | $(date) | ...  $MY_FOLDERNAME  ...";
			(
				if [[ -f ./PartitionFinder/analysis/best_scheme.txt  ]] && [[ "$(wc -c ./PartitionFinder/analysis/best_scheme.txt | sed 's/\ .*//' | perl -pe $'s/\t//g')" -gt 10000 ]]; then 
					cd ./raxml/; 
						echo "INFO      | $(date) | Prepping ${MY_FOLDERNAME} RAxML run folder... "
						if [[ ! -f ./strob_clade_simData.phy ]]; then 
							cp ../ElConcatenero/strob_clade_simData.phy .;
						fi

						if [[ ! -f ./strob_clade_simData.PF.partitions ]]; then
							MY_TOTAL_NUM_LINES="$(cat ../PartitionFinder/analysis/best_scheme.txt | wc -l | sed 's/\ //g')"
							MY_RAXML_PART_START_LINE="$(cat ../PartitionFinder/analysis/best_scheme.txt | grep -n 'RaxML' | sed 's/:.*//')"
							sed -n ''"$MY_RAXML_PART_START_LINE"','"$MY_TOTAL_NUM_LINES"'p' ../PartitionFinder/analysis/best_scheme.txt > ./strob_clade_simData.PF.partitions
						fi

						if [[ ! -f ./raxml_qsub.sh ]]; then
echo "INFO      | $(date) | Creating raxml run (shell) script... "
echo "#!/bin/bash

#$ -N ${MY_FOLDERNAME}
#$ -S /bin/bash
#$ -cwd
#$ -V
#$ -j y
##  #$ -pe smp 4
#$ -m a
#$ -M ${MY_EMAIL_ACCOUNT}


cd ${PWD}

raxml -f a -x $(python -c "import random; print random.randint(10000,100000000000)") -p $(python -c "import random; print random.randint(10000,100000000000)") -# 100 -m GTRGAMMA -s ./strob_clade_simData.phy -q ./strob_clade_simData.PF.partitions -n strob_${MY_FOLDERNAME}_raxml


exit 0

" > ./raxml_qsub.sh

						fi

						## Check for queue slots to use for raxml runs (depends on custom q stat check function I wrote called 'myq'):
						MY_REMAINING_QUEUE_SLOTS="$(myq | grep -h 'Remaining\ slots' | sed 's/Remain.*\ //')"
						if [[ "$MY_REMAINING_QUEUE_SLOTS" -ge "1" ]]; then
							qsub ./raxml_qsub.sh/;
						elif [[ "$MY_REMAINING_QUEUE_SLOTS" ! -ge "1" ]]; then
							echo "WARNING!  | $(date) | Insufficient slots remaining to queue ${MY_FOLDERNAME} RAxML run. Checking next run folder... "
							##exit 1
						fi

					cd ..;
				
				
				elif [[ ! -f ./PartitionFinder/analysis/best_scheme.txt ]]; then
					echo "WARNING!  | $(date) | PartitionFinder run for ${MY_FOLDERNAME} is incomplete. Moving on to next model run folder... "
				fi
			)
			cd ..;
		done
	
		cd ..;
	done
)	


exit 0

