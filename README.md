# tweetRecorder

## 1 Git clone repository
``git clone https://github.com/msmluca/tweetRecorder.git <shiny_server_folder>``

## 2 Create config/config.ini
Use config/config.ini.sample as template<br>

## 3 Create data and pid folders
Make sure the folders defined on step 2 exist

## 4 Schedule tweetStreamCron.sh
Create a cron task<br>
``crontab -e``<br>
``00 3  * * * <project_folder>/scripts/tweetStreamCron.sh -s <project_folder>/tweetStreaming/Python -d <data_folder>``

This script will:<br>
1. stop current streams<br>
2. compress json files<br>
3. resume streams<br>

## 5 Manage the streams 
This tool can be managed from https://<shiny_server>/tweetRecords/R/www/
