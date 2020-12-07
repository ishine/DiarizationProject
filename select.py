#!/usr/bin/env python

dict_adult = {}
list_key=[]

with open('/X/dataprep/data/train_adult_combined/spk2numutt', 'r') as f:
	for line in f:
    		data=line.split()
    		dict_adult[data[0]]=int(data[1])

adult_subset={}

# range values chosen to get adult numbers in compliance with child numbers
for key,value in dict_adult.items():
    if value in range(270,451):
        adult_subset[key]=dict_adult[key]
	list_key.append(key)

        
a = len(adult_subset)
print(a)
b = sum(adult_subset.values())
print(b)
   
with open('/X/dataprep/data/train_adult_combined/adult_subset','w') as f:
	 for x in list_key:
		f.write("{0}\n".format(x))

