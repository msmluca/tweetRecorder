# -*- coding: utf-8 -*-*
# @Author: Luca Minello - luca.minello@gmail.com
# @Date:   2016-10-10 15:03:16
# @Last Modified by:   Luca Minello
# @Last Modified time: 2016-10-18 20:39:39


from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream
import glob, csv, json, configparser, os, sys, getopt, signal
import gzip
from datetime import datetime

class StdOutListener(StreamListener):
	""" A listener handles tweets are the received from the stream.
	This is a basic listener that just prints received tweets to stdout.
	"""
	def __init__(self, output_file):
		self.output_file = output_file

	def on_data(self, data):
		with open(self.output_file, 'a+') as f:
			f.write(data)
			print(datetime.now().strftime("%d-%m-%Y %H:%M:%S") + " new tweet!")
		
		return True

	def on_error(self, status):
		print(status)

def load_configuration(config_file):

	config = configparser.ConfigParser()
	config.read(config_file)    

	return(config)


def stream_channel(configuration, channel_name):

	start_datetime = datetime.now().strftime("%Y%m%d_%H%M")
	consumer_key = configuration[channel_name]['consumer_key']
	consumer_secret = configuration[channel_name]['consumer_secret']
	access_token = configuration[channel_name]['access_token']
	access_token_secret = configuration[channel_name]['access_token_secret']
	output_file = configuration[channel_name]['tweeter_data_folder'] + \
					"/" + \
					configuration[channel_name]['output_file_prefix'] + \
					start_datetime + \
					".json"

	hashtags = json.loads(configuration[channel_name]['hashtags'])
	
	print(output_file)
	
	l = StdOutListener(output_file)
	auth = OAuthHandler(consumer_key, consumer_secret)
	auth.set_access_token(access_token, access_token_secret)
	stream = Stream(auth, l)
	
	stream.filter(track=hashtags)




def main(argv):
	channel_name = ''
	force_restart = False
	force_stop = False

	try:
		opts, args = getopt.getopt(argv,"hc:rs",["channel="])
	except getopt.GetoptError:
		print('test.py -c <channelname> -rs')
		sys.exit(2)

	for opt, arg in opts:
		if opt == '-h':
			print('test.py -c <channelname> -rs')
			sys.exit()
		elif opt in ("-c", "--channel"):
			channel_name = arg
		elif opt in ("-r"):
			force_restart = True
		elif opt in ("-s"):
			force_stop = True			
	

	configuration = load_configuration('../config/config.ini')

	if not channel_name in configuration:        
		print("Channel %s not found" % channel_name)
		sys.exit()

	print("")
	print("^^^ TWEETER STREAMING ^^^")
	print("Stream Channel: %s" % channel_name)
	print("Restart: %s" % str(force_restart))
	print("Stop: %s" % str(force_stop))
	print("")

	pid = str(os.getpid())
	pidfile = configuration[channel_name]['pid_folder'] + "/" + channel_name + ".pid"

	if os.path.isfile(pidfile):		
		oldpid = int(open(pidfile, 'r').readline())
		print("Current PID: %d" % oldpid)
		if (force_stop == True) | (force_restart == True):
			print("Kill current process")
			try:
				os.kill(oldpid, signal.SIGTERM)
			except OSError, e:
				print("PID not found: %s" % str(e))			
			os.unlink(pidfile)
		else:
			print("%s already exists, exiting" % pidfile)
			sys.exit()
				
	if (force_stop == True):
		print("Stop requested")
		sys.exit()

	if int(configuration[channel_name]['active']) != 1:
		print("Sorry this channel is disabled")
		sys.exit()
		
	open(pidfile, 'w').write(pid)

	try:
		stream_channel(configuration, channel_name)    # Do some actual work here		
	finally:
		os.unlink(pidfile)


if __name__ == "__main__":
	main(sys.argv[1:])
