## Information for ISI

This repository is a copy of the repository (under SAIL-USC) that was made for the SLT paper submission. 'X' in the path names, both in the README and in the code, is a place holder for the actual path names in order to maintain the privacy of the project

The scripts recall.py, filter.py, select.py and split_map.sh are my contributions to the Porject of which recall.py is particularly important as it validated the success of our experimentation. 

The file pv_prepareMyST.sh is a file that very closely follows the file https://github.com/kaldi-asr/kaldi/blob/master/egs/voxceleb/v2/run.sh but has been modified by me for creating the directories (with and without pitch variations). My contributions have been represented in the code.

The evaluation script diarize_kaldi.sh was written by the PhD student I collaborated with. My contributions to this script are minor and have been represented in the code.

# PROJECT DETAILS

## Dataset 

The MyST dataset consists of 1372 child speakers, conversing with a virtual tutor, summming up to a total of 240051 recordings(.wav) among all the children. 

Each recording has been treated as an utterance. The subset of 3 times the original data was taken from augmented ( reverberated + MUSAN ) data combining it with the original data, thus using 4 times the original data, anticiapting a loss of half the data during filtration. 

The adult data added was chosen using select.py to closely resemble the child data in terms of number of speakers and utterances. The values in select.py have to be varied to get desired numbers.

## Modified Dataset using Pitch Variation: Approach 1
Pitch variation has been introduced using sox to increase the number of child speakers to match the original number of adult speakers, 7323. Minimum and maximum cent values taken are -182 and +174, introducing pitch variations between 0.9 to 1.1 times the original pitch frequency. To introduce pitch variations between 0.8 to 1.2 times the original values, use -386 and +316 as the extremities.  

When the variable PV is set to 1 in the script pv_prepareMyST.sh, pitch variations will be introduced. For experimental purposes, the process is done 5 times, increasing the number of child speakers from 1372 to 8232. The number of times the process is repeated can be varied. The total number of child speakers and utterances are 8232 and 2880612, brought down to 7324 speakers and 2549773 respectively, to maintain a balance between child and adult data.

A subset of close to 7323 speakers can be taken by setting appropirate values of number of speakers and number of utterances in the program select.py that returns a list that can be given to utils/subset_data_dir.sh with the " --spk-list " argument. Another method is to vary the number of utterances in utils/subset_data_dir.sh with the " --speakers " argument until the desired number of speakers is obtained. It is important for the number of speakers of child and adult to match, more than it is for the number of utterances. 

Data, when reverberated only once, -reverb is not added to the recording ID. To avoid loss of data because of inconsistency while running fix_data_dir.sh, the recording ID in wav.scp and segments of train_reverb should be changed to include -reverb-rec instead of just -rec.

## Modified Dataset using Pitch Variation: Approach 2
In this method, pitch variation is being used to increased the number of original utterances for the same speaker instead of generating new speakers. 

Pitch variation was introduced 3 times in the range of 0.9 to 1.1 times the original frequency ( -182 to +174 cents). Thus, the original number of child speakers will be maintained while essentially increasing the total number of utterances to 4 times that of the original data, i.e., from 240051 to 960204. Augmented data, reverberation + MUSAN, of 960204 utterances was added to this giving a total of 1372 speakers and 1,920408 utterances. 

A subset of the adult data was chosen using select.py to match the number of child speakers, 1373 speakers while also trying to maintain similar number of utterances 1030942 utterances, which was what was approximately estimated for child utterances after the process of filtration (losing half the utterances). 

Combined child and adult data has a total of 2745 speakers and 2951350 utterances. After filtration, 2737 speakers and 2081141 utterances remain.

## Kaldi Directory

The script prepare_MyST.sh will create a directory called train_dir on the Desktop with the necessary files, wav.scp, spk2utt, utt2spk and segments, while also creating soft links to the required kaldi directories. 

The loaction variables should be set accordingly.

Kaldi expects the utterance id to be prefixed with speaker id and hence certain modifications need to be made when increasing replications (as a part of augmentation) as a prefix is added to the utterance ids to annotate the replication.

The MyST data directory is at /X/MyST_material/myst

mfcc and vad feature directoreis are /X/MyST_material/dataprep/mfcc and /X/MyST_material/dataprep/vad respectively

The 4 model files can be found at /X/MyST_material/dataprep/nnet

## Kaldi Directory after PV

When the variable PV is set to 0 in pv_prepareMyST.sh it functions exactly like prepare_MyST.sh. When PV is set to 1, the kaldi directory takes longer to prepare because it is handling 6 times the original data.

MyST data directory is same as above.

The kaldi directory is at /X/MyST_material/pvDir . MFCC and VAD directories are subdirectories within this directory

The data directory within the pvDir has the clean and augmented (music, babble, noise and reverbation ) child data, along with a combination of the two.

The combined directory for adult data can be found in /X/MyST_material/dataprep/data/train_combined_adult


## run.sh

Stages 2-10 are almost the same as in /kaldi/egs/voxceleb/v2/run.sh with certain changes to get different models for comparing performances. 

The model hyper parameters changed during training are in local/nnet3/xvector/run_xvector.sh. 4 models have been trained.

### Training hyperparameters
| Model | Time to train | Stage6:# repeats | Stage6: min and max frames per chunk | Stage8: initial learning rate| Stage8: number of epochs|
|------:|--------------:|-----------------:|-------------------------------:|-----------------------------:|------------------------:|
|  a    | ~8.5 hours    |      50          | 150 - 250                      |  0.001                       |        3                |
|  b    | ~9.5 hours    |      15          | 100 - 200                      |  0.002                       |        5                | 
|  c    | ~14 hours     |      16          | 100 - 300                      |  0.005                       |        8                |  
|  d    | ~32 hours     |      17          | 100 - 300                      |  0.005                       |        15               |

#### Modifications to model b:
| Model | # repeats | min - max frames per chunk | initial learning rate | # of epochs |
|-----|-----|-----|-----|-----|
|xvector_newb1| 15 | 100 - 200 | 0.002 | **8** |
|xvector_newb2| 15 | 100 - 200| **0.005** | 5 |
|xvector_newb3| 15 | **100 - 250** | 0.002 | 5 |
|xvector_newb4| 15 | **100 - 300** | 0.002 | 5 |


## Evaluation Scripts

Initially, baseline_xvectors.sh was used to evaluate the model. This program can be used as is only for the CARE corpus consisting of 27 child speakers.

The script, diarize_kaldi.sh, can be used on the CARE corpus as well as the DIHARD corpus. It provides two methods of evaluation namely, PLDA and Spectral Clustering. The variable "method" has to be set to either "plda" or "SC". It requires https://github.com/nryant/dscore and the packages mentioned in the README.md of the repository. When method is set to SC, additionally, https://github.com/manojpamk/pytorch_xvectors will be requried. 

## Evaluation Results from the different models

The DIHARD corpus consits of 47 recordings, the CARE corpus consists of 27 recordings, adosMod3 consists of 346 recordings and BOSCC_high and low both have 25 recordings each
### DER (Mean, Std) using PLDA (Probabilistic Linear Discriminant Analysis) and SC (Spectral CLustering) methods                                        
Model| DIHARD PLDA |DIHARD SC|CARE PLDA |CARE SC|adosMod3 PLDA |adosMod3 SC |toddler- BOSCC_high PLDA| toddler- BOSCC_high SC|toddler- BOSCC_low PLDA|toddler- BOSCC_low SC|
 ------|-----|---------|-------|--------|--------|--------|--------|--------|--------|--------|                            
Pretrained| (26.57, 16.58)|(26.21, 16.90)|(27.89, 17.56)|(16.70, 13.63)|(19.61, 13.44)|(13.52, 9.48)|(35.05, 24.34)|(33.45, 24.20)|(36.57, 16.47)|(39.32, 16.74)|
model_a| (22.06, 15.24)|(23.58, 16.85)|(17.38, 13.56)|(13.61, 9.45)|(15.70, 11.43)|(11.87, 8.29)|(32.51, 24.30)|(29.22, 24.46)|(34.96, 16.60)|(34.98, 17.48)|
model_b| (20.89, 14.91)|(22.02, 17.04) | (16.48, 13.66)|(12.83, 10.27)|(14.06, 11.31)|(11.62, 8.65)|(33.79, 24.96)|(28.23, 24.42)|(30.79, 16.84)|(30.86, 15.59)|
model_c| (22.08, 16.45)|(21.50, 15.90)| (15.04, 11.55)|(11.90, 8.38)|(14.82, 11.71)|(11.84, 8.49)|(31.05, 23.89)|(28.29, 24.32)|(28.81, 16.61)|(31.02, 15.965)|
model_d| (20.83, 14.25)|(22.40, 16.70)| (15.97, 13.58)|(11.52, 8.05)|(14.73, 11.97)|(11.47, 8.05)|(30.92, 24.02)|(28.14, 12.29)|(35.80, 17.91)|(30.84, 15.59)|

### DER (Mean, STD) using PLDA and SC for new models 

model_newb1 and model_newb2 are variations of the original model_b. Their hyperparameters are specified in the table "Modifications to model b"

model_pvDir = pitch variations introduced were between 0.9 and 1.1, increasing the number of speakers to number of original speakers times the number of times pitch variations were introduced

model_pvDir_new2 = same as above but pitch variations introduced were between 0.8 and 1.2

model_pvDir_1372 = pitch variations introduced were between 0.9and 1.1 but the number of speakers were kept the same as the original, adding the pitch variation as augmented utterances 


| Model | DIHARD PLDA | DIHARD SC | CARE PLDA | CARE SC | adosMod3 PLDA | adosMod3 SC | toddler- BOSCC_high PLDA | toddler- BOSCC_high SC| toddler- BOSCC_low PLDA| toddler- BOSCC_low SC|
-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|-----|
model_newb1| (21.85, 15.95)| (23.79, 17.42)| (19.37, 14.27)| (11.66, 7.00)| (14.72, 11.8993)| (11.83, 9.03)| (32.67, 24.39)| (27.06, 24.19)| (31.36, 17.07)| (29.64, 15.71)|
model_newb2| (21.71, 15.56)| (22.13, 16.71)| (15.34, 13.31)| (11.40, 6.96)| (15.23, 12.29)| (11.14, 7.82)| (33.19, 24,78)|(27.68, 24.36)| (29.13, 14.82)|(30.80, 15.28)|
model_newb3| (21.28, 14.34)| (22.25, 16.38)| (18.85, 13.64)| (12.11, 8.93)| (14.41, 10.91)| (11.33, 8.13)| (32.39, 24.02)| (27.79, 24.24)| (29.69, 14.02)| (30.60, 15.62)|
model_newb4| (20.49, 14.68)| (21.27, 15.54)| (19.59, 15.41)| (11.61, 7.01)| (14.39, 11.42)| (11.76, 8.04)| (30.62, 23.72)| (28.36, 24.33)| (31.14, 15.58)| (31.31, 16.56)|
model_pvDir| (24.97, 17.66)| (21.76, 15.54)| (16.43, 13.69)| (10.71, 6.16)| (13.00, 9.24)| (11.88, 9.09)| (36.49, 24.51)| (26.69, 23.93)| (35.11, 17.12)| (28.86, 15.36)|
model_pvDir_new2| (25.20, 16.19)| (21.54, 16.68)| (17.58, 13.70)| (12.24, 10.09)| (15.13, 10.56)| (11.17, 8.26)| (34.78, 24.47)| (27.11, 23.97)| (38.64, 17.67) | (28.92, 14.97)|
model_pvDir_1372| (25.53, 16.58)| (22.09,16.06)| (19.85, 13.87)| (13.70, 10.60)| (15.86, 9.83)| (11.83, 8.34)| (38.82, 24.34)| (28.73, 24.67)| (40.65, 17.29)| (30.36, 14.92)|

## Recall

Recall can be used as another evaluation metric like DER to determine the performance of a diarization model.

The hypothesis/system rttm file that is generated during evaluation is split into separate rttm files based on the child speaker for the datasets using split_map.sh. The corresponding mappings are used to create a dictionary in the python file recall.py, that calculates the precision, recall and F-1 scores for the different classes, Silence, Psychiatrist and Child and Parents when applicable.

Taking a frame rate of 100, treating each second to span over 100 indices of an array, chunks of speech start times upto duration determined from the rttm files are populated into the array as values 0, 1, 2 and 3 representing Silence, Psychiatrist, Child and Parent. The array lengths vary based on the total duration of the session, the system total duration is truncated depending on the reference rttm files. 

By running the bash script split_map.sh, the mappings are obtained along with individual rttm files. This file inturn calls the python file recall.py.

The mean child recall values for the PLDA and SC methods of the CARE dataset comprising of 27 sessions are presented below:

 
| Model | PLDA mean recall | SC mean recall |
-----|-----|-----|
Pretrained| 0.497| 0.702|
model_a| 0.709|0.777|
model_b| 0.694|0.835|
model_c| 0.783| 0.799|
model_d| 0.709| 0.808|
model_newb1| 0.726| 0.829|
model_newb2| 0.713| 0.828|
model_newb3| 0.693| 0.803|
model_newb4| 0.644| 0.830|
model_pvDir| 0.732| 0.831|


The mean child recall values for the PLDA and SC methods of the ADOSMod3 corpus are presented in the table below. The comparison is mainly between the pretrained model and the pitch variation model since that's the one that produces best results.

| Model | PLDA mean recall values | SC mean recall values |
-----|-----|-----|
Pretrained| 0.820| 0.869|
model_b| 0.852| 0.860|
model_pvDir| 0.913| 0.842|
model_newb1| 0.850| 0.835|
model_newb2| 0.863| 0.855|
model_newb3| 0.868| 0.855|
model_newb4| 0.859| 0.854|



## Age Experiments

For the adosMod3 corpus, children have been classified into 3 categories based on their ages. filter.py was the program used to segregate the wave files based on the ages. This script checks to see which of the files listed in ageGenderIQ.sh (contains file name, age, gender and verbal quotient information) are actually present in the corpus. The minimum and maximum age values were found and 3 categories for ages were determined such that each category would have similar number of .wav files. Each of these groups have been used as separate corpora to evaluate the 4 existing models as well as the pretrained model. The Age groups, in months,  are as follows:

Age Group1 : 43 - 92

Age Group2 : 92 - 119

Age Group3 : 119 - 159

Model| Age Group1 plda | Age Group1 SC | Age Group2 plda | Age Group2 SC | Age Group3 plda | Age Group3 SC |
-----|-----|-----|-----|-----|-----|-----|
Pretrained| (21.03, 12.36) | (14.56, 8.97) | (19.97, 14.89) | (12.07, 9.26) | (19.93, 14.21) | (13.11, 10.14) | 
model_a| (13.44, 8.095) | (11.78, 7.85) | (13.18, 9.02) | (11.09, 6.95) | (17.20, 13.87) | (12.86, 8.59) |
model_b| (12.03, 8.30) | (11.41, 7.47) | (14.66, 12.52) | (10.46, 6.90) |  (17.08 , 9.69) | (12.31, 9.35) |
model_c| (12.56, 8.43) | (11.67, 8.86) | (13.77, 11.11) | (11.69, 8.35) | (17.37, 14.52) | (12.54, 10.01) |
model_d| (12.76, 8.64) | (11.50, 8.24) | (14.00 , 11.86) | (11.52, 8.57) | (16.39, 13.74) | (12.15, 9.43) |
**model_pvDir**| (12.65, 8.14) | (11.03, 7.86) | (12.27, 8.18) | (9.84, 6.37) | (13.67, 11.13) | (12.03, 10.27) | 

## Gender Experiments

Again, the adosMod3 corpus has been classified into 2 categories, male and female. The same python script, filter.py was used for the same. The male speakers were annotated by the value 1 and the female speakers were annotated by the value 2 in the ageGenderIQ.sh file.

The models pretrained, a, b, c, d and the pitch variation model were used for evaluating the datasets. The results are tabulated below:

Model | Female PLDA | Female SC | Male PLDA | Male SC |
-----|-----|-----|-----|-----|
Pretrained| (21.26, 13.93) | (14.94, 10.40) | (19.47, 13.56) | (12.99, 9.04) |
model_a| (16.38, 11.29)| (13.00, 8.96) | (15.01, 11.46) | (11.44, 7.97) |
model_b| (14.90, 10.67) | (11.48, 7.62) | (14.63, 12.21) | (11.48, 8.07) |
model_c| (15.96, 11.28) | (12.31, 8.36) | (14.33, 11.84) | (11.86, 8.59) |
model_d| (14.37, 9.92) | (12.62, 9.05) | (14.37, 12.22) | (11.38, 8.12) |
model_pvDir| (14.64, 9.72) | (11.09, 8.23) | (12.46, 8.78) | (11.37, 8.76)|

## DER in the absence of Ground Truth

Instead of using the RTTM files, in this experiment a pre-trained model was used to create the voice activity regions. The DER results are expected to be higher than that of the ones where the ground truth RTTM files were used. The resuls are presented below:

Model | DIHARD PLDA| DIHARD SC | CARE PLDA | CARE SC | ADOSMod3 PLDA | ADOSMod3 SC |
------|------|------|------|------|-------|-------|
Pretrained| (54.00, 37.29) | (52.05, 36.44) | (47.02, 21.15) | (41.89, 19.47) | (53.49, 37.93) | (48.50, 36.77) |
model_b| (50.65, 38.09) | (50.85, 36.62) | (37.49, 18.52) | (34.64, 15.89) | (48.02, 36.84) | (48.97, 35.80) |
model_newb1| (49.18, 36.33) | (50.67, 37.32) | (40.14, 18.86) | (37.45, 20.43) | (48.30, 36.13) | (48.93, 36.02) |
model_newb2| (48.50, 36.77) | (51.11, 36.81) | (36.97, 17.40) | (37.50, 20.30) | (47.86, 37.31) | (49.01, 36.78) |
model_newb3| (50.72, 36.71) | (50.62, 35.51) | (39.64, 18.26) | (37.41, 20.35) | (48.45, 37.05) | (49.02, 37.00) |
model_newb4| (48.50, 36.12) | (51.18, 36.89) | (38.46, 18.64) | (36.10, 19.51) | (47.83, 37.48) | (49.04, 35.97) |
model_pvDir| (50.56, 37.99) | (50.41, 36.57) | (38.07, 18.69) | (32.60, 13.86) | (48.19, 37.47) | (49.15, 36.09) |

The relative imrpovement in the PLDA DER values between the pretrained and the best model are 10.19% for the DIHARD corpus, 21.37% for the CARE corpus and 10.58% for the ADOSMod3 corpus. The improvement decreased from 22.88%, nearly 45% and 33.7% for the respective corpora when the RTTM files were used to generate regions of speech activity. 
