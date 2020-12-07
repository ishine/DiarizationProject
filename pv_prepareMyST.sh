#!/bin/bash

cd /home/coder/suchitra/MyST_material


mkdir pvDir

#Introducing Pitch Variations between 0.9 to 1.1 times the orginal frequency
PV=1
cent_low=-182
cent_high=174
upper_limit=( $cent_high - $cent_low + 1 )

stage=0

dataDir=/home/coder/suchitra/MyST_material/myst/myst-v0.3.0-171fbda/corpora/myst/data
newDir=/home/coder/suchitra/MyST_material/pvDir
kaldiDir=/home/coder/kaldi/egs/voxceleb/v2/
musan_root=/home/coder/Datasets/musan

if [ $stage -le 1 ]; then
cd $dataDir

find "$(pwd)" -name "*.wav" > $newDir/wavlist

cd $newDir

ln -s $kaldiDir/utils $newDir/utils
ln -s $kaldiDir/steps $newDir/steps
ln -s $kaldiDir/sid $newDir/sid
ln -s $kaldiDir/local $newDir/local

mkdir exp
mkdir conf
mkdir data

cp $kaldiDir/path.sh $newDir
cp $kaldiDir/cmd.sh $newDir
cp $kaldiDir/conf/mfcc.conf $newDir/conf
cp $kaldiDir/conf/vad.conf $newDir/conf

. cmd.sh
. path.sh

cd data
mkdir train

cd ..
 
#kaldi Directory
paste -d ' ' <(rev wavlist | cut -f 1 -d '/' | rev | sed "s/\.wav$/-rec/g") <(cat wavlist | xargs readlink -f) > $newDir/data/train/wav.scp

numWavFiles=`wc -l $newDir/data/train/wav.scp | cut -f 1 -d ' '`

#echo $numWavFiles

if [ $PV == 1 ] ; then

 for i in {1..5}; do

    for num in $(seq 1 $numWavFiles); do
         echo $((RANDOM % $((cent_high-cent_low+1)) + $cent_low)) >> $newDir/data/train/randomCent_$i
    done

    paste -d ' ' <(cut -f 1 -d ' ' $newDir/data/train/wav.scp | sed "s~^~PV$i-~g" ) <(yes " sox -G -D -t wav " | head -n$numWavFiles) <(cut -f 2 -d ' ' $newDir/data/train/wav.scp) <(yes " -t wav - pitch " | head -n$numWavFiles) $newDir/data/train/randomCent_$i  <(yes " |" | head -n$numWavFiles) >> $newDir/data/train/newwav.scp

 done

   cat $newDir/data/train/newwav.scp >> $newDir/data/train/wav.scp
 
   paste -d ' ' <(cut -f 1 -d ' ' $newDir/data/train/wav.scp | sed "s/-rec$//g") <(awk -F '_' '{print $1 "_" $2}' $newDir/data/train/wav.scp) > $newDir/data/train/utt2spk

   utils/utt2spk_to_spk2utt.pl $newDir/data/train/utt2spk > $newDir/data/train/spk2utt
   
   paste -d ' ' <(cut -f 9 -d ' ' $newDir/data/train/newwav.scp) >> $newDir/wavlist

   numUtts=`wc -l $newDir/data/train/utt2spk | cut -f 1 -d ' '`

   paste -d ' ' <(cut -f 1 -d ' ' $newDir/data/train/utt2spk) <(cut -f 1 -d ' ' $newDir/data/train/wav.scp) <(yes "0" | head -n $numUtts) <(cat wavlist | xargs soxi -D) > $newDir/data/train/segments1

   awk '$4 == "0.000000" {next} {print}' "$newDir/data/train/segments1" >> $newDir/data/train/segments

   rm $newDir/data/train/segments1 $newDir/data/train/newwav.scp $newDir/data/train/randomCent_* 

else
  
   paste -d ' ' <(cut -f 1 -d ' ' $newDir/data/train/wav.scp | sed "s/-rec$//g") <(awk -F '_' '{print $1 "_" $2}' $newDir/data/train/wav.scp) > $newDir/data/train/utt2spk

   utils/utt2spk_to_spk2utt.pl $newDir/data/train/utt2spk > $newDir/data/train/spk2utt

   numUtts=`wc -l $newDir/data/train/utt2spk | cut -f 1 -d ' '`

   paste -d ' ' <(cut -f 1 -d ' ' $newDir/data/train/utt2spk) <(cut -f 1 -d ' ' $newDir/data/train/wav.scp) <(yes "0" | head -n $numUtts) <(cat wavlist | xargs soxi -D) > $newDir/data/train/segments1

   awk '$4 == "0.000000" {next} {print}' "$newDir/data/train/segments1" >> $newDir/data/train/segments

   rm $newDir/data/train/segments1

fi


utils/fix_data_dir.sh $newDir/data/train
utils/validate_data_dir.sh --no-text --no-feats $newDir/data/train


#mfcc/vad/cmvn feature extraction
mfccdir=mfcc
vaddir=vad
steps/make_mfcc.sh --cmd "$train_cmd" --nj 6 data/train exp/make_mfcc/data/train $mfccdir
steps/compute_cmvn_stats.sh data/train exp/make_mfcc/data/train $mfccdir
sid/compute_vad_decision.sh --nj 6 --cmd "$train_cmd" data/train exp/make_vad/data/train $vaddir

utils/fix_data_dir.sh $newDir/data/train

fi
#stage 2-10 of run.sh with minor modifications to maintain compatability of recording id

if [ $stage -le 2 ]; then
  frame_shift=0.01
  awk -v frame_shift=$frame_shift '{print $1, $2*frame_shift;}' data/train/utt2num_frames | awk -F ' ' '{print $1"-rec " $2}' > data/train/reco2dur #adding an extra rec print to make it compatible because the recording id and the utterance id are not the same

  if [ ! -d "RIRS_NOISES" ]; then
    # Download the package that includes the real RIRs, simulated RIRs, isotropic noises and point-source noises
    wget --no-check-certificate http://www.openslr.org/resources/28/rirs_noises.zip
    unzip rirs_noises.zip
  fi

  # Make a version with reverberated speech
  rvb_opts=()
  rvb_opts+=(--rir-set-parameters "0.5, RIRS_NOISES/simulated_rirs/smallroom/rir_list")
  rvb_opts+=(--rir-set-parameters "0.5, RIRS_NOISES/simulated_rirs/mediumroom/rir_list")

  # Make a reverberated version of the VoxCeleb2 list.  Note that we don't add any
  # additive noise here.

  steps/data/reverberate_data_dir.py \
      "${rvb_opts[@]}" \
      --speech-rvb-probability 1 \
      --pointsource-noise-addition-probability 0 \
      --isotropic-noise-addition-probability 0 \
      --num-replications 1 \ 
      --source-sampling-rate 16000 \
      data/train data/train_reverb
    cp data/train/vad.scp data/train_reverb/
    utils/copy_data_dir.sh --utt-suffix "-reverb" data/train_reverb data/train_reverb.new
    rm -rf data/train_reverb
    mv data/train_reverb.new data/train_reverb


  # Prepare the MUSAN corpus, which consists of music, speech, and noise
  # suitable for augmentation.
  steps/data/make_musan.sh --sampling-rate 16000 $musan_root data

  # Get the duration of the MUSAN recordings.  This will be used by the
  # script augment_data_dir.py.
  for name in speech noise music; do
    utils/data/get_utt2dur.sh data/musan_${name}
    mv data/musan_${name}/utt2dur data/musan_${name}/reco2dur
  done

# Augment with musan_noise
  steps/data/augment_data_dir.py --utt-suffix "noise" --fg-interval 1 --fg-snrs "15:10:5:0" --fg-noise-dir "data/musan_noise" data/train data/train_noise
  # Augment with musan_music
  steps/data/augment_data_dir.py --utt-suffix "music" --bg-snrs "15:10:8:5" --num-bg-noises "1" --bg-noise-dir "data/musan_music" data/train data/train_music
  # Augment with musan_speech
  steps/data/augment_data_dir.py --utt-suffix "babble" --bg-snrs "20:17:15:13" --num-bg-noises "3:4:5:6:7" --bg-noise-dir "data/musan_speech" data/train data/train_babble
#TRIAL 1: CHANGED ALL -rec-aug to -aug-rec and added -reverb-rec 
  # Combine reverb, noise, music, and babble into one directory.
  utils/combine_data.sh data/train_aug data/train_reverb data/train_noise data/train_music data/train_babble
fi

if [ $stage -le 3 ]; then
  # Take a random subset of the augmentations
  

  utils/subset_data_dir.sh data/train_aug 1440306 data/train_aug_1.5m
  utils/fix_data_dir.sh data/train_aug_1.5m

  # Make MFCCs for the augmented data.  Note that we do not compute a new
  # vad.scp file here.  Instead, we use the vad.scp from the clean version of
  # the list.
  steps/make_mfcc.sh --mfcc-config conf/mfcc.conf --nj 6 --cmd "$train_cmd" \
    data/train_aug_1.5m exp/make_mfcc $mfccdir

  # Combine the clean and augmented VoxCeleb2 list.  This is now roughly
  # double the size of the original clean list.
  
### used a python file(select.py) to take a subset of the adult speakers (clean+augmented) to match the number of speakers  and utterances of the children; have the tweak the values in the python file to get desired result OR use utils/subset_data_dir.sh to select speaker based on given utterance number, which is also trial and error as it will choose randomltterance number, which is also trial and error as it will choose randomlyy
  utils/combine_data.sh data/train_combined data/train_aug_1.5m data/train data/train_combined_adult
fi

if [ $stage -le 4 ]; then
  # This script applies CMVN and removes nonspeech frames.  Note that this is somewhat
  # wasteful, as it roughly doubles the amount of training data on disk.  After
  # creating training examples, this can be removed.####how is it wasteful?
  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 6 --cmd "$train_cmd" \
    data/train_combined data/train_combined_no_sil exp/train_combined_no_sil
  utils/fix_data_dir.sh data/train_combined_no_sil
fi

if [ $stage -le 5 ]; then
  # Now, we need to remove features that are too short after removing silence
  # frames.  We want atleast 5s (500 frames) per utterance.
  min_len=300
  mv data/train_combined_no_sil/utt2num_frames data/train_combined_no_sil/utt2num_frames.bak
  awk -v min_len=${min_len} '$2 > min_len {print $1, $2}' data/train_combined_no_sil/utt2num_frames.bak > data/train_combined_no_sil/utt2num_frames
  utils/filter_scp.pl data/train_combined_no_sil/utt2num_frames data/train_combined_no_sil/utt2spk > data/train_combined_no_sil/utt2spk.new
  mv data/train_combined_no_sil/utt2spk.new data/train_combined_no_sil/utt2spk
  
  utils/fix_data_dir.sh data/train_combined_no_sil

  # We also want several utterances per speaker. Now we'll throw out speakers
  # with fewer than 8 utterances.
  min_num_utts=8
  awk '{print $1, NF-1}' data/train_combined_no_sil/spk2utt > data/train_combined_no_sil/spk2num
  awk -v min_num_utts=${min_num_utts} '$2 >= min_num_utts {print $1, $2}' data/train_combined_no_sil/spk2num | utils/filter_scp.pl - data/train_combined_no_sil/spk2utt > data/train_combined_no_sil/spk2utt.new
  mv data/train_combined_no_sil/spk2utt.new data/train_combined_no_sil/spk2utt
  utils/spk2utt_to_utt2spk.pl data/train_combined_no_sil/spk2utt > data/train_combined_no_sil/utt2spk

  utils/filter_scp.pl data/train_combined_no_sil/utt2spk data/train_combined_no_sil/utt2num_frames > data/train_combined_no_sil/utt2num_frames.new
  mv data/train_combined_no_sil/utt2num_frames.new data/train_combined_no_sil/utt2num_frames
  rm data/train_combined_no_sil/wav.scp #may create problems with fix_data_dir.sh
  # Now we're ready to create training examples.
  utils/fix_data_dir.sh data/train_combined_no_sil
fi

# Stages 6 through 8 are handled in run_xvector.sh
local/nnet3/xvector/run_xvector.sh --stage $stage --train-stage -1 \
  --data data/train_combined_no_sil --nnet-dir $nnet_dir \
  --egs-dir $nnet_dir/egs

if [ $stage -le 9 ]; then
  # Extract x-vectors for centering, LDA, and PLDA training.
  sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 4G" --nj 80 \
    $nnet_dir data/train_combined_no_sil \
    $nnet_dir/xvectors_train
fi

if [ $stage -le 10 ]; then
  # Compute the mean vector for centering the evaluation xvectors.
  $train_cmd $nnet_dir/xvectors_train/log/compute_mean.log \
    ivector-mean scp:$nnet_dir/xvectors_train/xvector.scp \
    $nnet_dir/xvectors_train/mean.vec || exit 1;

  # This script uses LDA to decrease the dimensionality prior to PLDA.
  lda_dim=200
  $train_cmd $nnet_dir/xvectors_train/log/lda.log \
    ivector-compute-lda --total-covariance-factor=0.0 --dim=$lda_dim \
    "ark:ivector-subtract-global-mean scp:$nnet_dir/xvectors_train/xvector.scp ark:- |" \
    ark:data/train_combined_no_sil/utt2spk $nnet_dir/xvectors_train/transform.mat || exit 1;

  # Train the PLDA model.
  $train_cmd $nnet_dir/xvectors_train/log/plda.log \
    ivector-compute-plda ark:data/train_combined_no_sil/spk2utt \
    "ark:ivector-subtract-global-mean scp:$nnet_dir/xvectors_train/xvector.scp ark:- | transform-vec $nnet_dir/xvectors_train/transform.mat ark:- ark:- | ivector-normalize-length ark:-  ark:- |" \
    $nnet_dir/xvectors_train/plda || exit 1;
fi

##EVALUATION
