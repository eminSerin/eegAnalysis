# v2.0
EEG preprocessing pipeline v2.0 for heartbeat evoked potentials analysis.

Preprocessing steps:

1. Resampling
2. Bandpass filtering (Different filters on EEG and ECG data)
3. Epoching
4. Channel interpolation (if necessary)
5. Reject epochs with artifact
6. Reference to average
7. ICA on EEG data with highpass filter at 1 Hz. 
8. Copying ICA weights to original EEG data with high pass filter at 0.1 Hz 
9. Component rejection
10.Segmentation regarding each condition and R-waves.

The reason why we run ICA on data with highpass filter at 1Hz and copy the 
ICA weights to the original data is that ICA decomposition is not good on 
0.1Hz highpass filtered data. Minimum frequency of 0.5Hz is recommended for
sufficent ICA performance (for detailed information; https://github.com/CSC-UW/csc-eeg-tools/wiki/Filtering-and-ICA). 
