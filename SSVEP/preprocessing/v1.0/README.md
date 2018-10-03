EEG preprocessing pipeline 1.0. 

Preprocessing steps: 
- Resampling
- Bandpass filtering 
- Channel interpolation (if necessary)
- Reference to average
- ICA and component rejection
- Epoching
- Reject epochs with artifact (based on Occipital electrodes)
- Segmentation for each condition
