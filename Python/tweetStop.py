# -*- coding: utf-8 -*-*
# @Author: Luca Minello - luca.minello@gmail.com
# @Date:   2016-10-10 15:03:16
# @Last Modified by:   Luca Minello
# @Last Modified time: 2016-10-17 22:27:38

import subprocess,configparser


def load_configuration(config_file):

	config = configparser.ConfigParser()
	config.read(config_file)    

	return(config)

def main():

	configuration = load_configuration('../config/config.ini')

	process_list = []
	for channel in configuration.sections():
		cmd = ['python','tweetStream.py', '-c',channel,'-s']
		process_list.append(subprocess.Popen(cmd)) # continue immediately

if __name__ == "__main__":
	main()
