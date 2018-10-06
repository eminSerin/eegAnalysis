EEG preprocessing pipeline v2.0 for heartbeat evoked potentials analysis.

Preprocessing steps:

Resampling
Bandpass filtering (Different filters on EEG and ECG data)
Epoching
Channel interpolation (if necessary)
Reject epochs with artifact
Reference to average
ICA on EEG data with highpass filter at 1 Hz. 
Copy ICA weights to original EEG data with high pass filter at 0.1 Hz 
Component rejection
Segmentation regarding each condition and R-waves.

The reason why we run ICA on data with highpass filter at 1Hz and copy the 
ICA weights to the original data is that ICA decomposition is not good on 
0.1Hz highpass filtered data. Minimum frequency of 0.5Hz is recommended for
sufficent ICA performance (for detail information; https://github.com/CSC-UW/csc-eeg-tools/wiki/Filtering-and-ICA). 