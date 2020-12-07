#!/bin/bash/env python

#To get the individual system rttm files for each speaker from the overall file  that was created during evaluation, run split_map.sh : bash split_map.sh 
#This will give 27 individual rttm and map files.

import os
import sys
import glob
import numpy as np
import math
from sklearn.metrics import recall_score
from sklearn.metrics import classification_report
from sklearn.metrics import precision_recall_fscore_support
import matplotlib.pyplot as plt

dict_map = {}

dict_map_path = '/X/CARE/rttm/system/'

for filename in glob.glob(os.path.join(dict_map_path,"*.txt")):
        with open(filename,'r') as f:
                for line in f:
                        line = line.split(',')
                        if 'mapped' in line:
                                dict_map[line[3]+"_"+line[0]] = line[2]

reference_path = '/X/CARE/rttm/reference/'
system_path = '/X/CARE/rttm/system/'

dict_reftime = {}
dict_systime = {}
max_list_ref = []
max_list_sys = []
frame_rate=100

def speaker_start_end_times(pathname,dict_name,max_list):
	for filename in glob.glob(os.path.join(pathname,"*.rttm")):
		sum_float = 0
		with open(filename,"r") as f:
			for line in f:
				line = line.split()
				if line[7] == '1' or line[7] == '2':
					line[7] = dict_map[line[7]+'_'+line[1]]
				x = line[7]
				duration = float(line[3]) + float(line[4])
				sum_float = max(sum_float,duration)
				if x not in dict_name.keys():
					dict_name[x] = [[float(line[3]), duration]]
				elif x in dict_name.keys():
					new_time = [float(line[3]),duration]
					dict_name[x].append(new_time)
			max_list.append([line[1],sum_float])
	max_list = max_list.sort()			

def populate(dict_name,session_name,max_value,total_ref_duration):
	X = np.zeros((max_value + 1))
	for x in dict_name.keys():
		x1 = x.split("_")
		if session == x1[1]:
			if x1[0] == 'psych':
				for val in dict_name[x]:
					X[int(round(val[0],2)*frame_rate):int(round(val[1],2)*frame_rate)+1] = 1
			elif x1[0] == 'child':	
				for val in dict_name[x]:
					X[int(round(val[0],2)*frame_rate):int(round(val[1],2)*frame_rate)+1] = 2
	X = X[0:total_ref_duration + 1]
	return X

speaker_start_end_times(reference_path,dict_reftime,max_list_ref)
speaker_start_end_times(system_path,dict_systime,max_list_sys)

total_sessions = len(max_list_ref) #27 seakers

for i in range(0,total_sessions):
	session = max_list_ref[i][0]
#	print("This is {}'s session".format(session))
	max_value = int(round((max(max_list_ref[i][1],max_list_sys[i][1]))*100,2))
	ref_max = int(round(max_list_ref[i][1]*100,2))
	R = populate(dict_reftime,session,max_value,ref_max)
	S = populate(dict_systime,session,max_value,ref_max)
	print(classification_report(R.astype(int), S.astype(int), target_names = ['Silence','Psych','Child']))
	#print(round(precision_recall_fscore_support(R.astype(int), S.astype(int), average = None)[1][2],2))
