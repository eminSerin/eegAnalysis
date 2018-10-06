# v1.0
EEG preprocessing pipeline v1.0 for heartbeat evoked potentials analysis.

Preprocessing steps:

1. Resampling
2. Bandpass filtering (Different filters on EEG and ECG data)
3. Epoching
4. Channel interpolation (if necessary)
5. Reject epochs with artifact
6. ICA and component rejection
7. Reference to average
8. Segmentation regarding each condition and R-waves.

Since the minimum frequency of 0.5Hz is recommended for sufficent ICA performance 
(for detailed information; https://github.com/CSC-UW/csc-eeg-tools/wiki/Filtering-and-ICA), preprocessing v2.0 is recommended
for more precision. 
