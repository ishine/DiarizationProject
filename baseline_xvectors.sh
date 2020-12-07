#!/bin/bash

: ' Date created: Jul 7 2018

This script performs diarization using x-vectors as feature representations (https://david-ryan-snyder.github.io/2017/10/04/model_sre16_v2.html). Initially, this will be a wrapper for the default pipeline as provided in kaldi/egs/callhome_diairzation/v2/run.sh (xvectors -> plda -> AHC). 

The PLDA model used in this script is NOT provided as part of the x-vector model and must be created following prepare.sh

Later, viterbi re-alignment might be explored '


# Inputs:
corpus=multiSite                        # 'multiSite' or 'BOSCChigh'
xvectorType=voxceleb
kaldiDir=/home/coder/kaldi/
callhomeDir=$kaldiDir/egs/callhome_diarization/v2/
voxcelebDir=$kaldiDir/egs/voxceleb/v2/
threshold=0
mystDir=/home/coder/suchitra/MyST_material/dataprep
if [ "$xvectorType" == "callhome" ]; then
	nnet_dir=$callhomeDir/exp/xvector_nnet_1a/
	transform_dir=$nnet_dir/../xvectors_sre_combined
else
	#nnet_dir=$mystDir/nnet/model_a
	nnet_dir=$voxcelebDir/exp/xvector_nnet_1a
	transform_dir=$nnet_dir/xvectors_train/
fi

#echo ${nnet_dir}
# Other params
currDir=$PWD
#echo $currDir
wavList=newwavlist			# File with list of audio files to be diarized
inputVADDir=oracleVAD_$corpus            # Directory with VAD files; labels@frame-level every line
inputRttmDir=../rttm
if [[ $inputVADDir == "oracle"* ]]; then
	expDir=$currDir/expDir_${corpus}_${xvectorType}_new
	outDiarDir=$currDir/diarDir_${corpus}_${xvectorType}_new
else
	expDir=$currDir/expDir_${corpus}_${xvectorType}_der
	outDiarDir=$currDir/diarDir_${corpus}_${xvectorType}_der
fi
#echo $expDir

rm -rf $expDir; mkdir $expDir
rm -rf $outDiarDir; mkdir $outDiarDir

#cd $callhomeDir
. cmd.sh
. path.sh
#cd $currDir


# Create kaldi directory
paste -d ' ' <(rev $wavList | cut -f 1 -d '/' | rev | sed "s/\.wav$/-rec/g") <(cat $wavList | xargs readlink -f) > $expDir/wav.scp
paste -d ' ' <(cut -f 1 -d ' ' $expDir/wav.scp | sed "s/-rec$//g") <(cut -f 1 -d ' ' $expDir/wav.scp | sed "s/-rec$//g") > $expDir/utt2spk
cp $expDir/utt2spk $expDir/spk2utt
numUtts=`wc -l $expDir/utt2spk | cut -f 1 -d ' '`
paste -d ' ' <(cut -f 1 -d ' ' $expDir/utt2spk) <(cut -f 1 -d ' ' $expDir/wav.scp) <(yes "0" | head -n $numUtts) <(cat $wavList | xargs soxi -D) > $expDir/segments
paste -d ' ' <(rev $wavList | cut -f 1 -d '/' | rev | sed "s/\.wav$//g") <(yes "2" | head -n $numUtts) > $expDir/reco2num_spk


# Convert the supplied VAD into kaldi format and prepare the feats for x-vectors
while read -r line; do
	uttID=`echo $line | cut -f 1 -d ' '`
	inVadFile=$inputVADDir/$uttID.csv
	[ ! -f $inVadFile ] && { echo "Input vad file does not exist"; exit 0; }
	paste -d ' ' <(echo $uttID) <(cut -f 2 -d ',' $inVadFile | tr "\n" " " | sed "s/^/ [ /g" | sed "s/$/ ]/g") >> $expDir/vad.txt
done < $expDir/utt2spk
copy-vector ark,t:$expDir/vad.txt ark,scp:$expDir/vad.ark,$expDir/vad.scp
[ "$numUtts" -gt 8 ] && nj=8 || nj=1

if [ "$xvectorType" == "callhome" ]; then
	cd $callhomeDir
else
	cd $mystDir
fi

# Feature processing pipeline
utils/fix_data_dir.sh $expDir
cp conf/mfcc.conf temp_mfcc.conf

echo "--dither=0" >> temp_mfcc.conf	# Removing dither, and not disturbing contents in kaldi trunk
bash steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" --mfcc-config temp_mfcc.conf --write-utt2num-frames true $expDir/ > /dev/null
rm temp_mfcc.conf

diarization/vad_to_segments.sh --nj $nj --cmd "$train_cmd" --min-duration 0.5 --segmentation-opts '-silence-proportion 0.011' $expDir $expDir/segmented > /dev/null


# Following script seems to have been deleted after kaldi update
local/nnet3/xvector/prepare_feats_for_egs.sh --nj $nj --cmd "$train_cmd" $expDir/segmented $expDir/segmented_cmn $expDir/segmented_cmn/data > /dev/null
cp $expDir/segmented/segments $expDir/segmented_cmn

diarization/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 5G" --nj $nj --window 1 --period 0.25 --apply-cmn false --min-segment 0.5 $nnet_dir $expDir/segmented_cmn $expDir/xvectors/ > /dev/null

diarization/nnet3/xvector/score_plda.sh --cmd "$train_cmd" --nj $nj $transform_dir $expDir/xvectors $expDir/xvectors/plda_scoring > /dev/null

diarization/cluster.sh --reco2num-spk $expDir/reco2num_spk --cmd "$train_cmd --mem 5G" --nj 4 --threshold $threshold $expDir/xvectors/plda_scoring $expDir/xvectors/plda_scores_thresh_$threshold

cd $currDir
rm -f $currDir/temp_ders


# Evaluation
cut -f 2 -d ' ' $expDir/segments |\
while read -s wavid; do
	grep " $wavid " $expDir/xvectors/plda_scores_thresh_$threshold/rttm | sed "s/-rec//g" > $outDiarDir/$(echo $wavid | sed "s/-rec//g").rttm
	printf "%-30s" "$wavid: "
	perl /home/suchitra/kaldi/tools/sctk-2.4.10/bin/md-eval.pl -1 -c 0.25 \
		-r $inputRttmDir/$(echo $wavid | sed "s/-rec//g").rttm -s $outDiarDir/$(echo $wavid | sed "s/-rec//g").rttm 2>&1 |\
		grep "OVERALL" | cut -f 2 -d '=' || echo "Failure during eval"
	perl /home/suchitra/kaldi/tools/sctk-2.4.10/bin/md-eval.pl -1 -c 0.25 \
		-r $inputRttmDir/$(echo $wavid | sed "s/-rec//g").rttm -s $outDiarDir/$(echo $wavid | sed "s/-rec//g").rttm 2>&1 |\
		grep "OVERALL" | cut -f 7 -d ' ' >> $currDir/temp_ders
done 
meanDER=`awk '{sum += $1} END {print sum/NR}' $currDir/temp_ders`
stdDER=`awk -v var=$meanDER '{ssq+=($1 - var)^2} END { print sqrt(ssq / NR); }' $currDir/temp_ders`
echo "(Mean, Std) DER: ($meanDER, $stdDER)"
#rm -f $currDir/temp_ders
