#!/bin/bash

cd $1
dirs=*/
for dir in ${dirs[@]}
do
	#echo $dir
	cd $dir
	#sudo perf report -F sample,period -i _record\-1 > perf_report_col

	if [[ $2 == "clean" ]];
	then
		recs=perf_report_perf_report*
		for rec in ${recs[@]}
		do
			echo $rec
			sudo rm $rec
		done
	elif [[ $2 == "move" ]];
	then
		recs=*$2*
		for rec in ${recs[@]}
		do
			sudo mv $rec ../../perf_output_backup/$dir/
		#sudo mv "${rec}_record\*" ../perf_output_backup/$dir/
		#sudo mv "${rec}_stat\*" ../perf_output_backup/$dir/
		done
	else
		recs=instructions*_record*
		for rec in ${recs[@]}
		do
			if [[ -f perf_report_$rec ]]; then
				continue
			fi
			echo $rec
			sudo perf report -i $rec > perf_report_$rec
		done
	fi
	cd -
done
