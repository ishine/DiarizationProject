#!/bin/usr/env python

#Divides the corpora into 3 sub directories of ages and 2 subdirectories of gender

import os
import glob
import shutil

list1 = []
list_male = []
list_female = []
dict1 = {}
dict2 = {}
dict3 = {}

#function called to split into 3 sub directories depending on the age limits chosen
def splitAge_function(list_path, name1, name2, name3):
	pathname1 = os.path.join('/X/adosMod3/',name1)
	pathname2 = os.path.join('/X/adosMod3/',name2)
	pathname3 = os.path.join('/X/adosMod3/',name3)
	if not os.path.exists(pathname1):	
		os.mkdir(pathname1)
	if not os.path.exists(pathname2):
		os.mkdir(pathname2)
	if not os.path.exists(pathname3):
		os.mkdir(pathname3)
	for x in list_path:
        	y = x.split("_") #Depends on the pathname and how it is split. Taken y[2] accordingly.
        	if (y[2] in list1) and (y[2] in dict1.keys()):
                	shutil.copy(x,pathname1)
        	if (y[2] in list1) and (y[2] in dict2.keys()):
                	shutil.copy(x,pathname2)
        	if (y[2] in list1) and (y[2] in dict3.keys()):
                	shutil.copy(x,pathname3)


#function to split according to gender
def splitGender_function(list_path, name1, name2):
	pathname1 = os.path.join('/X/adosMod3/',name1)
        pathname2 = os.path.join('/X/adosMod3/',name2)
	if not os.path.exists(pathname1):
		os.mkdir(pathname1)
	if not os.path.exists(pathname2):
		os.mkdir(pathname2)
	for x in list_path:
		y = x.split("_")
		if y[2] in list_male:
			shutil.copy(x,pathname1)
		if y[2] in list_female:
			shutil.copy(x,pathname2)
	

#created 3 dictionaries depending on the pre-defined age limit.The values have been hardcoded depending on the min and max ages from the ageGenderIQ.sh file to give 3 almost equal splits. In this case, ages 3.5 to 7.6 years, ages 7.6 to 10 years and ages 10 and above.
with open('/X/adosMod3/ageGenderIQ.sh','r') as f:
	for word in f:
                word = word.split( )
		list1.append(word[0])
		if int(word[1]) in range(43,92):
	        	dict1[word[0]] = int(word[1])
		if int(word[1]) in range(92,119):
			dict2[word[0]] =  int(word[1])
		if int(word[1]) in range(119,159):
			dict3[word[0]] = int(word[1])
                if int(word[2]) == 1:
			list_male.append(word[0])
		if int(word[2]) == 2:
			list_female.append(word[0])


wavfile_path = glob.glob(os.path.join('/X/adosMod3/adosMod3_wav/','*.wav'))
rttmfile_path = glob.glob(os.path.join('/X/adosMod3/adosMod3_rttm','*.rttm'))

splitAge_function(wavfile_path, "adosMod3_wav1", "adosMod3_wav2", "adosMod3_wav3")
splitAge_function(rttmfile_path, "adosMod3_rttm1", "adosMod3_rttm2", "adosMod3_rttm3")

splitGender_function(wavfile_path, "adosMod3_male_wav", "adosMod3_female_wav")
splitGender_function(rttmfile_path, "adosMod3_male_rttm", "adosMod3_female_rttm")
