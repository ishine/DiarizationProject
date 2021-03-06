#!/bin/bash


currDir=$PWD
kaldiDir=/X/kaldi
expDir=$currDir/exp_kaldi
wavDir=$currDir/wav
rttmDir=$currDir/rttm
wavList=$currDir/wavList
readlink -f $wavDir/* > $wavList

# Extraction parameters
window=1.5
window_period=0.75
min_segment=0.5
nnetDir=/X/MyST_material/dataprep/nnet/model_d
#nnetDir=/X/0007_voxceleb_v2_1a/exp/xvector_nnet_1a
transformDir=$nnetDir/xvectors_train/

# Evaluation parameters
method=SC # plda or SC (spectral clustering)
useOracleNumSpkr=1
useCollar=0
skipDataPrep=0
dataDir=$expDir/data
nj=8

if [[ "$method" == "SC" ]] && [[ ! -d Auto-Tuning-Spectral-Clustering ]]; then
  echo "Please install https://github.com/tango4j/Auto-Tuning-Spectral-Clustering"
  exit 1
fi

for f in sid steps utils local conf diarization; do
  [ ! -L $f ] && ln -s /X/MyST_material/dataprep/$f;
done
#exit 0
if [[ "$useCollar" == "1" ]]; then
  collarCmd="--collar 0.25 --ignore_overlaps"
else
  collarCmd="--ignore_overlaps"
fi

. cmd.sh
. path.sh

# Kaldi directory preparation
if [ "$skipDataPrep" == "0" ]; then

  rm -rf $dataDir; mkdir -p $dataDir
  paste -d ' ' <(rev $wavList | cut -f 1 -d '/' | rev | sed "s/\.wav$/-rec/g") \
    <(cat $wavList | xargs readlink -f) > $dataDir/wav.scp
  paste -d ' ' <(cut -f 1 -d ' ' $dataDir/wav.scp | sed "s/-rec$//g") \
    <(cut -f 1 -d ' ' $dataDir/wav.scp | sed "s/-rec$//g") > $dataDir/utt2spk
  cp $dataDir/utt2spk $dataDir/spk2utt
  numUtts=`wc -l $dataDir/utt2spk | cut -f 1 -d ' '`
  paste -d ' ' <(cut -f 1 -d ' ' $dataDir/utt2spk) \
    <(cut -f 1 -d ' ' $dataDir/wav.scp) <(yes "0" | head -n $numUtts) <(cat $wavList | xargs soxi -D) \
    >  $dataDir/segments
  for rttmFile in $rttmDir/*.rttm; do
    n=`cut -f 8 -d ' ' $rttmFile | sort | uniq | wc -l`
    echo "`basename $rttmFile .rttm` $n" >> $dataDir/reco2num_spk
  done

  # Create VAD directory
  echo "Creating VAD files.."
  python pytorch_xvectors/egs/convert_rttm_to_vad.py $wavDir $rttmDir $expDir/oracleVAD
  while read -r line; do
      uttID=`echo $line | cut -f 1 -d ' '`
      inVadFile=$expDir/oracleVAD/$uttID.csv # this change yet to be verified
      [ ! -f $inVadFile ] && { echo "Input vad file does not exist"; exit 0; }
      paste -d ' ' <(echo $uttID) <(cut -f 2 -d ',' $inVadFile | tr "\n" " " | sed "s/^/ [ /g" | sed "s/$/ ]/g") >> $dataDir/vad.txt
  done < $dataDir/utt2spk
  copy-vector ark,t:$dataDir/vad.txt ark,scp:$dataDir/vad.ark,$dataDir/vad.scp
  echo "Done"


  # Feature preparation pipeline, until train_combined_no_sil
  utils/fix_data_dir.sh $dataDir
  steps/make_mfcc.sh --nj $nj \
                 --cmd "$train_cmd" \
                 --mfcc-config conf/mfcc.conf \
                 --write-utt2num-frames true \
                 $dataDir || exit 1
  utils/fix_data_dir.sh $dataDir

  diarization/vad_to_segments.sh --nj $nj \
                 --cmd "$train_cmd" \
                 --segmentation-opts '--silence-proportion 0.01001' \
                 --min-duration 0.5 \
                 $dataDir $dataDir/segmented || exit 1

  local/nnet3/xvector/prepare_feats_for_egs.sh --nj $nj \
                 --cmd "$train_cmd" \
                 $dataDir/segmented \
                 $dataDir/segmented_cmn \
                 $dataDir/segmented_cmn/feats || exit 1
  cp $dataDir/segmented/segments $dataDir/segmented_cmn/segments
  utils/fix_data_dir.sh $dataDir/segmented_cmn
  utils/split_data.sh $dataDir/segmented_cmn $nj

  # Use extract.py or kaldi's extract_xvectors.sh
  diarization/nnet3/xvector/extract_xvectors.sh --nj $nj \
               --cmd "$train_cmd --mem 5G" \
               --window $window \
               --period $window_period \
               --apply-cmn false \
               --min-segment $min_segment \
               $nnetDir \
               $dataDir/segmented_cmn \
               $dataDir/kaldi_xvectors/

else
  [ ! -f $dataDir/kaldi_xvectors/xvector.scp ] && echo "Cannot find features" && exit 1;
fi

if [ "$method" == "plda" ]; then

  diarization/nnet3/xvector/score_plda.sh --nj $nj \
               --cmd "$train_cmd" \
               $transformDir \
               $dataDir/kaldi_xvectors \
               $expDir/plda/scoring

  diarization/cluster.sh --nj $nj \
               --cmd "$train_cmd --mem 5G" \
               --reco2num-spk $dataDir/reco2num_spk \
               $expDir/plda/scoring \
               $expDir/plda/clustering_oracleNumSpkr


else

  # Compute the cosine affinity
  cd Auto-Tuning-Spectral-Clustering/sc_utils
  bash score_embedding.sh --cmd "$train_cmd" --nj 6 \
               --python_env ~/virtualenv/keras_fixed/bin/activate \
               --score_metric cos --out_dir $expDir/SC/cos_scores  \
               $dataDir/kaldi_xvectors $expDir/SC/cos_scores
  cd ..

  # Perform spectral clustering
  python spectral_opt.py --affinity_score_file $expDir/SC/cos_scores/scores.scp \
               --threshold 'None' --score_metric "cos" --max_speaker 10 \
               --spt_est_thres 'NMESC' --reco2num_spk $dataDir/reco2num_spk \
               --segment_file_input_path $dataDir/kaldi_xvectors/segments \
               --spk_labels_out_path $expDir/SC/labels_oracleNumSpkr \
               --sparse_search True
  mkdir -p $expDir/SC/clustering_oracleNumSpkr 

 sc_utils/make_rttm.py $dataDir/kaldi_xvectors/segments $expDir/SC/labels_oracleNumSpkr $expDir/SC/clustering_oracleNumSpkr/rttm 
  
cd ..

fi


# Evaluation

sed -i "s/-rec//g" $expDir/$method/clustering_oracleNumSpkr/rttm

cd dscore/
oracleResults=`python score.py $collarCmd -u /X/DIHARD/all.uem -R <(ls $rttmDir/*) \
  -S <(ls $expDir/$method/clustering_oracleNumSpkr/rttm) |\
  grep OVERALL | tr -s ' ' | cut -f 4-5 -d ' '`

python score.py $collarCmd -u /X/DIHARD/all.uem -R <(ls $rttmDir/*) \
  -S <(ls $expDir/$method/clustering_oracleNumSpkr/rttm) > $currDir/temp

# Beginning of my code contributions

meanDER=`awk -F ' ' '{sum+=$2;} END{print sum/(NR-3)}' $currDir/temp`
stdDER=`awk -v var=$meanDER '{ssq+=($2 - var)^2} END { print sqrt(ssq / (NR-3)); }' $currDir/temp`
echo $meanDER 
cd ..

echo "Mean DER with Oracle #Spkrs: `echo $oracleResults | cut -f 1 -d ' '`"
echo "STD DER with Oracle #Spkrs: `echo $stdDER`"


rm $wavList

# End of my code contributions
