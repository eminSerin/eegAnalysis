function [] = calculate_fftSNR()
%%
% calculate_fftSNR performs Fast Fourier Transformation on epoched EEG data
% and calculates signal to noise ratio for each frequency. Plots power
% density and SNR after calculations and saves figure as pdf file.
%
% Use as:
% calculate_fft()
%
% Function pops up a window which you can select epoched EEG ".set" file
% you want to analyze. Uses only occipital channels and performs 100Hz low
% pass filter after FFT.
%
% Parameters:
%
% maxFreq = 100; % The maximum frequency which you want to analyze. (100 in default)
%
% noisebins = 10; % Number of neighboring bins on each side of frequency of
% interest. SNR for each frequency is calculated by dividing power of
% frequency of interest by average of 10 bins on each side of the FOI
% skipping the closest two bins.
%
% padbins = 2; % Number of padding bins.
%
% freqRes = 1/50; % Frequency resolution used in SNR analysis. (0.02Hz in default)
%
% Reference for SNR analysis:
%
% Rossion, B., Boremanse, A., 2011. Robust sensitivity to facial identity in the right human
% occipito-temporal cortex as revealed by steady-state visual-evoked potentials. J.
% Vision 11 (2), 16, 1–21.
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

for t = 1 : length(files)
    outputfilename = files{t}(1:end-4);
    EEG = pop_loadset(files{t},path);
    % Choose occipital channels.
    EEG = pop_select( EEG,'channel',{'PO7' 'PO3' 'O1' 'Oz' 'POz' 'PO8' 'PO4' 'O2'});
        
    % Set parameters.
    maxFreq = 100; % low pass filter.
    datasize = size(EEG.data);  % datasize.
    Fs = EEG.srate; % sampling frequency.
    freq = (0:datasize(2)-1)*Fs/datasize(2); % freqs.
    freqList = freq(freq <= maxFreq); % new frequency list.
    noisebins = 10; % neighboring bins.
    padbins = 2; % number of closest neighbors.
    freqRes = 1/50; % frequency resolution (1/50 suggested).
    
    %% FFT
    % Calculate power using fast fourier transformation and filter out data
    % with frequency above max frequency.
    fData.power = zeros(datasize(1),length(freqList),datasize(3));
    for channel = 1: datasize(1)
        for trial = 1: datasize(3)
            % Power spectrum in microvolt squared.
            temp = abs(fft(EEG.data(channel,:,trial)).^2);
            fData.power(channel,:,trial) = temp(freq <= maxFreq);
        end
    end
    
    clear temp; % Clear temp data.
    
    %% SNR
    fData.snr = zeros(size(fData.power));
    for trial = 1:size(fData.power, 3)
        for i = 1:numel(freqList)
            
            % current frequency
            cFreq = freqList(i);
            
            % calculate signal to noise
            stimband = freqList > cFreq-freqRes &...
                freqList < cFreq+freqRes;
            noiseband = ~((freqList > cFreq-padbins*freqRes) &...
                (freqList < cFreq+padbins*freqRes)) & ...
                freqList > cFreq-noisebins*freqRes &...
                freqList < cFreq+noisebins*freqRes;
            
            % Calculate SNR and store it in the structure
            fData.snr(:, i, trial) = mean(fData.power(:, stimband, trial), 2)./...
                mean(fData.power(:, noiseband, trial), 2);
        end
    end
    
    % Make the beginning and end NaNs because they don't have any neighbours
    fData.snr(:, 1:noisebins,:) = NaN;
    fData.snr(:, end-noisebins:end,:) = NaN;
    
    %% SNR II
    fData.powerERP = mean(fData.power,3);
    
    if ndims(fData.powerERP) == 2
        fData.powerERP = permute(fData.powerERP, [3, 1, 2]);
    end
    fData.snrERP = zeros(size(fData.powerERP));
    for trial = 1:size(fData.powerERP, 1)
        for i = 1:numel(freqList)
            
            % current frequency
            cFreq = freqList(i);
            
            % calculate signal to noise
            stimband = freqList > cFreq-freqRes &...
                freqList < cFreq+freqRes;
            noiseband = ~((freqList > cFreq-padbins*freqRes) &...
                (freqList < cFreq+padbins*freqRes)) & ...
                freqList > cFreq-noisebins*freqRes &...
                freqList < cFreq+noisebins*freqRes;
            
            % Calculate SNR and store it in the structure
            fData.snrERP(trial, :, i) = mean(fData.powerERP(trial, :, stimband), 3)./...
                mean(fData.powerERP(trial, :, noiseband), 3);
        end
    end
    
    fData.snrERP = squeeze(fData.snrERP);
    % Make the beginning and end NaNs because they don't have any neighbours
    fData.snrERP(:, 1:noisebins) = NaN;
    fData.snrERP(:, end-noisebins:end) = NaN;
    
    %% Plot Results.
    
    % Plot Power
    fig = figure;
    subplot(3,1,1);
    plot(freqList,(mean(fData.power,3)));
    title(['Power Spectrum Density (Occipital channel)']);
    xlim([2 45])
    ylim([0 max(max(mean(fData.power,3)))])
    set(gca,'XTick',(0:1:45))
    % set(gca,'YTick',(0:1:max(max(fData.snrERP,3))))
    xlabel('Freq (Hz)')
    ylabel('Amplitude (mV^2)')
    
    % Plot SNR
    subplot(3,1,2);
    plot(freqList, mean(fData.snr,3));
    title(['Signal to noise ratio (Occipital channel, all trials)']);
    xlim([2 45])
    ylim([0 15])
    set(gca,'XTick',(0:1:45))
    set(gca,'YTick',(0:1:15))
    xlabel('Freq (Hz)')
    ylabel('SNR')
    
    % % Plot SNR II
    % subplot(4,1,3);
    % plot(freqList, fData.snrERP);
    % title(['ERP Signal to noise ratio (Occipital channel)']);
    % xlim([2 45])
    % ylim([0 15])
    % set(gca,'XTick',(0:1:45))
    % set(gca,'YTick',(0:1:max(max(fData.snrERP))))
    % xlabel('Freq (Hz)')
    % ylabel('SNR')
    
    % Plot Time-Frequency Representation
    % Uses FFT.
    subplot(3,1,3)
    newtimef(mean(EEG.data,1),...
        EEG.pnts,[-2000 10990], EEG.srate,0,...
        'freqs',[2 20],'plotitc','off','erspmax', [1 4],...
        'title','Time Frequency Representation (Channels Averaged)',...
        'scale','abs');
    
    fig.PaperPositionMode = 'manual';
    orient(fig,'landscape')
    print(fig,'-dpdf', [path outputfilename,'.pdf'])
end
end