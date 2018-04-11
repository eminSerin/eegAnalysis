function [] = calc_MTFFTSnr()
%%
% calc_MTFFTSnr performs Fast Fourier Transformation on epoched EEG data
% using taper and calculates signal to noise ratio for each frequency.
% Plots power density and SNR after calculations and saves figure as pdf
% file.
% 
% calc_MTFFTSnr function REQUIRES fieldtrip toolbox to perform taper FFT. 
% http://www.fieldtriptoolbox.org/start
% 
% Use as:
% calc_MTFFTSnr()
% 
% Function pops up a window which you can select epoched EEG ".set" file
% you want to analyze. Uses only occipital channels and performs 1Hz -
% 100Hz band pass filter after FFT.
%
% Parameters:
%
% data.ft.cfg.foilim = [1 100]; % Bandpass filter parameter. 
%
% noisebins = 10; % Number of neighboring bins on each side of frequency of
% interest. SNR for each frequency is calculated by dividing power of
% frequency of interest by average of 10 bins on each side of the FOI
% skipping the closest two bins. 
%
% padbins = 2; % Number of padding bins.
%
% data.ft.cfg.tapsmofrq = 1/50; % Frequency resolution used in FFT and SNR
% analysis. (0.02Hz in default)
%
% data.ft.cfg.taper = 'hanning'; % Window function used in FFT. For more
% information: https://en.wikipedia.org/wiki/Window_function
%
% Reference for SNR analysis: 
%
% Rossion, B., Boremanse, A., 2011. Robust sensitivity to facial identity
% in the right human occipito-temporal cortex as revealed by steady-state
% visual-evoked potentials. J. Vision 11 (2), 16, 1–21.
%
%Srinivasan R. Russell D. P. Edelman G. M. Tononi G. (1999). Increased
%synchronization of neuromagnetic responses during conscious perception.
%Journal of Neuroscience, 19, 5435–5448
%
%
% Author: Emin Serin / Berlin School of Mind and Brain / 2018. 

%% Pre-FFT

% Load eeglab set file.
[file, path] = uigetfile('.set');
while file == 0
    disp('Please load .set file')
    [file, path] = uigetfile;
end
EEG = pop_loadset(file,path);

% Choose occipital channels.
EEG = pop_select( EEG,'channel',{'PO7' 'PO3' 'O1' 'Oz' 'POz' 'PO8' 'PO4' 'O2'});

% Convert eeglab to fieldtrip data structure. 
data.ft = eeglab2fieldtrip(EEG,'preprocessing');


%% FFT and SNR analysis. 
% Set fieldtrip parameters. 
data.ft.cfg.method = 'mtmfft'; % FFT method which uses tapers. 
data.ft.cfg.output = 'pow'; % output as power. 
data.ft.cfg.pad = 'nextpow2'; % rounds the maximum trial length up to the next power of 2.
data.ft.cfg.taper = 'hanning'; % Hanning taper method. 
data.ft.cfg.foilim = [1, 100]; % frequency band of interest
data.ft.cfg.tapsmofrq = 1/50; % frequency resolution. 

% Set snr parameters
snr.noisebins = 10; % neighboring bins.
snr.padbins = 2; % number of closest neighbors.
snr.freqRes = data.ft.cfg.tapsmofrq; % frequency resolution.

% Frequency analysis
% Fieldtrip Multitrap FFT function.
data.fft = ft_freqanalysis(data.ft.cfg,data.ft);

% Calculate SNR for all channels. 
if ndims(data.fft.powspctrm) == 2
    % Make data structure 3D if 2D. 
    data.fft.powspctrm = permute(data.fft.powspctrm, [3, 1, 2]);
end

data.snr = zeros(size(data.fft.powspctrm));
for trial = 1:size(data.fft.powspctrm, 1)
    for i = 1:numel(data.fft.freq)

        % current frequency.
        cFreq = data.fft.freq(i);

        % calculate signal to noise
        stimband = data.fft.freq > cFreq - snr.freqRes &...
                   data.fft.freq < cFreq + snr.freqRes;
        noiseband = ~((data.fft.freq > cFreq - snr.padbins * snr.freqRes) &...
                      (data.fft.freq < cFreq + snr.padbins * snr.freqRes)) & ...
                    data.fft.freq > cFreq - snr.noisebins * snr.freqRes &...
                    data.fft.freq < cFreq + snr.noisebins * snr.freqRes;

        % Calculate SNR and store it in the structure
        data.snr(trial, :, i) = mean(data.fft.powspctrm(trial, :, stimband), 3)./...
                                mean(data.fft.powspctrm(trial, :, noiseband), 3);
    end
end

% Squeze 3D into 2D back. 
data.snr = squeeze(data.snr);
data.fft.powspctrm = squeeze(data.fft.powspctrm);
% Make the beginning and end NaNs because they don't have any neighbours
data.snr(:, 1 : snr.noisebins) = NaN;
data.snr(:, end - snr.noisebins : end) = NaN;


%% Plot Data.

% Plot PSD. 
figure;
subplot(2,1,1);
plot(data.fft.freq,data.fft.powspctrm)
xlim([2 45])
set(gca,'XTick',(2:1:45))
ylim([0 ceil(max(max(data.fft.powspctrm)))])  ;
set(gca,'YTick',(0:1:ceil(max(max(data.fft.powspctrm)))))
xlabel('Freq(Hz)');
ylabel('PSD');
title('Power Spectrum Density (Occipital Channels) using fieldtrip');

% Plot SNR. 
subplot(2,1,2)
plot(data.fft.freq,data.snr)
xlim([2 45])
set(gca,'XTick',(2:1:45))
ylim([0 ceil(max(max(data.snr)))])  ;
set(gca,'YTick',(0:1:ceil(max(max(data.snr)))))
xlabel('Freq(Hz)');
ylabel('SNR');
title('Signal to noise ratio (Occipital Channels) using fieldtrip');

end
