function [] = calc_TFSnr()
%%
% calc_TFSnr performs Time-frequency analysis on epoched EEG data using FFT
% and Morlet Wavelets and calculates signal to noise ratio for each
% frequency. Plots power density,SNR, and Time-frequency after calculations
% and saves figure as pdf file.
%
% calc_TFSnr function REQUIRES fieldtrip toolbox to perform such analyses.
% http://www.fieldtriptoolbox.org/start
%
% Use as: calc_TFSnr()
%
% Function pops up a window which you can select epoched EEG ".set" file
% you want to analyze (multiple file selection is also possible). 
%
% Parameters:
%
% cfg.foilim = [1 20]; % Frequency of interest.
% cfg.cfg.width = 12; % Window width used for Morlet Wavelets. 
% 
% noisebins = 10; % Number of neighboring bins on each side of frequency of
% interest. SNR for each frequency is calculated by dividing power of
% frequency of interest by average of 10 bins on each side of the FOI
% skipping the closest two bins.
%
% padbins = 2; % Number of padding bins.
%
% snr.freqRes = 1/20; % Frequency resolution used for SNR analysis. (0.05Hz
% in default)
%
% Hanning window function was used for frequency and time-frequency domain
% analyses. For more information:
% https://en.wikipedia.org/wiki/Window_function
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
[files, path] = uigetfile('.set','Please load .set eeg datafile',...
    'MultiSelect','on');

if ischar(files) 
    nfile = 1; 
else
    nfile = length(files); 
end

%% Import and convert eeg files. 
for t = 1 : nfile
    if nfile ~= 1
        cfile = files{t};
    else
        cfile = files;
    end
    
    outputfilename = cfile(1:end-4); % output file name. 
    % Load current data file.
    data = pop_loadset(cfile,path);
    
    % Choose occipital channels.
    data = pop_select(data,'channel',{'PO7' 'PO3' 'O1' 'Oz' 'POz' 'PO8' 'PO4' 'O2'});
    
    % Convert eeglab to fieldtrip data structure.
    data = eeglab2fieldtrip(data,'preprocessing');
    
    %% Short-window fourier transform (frequency analysis).
    
    % set fieldtrip parameters.
    cfg = [];
    cfg.output = 'pow'; % output as power.
    cfg.method = 'mtmfft'; % FFT method which uses tapers.
    cfg.taper = 'hanning'; % Hanning taper method (single taper).
    cfg.foilim = [2 20]; % frequency band of interest
    
    % Frequency analysis
    ft(t).swfft = ft_freqanalysis(cfg,data);
    
    %% Convolution method. (time-frequency)
    
    % Set fieldtrip parameters. cfg = []; cfg.output = 'pow'; % output as
    % power. cfg.method = 'mtmconvol'; % FFT method which uses tapers.
    % cfg.taper = 'hanning'; % Hanning taper method (single taper). cfg.foi
    % = [2:0.1:20]; % frequency band of interest cfg.t_ftimwin =
    % 12./cfg.foi; % cycles per time window. cfg.toi = -2:0.05:10.9; % time
    % of interest.
    %
    % % run time-frequency analysis ft.mtconvol =
    % ft_freqanalysis(cfg,data);
    
    %% Morlet Wavelet method.
    
    % Set fieldtrip parameters.
    cfg = [];
    cfg.method = 'wavelet'; % FFT method which uses tapers.
    cfg.output = 'pow'; % output as power.
    cfg.foilim = [2 20]; % frequency band of interest
    cfg.width = 7; % Morlet window width.
    cfg.toi = -2:0.05:11.9;
    
    % Frequency analysis
    ft(t).morlet = ft_freqanalysis(cfg,data);
    
    %% Signal-to-noise ratio analysis.
    
    % Set snr parameters
    snr.noisebins = 10; % neighboring bins.
    snr.padbins = 2; % number of closest neighbors.
    snr.freqRes = 1/50; % frequency resolution.
    snr.data = ft(t).swfft;
    
    % Calculate SNR for all channels.
    if ndims(snr.data.powspctrm) == 2
        % Make data structure 3D if 2D.
        snr.data.powspctrm = permute(snr.data.powspctrm, [3, 1, 2]);
    end
    
    snr.snr = zeros(size(snr.data.powspctrm));
    for trial = 1:size(snr.data.powspctrm, 1)
        for i = 1:numel(snr.data.freq)
            
            % current frequency.
            cFreq = snr.data.freq(i);
            
            % calculate signal to noise
            stimband = snr.data.freq > cFreq - snr.freqRes &...
                snr.data.freq  < cFreq + snr.freqRes;
            noiseband = ~((snr.data.freq  > cFreq - snr.padbins * snr.freqRes) &...
                (snr.data.freq  < cFreq + snr.padbins * snr.freqRes)) & ...
                snr.data.freq  > cFreq - snr.noisebins * snr.freqRes &...
                snr.data.freq  < cFreq + snr.noisebins * snr.freqRes;
            
            % Calculate SNR and store it in the structure
            ft(t).snr.snr(trial, :, i) = mean(snr.data.powspctrm(trial, :, stimband), 3)./...
                mean(snr.data.powspctrm(trial, :, noiseband), 3);
        end
    end
    
    % Squeze 3D into 2D back.
    ft(t).snr.snr = squeeze(ft(t).snr.snr);
    
    % Make the beginning and end NaNs because they don't have any
    % neighbours
    ft(t).snr.snr(:, 1 : snr.noisebins) = NaN;
    ft(t).snr.snr(:, end - snr.noisebins : end) = NaN;
    
    % Frequencies for snr. 
    ft.snr.freq = snr.data.freq;
    %% Plot Data.
    
    % Plot PSD.
    fig = figure;
    subplot(2,2,1);
    plot(ft.swfft.freq,mean((ft.swfft.powspctrm),1))
    xlim(cfg.foilim)
    set(gca,'XTick',(cfg.foilim(1):1:cfg.foilim(2)))
    ymax = ceil(max(mean(ft.swfft.powspctrm,1)));
    ylim([-0.2 ymax+ymax/10]);
    set(gca,'YTick',(-0.2:ymax/10:ymax+ymax/10))
    xlabel('Freq(Hz)','FontSize',10);
    ylabel('Amplitude (mV^2)','FontSize',10);
    title('Power Spectrum Density (mean Occipital Channels)',...
        'FontSize', 8);
    
    % Plot Time-frequency domain
    subplot(2,2,[3 4])
    cfg.baseline = [-2 0];
    cfg.title = 'Time-frequency in dB using Morlet Wavelets(mean Occipital Channels)';
    cfg.ylim = cfg.foilim;
    cfg.xlim = [0 10];
    cfg.zlim = [0 4];
    cfg.interactive = 'no';
    cfg.baselinetype = 'db';
    cfg.maskstyle = 'saturation';
    ft_singleplotTFR(cfg,ft.morlet)
    set(gca,'YTick',(cfg.foilim(1):2:cfg.foilim(2)))
    ylabel('Hz', 'FontSize',10);
    xlabel('Time', 'FontSize',10);
    
    % Plot SNR.
    subplot(2,2,2)
    plot(snr.data.freq,mean(ft(t).snr.snr,1))
    xlim(cfg.foilim)
    set(gca,'XTick',(cfg.foilim(1):1:cfg.foilim(2)))
    ymax = ceil(max(mean(ft(t).snr.snr,1)));
    ylim([0.2 ymax+ymax/10])  ;
    set(gca,'YTick',(0.2:ymax/10:ymax))
    xlabel('Freq(Hz)', 'FontSize',10);
    ylabel('SNR', 'FontSize',10);
    title('Signal to noise ratio (mean Occipital Channels)',...
        'FontSize', 10);
    fig.PaperPositionMode = 'manual';
    orient(fig,'landscape')
    print(fig,'-dpdf', [path outputfilename,'_fieldtrip','.pdf'])
end
end
