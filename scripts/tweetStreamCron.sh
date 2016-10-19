#!/bin/bash

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -s|--scripts)
    SCRIPT_FOLDER="$2"
    shift # past argument
    ;;
    -d|--data)
    DATA_FOLDER="$2"
    shift # past argument
    ;;    
    *)
     # unknown option
    ;;
esac
shift # past argument or value
done

if [ -n "$SCRIPT_FOLDER" ] && [ -n "$DATA_FOLDER" ];
then

	echo "Scripts folder: "$SCRIPT_FOLDER
	echo "Data folder: "$DATA_FOLDER
	
	echo "[1/3] Stop current streaming"
	cd $SCRIPT_FOLDER
	python tweetStop.py
	sleep 1

	#python tweetCompress.py
	echo "[2/4] Update Stats"
	cd $SCRIPT_FOLDER
	python tweetStats.py
	sleep 1

	echo "[3/4] Compress data"
	cd $DATA_FOLDER
	gzip *json
	sleep 1

	#python tweetCompress.py
	echo "[4/4] Resume streaming"
	cd $SCRIPT_FOLDER
	python tweetRun.py
	sleep 1

else
	echo "Please configure script folder and data folder"
	echo "$0 -s <python_script_folder> -d <json_data_folder>"
fi
