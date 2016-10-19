# -*- coding: utf-8 -*-*
# @Author: Luca Minello - luca.minello@gmail.com
# @Date:   2016-10-18 15:03:16
# @Last Modified by:   Luca Minello
# @Last Modified time: 2016-10-19 22:49:12

import subprocess,configparser
import glob, json, csv, os

def load_configuration(config_file):

	config = configparser.ConfigParser()
	config.read(config_file)    

	return(config)

TWEET_KEYS = ['id_str', 'created_at']
ENTITIES_KEYS = ['hashtags']
USER_KEYS = ['id_str', 'screen_name', 'name']

TWEET_ALL_KEYS = TWEET_KEYS + ['user.' + key for key in USER_KEYS] + ['entities.' + key for key in ENTITIES_KEYS]

def main():

	configuration = load_configuration('../config/config.ini')

	for channel_name in configuration.sections():
		tweeter_data_folder = configuration[channel_name]['tweeter_data_folder'] + "/"
		tweeter_data_json = configuration[channel_name]['output_file_prefix'] + "*.json"
		tweeter_data_stat = configuration[channel_name]['tweeter_data_folder'] + "/" + configuration[channel_name]['output_file_prefix'] + "stats.csv"

		create_header = False

		if not os.path.isfile(tweeter_data_stat):			
			create_header = True

		output_stats = open(tweeter_data_stat, 'a')	
		output_writer = csv.DictWriter(output_stats, TWEET_ALL_KEYS)
		
		# Load all json files
		list_files = glob.glob(tweeter_data_folder + tweeter_data_json)
		for current_file in list_files:	

			print("Loading: " + current_file)
			rawdata_file = open(current_file,'r')

			for line in rawdata_file:				
				try:
					track = json.loads(line)

					# Basic tweet data
					tweet_data = dict.fromkeys(TWEET_KEYS)
					tweet_data.update({key : track.get(key,'') for key in TWEET_KEYS})	
					# User tweet data				
					tweet_user = dict.fromkeys(['user.' + key for key in USER_KEYS])
					if track.has_key('user'):
						tweet_user.update({'user.' + key : track['user'].get(key,'') for key in USER_KEYS})

					# Entities tweet data
					tweet_entities = dict.fromkeys(['entities.' + key for key in ENTITIES_KEYS])
					if track.has_key('entities'):
						tweet_entities.update({'entities.' + key : track['entities'].get(key,'') for key in ENTITIES_KEYS})
						tweet_hashtags = {'entities.hashtags' : ":".join([hashtag['text'] for hashtag in tweet_entities['entities.hashtags']])}						
					else:
						tweet_hashtags = {'entities.hashtags':''}						

					# Merge all
					tweet_data.update(tweet_user)
					tweet_data.update(tweet_hashtags)				

					# Convert to utf-8
					tweet_data_enc = {key : value.encode("utf-8") if isinstance(value, basestring) else value for key,value in tweet_data.iteritems() }
									
					# Create header if new file
					if (create_header):						
						output_writer.writeheader()
						create_header = False
					
					# Write stats out
					output_writer.writerow(tweet_data_enc)   

				except Exception, e:
					print("Error " + str(e))			
										

if __name__ == "__main__":
	main()

