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
% maxFreq = 20; % The maximum frequency which you want to analyze. (20 in default)
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

% Set parameters.
maxFreq = 30; % maximum frequency
noisebins = 10; % neighboring bins.
padbins = 2; % number of closest neighbors.
freqRes = 1/50; % frequency resolution (1/50 suggested).
datTimeWin = [3000,10000]; % task Time Window
Display = 0; % If plots.

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
    
    outputfilename = cfile(1:end-4);
    ft(t).dataname = outputfilename;
    EEG = pop_loadset(cfile,path);
    %     % Choose occipital channels.
    %     EEG = pop_select( EEG,'channel',{'PO7' 'PO3' 'O1' 'Oz' 'POz' 'PO8' 'PO4' 'O2'});
    
    % Set parameters.
    datasize = size(EEG.data);  % datasize.
    Fs = EEG.srate; % sampling frequency.
    datIdx = [find(EEG.times == datTimeWin(1))...
        :find(EEG.times == datTimeWin(2))]; % Task index.
    freq = (0:numel(datIdx)-1)*Fs/(numel(datIdx)); % freqs.
    datFreqList = freq(freq <= maxFreq); % new frequency list.
    %% FFT
    % Calculate power using fast fourier transformation and filter out data
    % with frequency above max frequency.
    for channel = 1: datasize(1)
        for trial = 1: datasize(3)
            % Normalized Power spectrum in microvolt squared.
            temp = abs(fft(EEG.data(channel,datIdx,trial))/length(freq)).^2;
            ft(t).power(channel,:,trial) = temp(:,freq <= maxFreq,:);
        end
    end
    
    clear temp; % Clear temp data.
    
    %% SNR
    ft(t).snr = zeros(size(ft(t).power));
    for trial = 1:size(ft(t).power, 3)
        for i = 1:numel(datFreqList)
            
            % current frequency
            cFreq = datFreqList(i);
            
            % calculate signal to noise
            stimband = datFreqList > cFreq-freqRes &...
                datFreqList < cFreq+freqRes;
            noiseband = ~((datFreqList > cFreq-padbins*freqRes) &...
                (datFreqList < cFreq+padbins*freqRes)) & ...
                datFreqList > cFreq-noisebins*freqRes &...
                datFreqList < cFreq+noisebins*freqRes;
            
            % Calculate SNR and store it in the structure
            ft(t).snr(:, i, trial) = mean(ft(t).power(:, stimband, trial), 2)./...
                mean(ft(t).power(:, noiseband, trial), 2);
        end
    end
    
    % Make the beginning and end NaNs because they don't have any neighbours
    ft(t).snr(:, 1:noisebins,:) = NaN;
    ft(t).snr(:, end-noisebins:end,:) = NaN;
    
    %% Plot Results.
    
    if Display
        % Plot Power
        fig = figure;
        subplot(2,2,1);
        plot(datFreqList,mean(mean(ft(t).power,3),1));
        title(['Power Spectrum (Occipital channels only)']);
        xlim([2 maxFreq])
        ymax = ceil(max(mean(mean(ft(t).power,3),1)));
        ylim([-0.2 ymax+ymax/10])
        set(gca,'XTick',(0:1:maxFreq))
        set(gca,'YTick',(-0.2:ymax/3:ymax))
        xlabel('Freq (Hz)', 'FontSize',10);
        ylabel('Amplitude (mV^2)', 'FontSize',10);
        
        % Plot SNR
        subplot(2,2,2);
        plot(datFreqList, mean(mean(ft(t).snr,3),1));
        title(['Signal to noise ratio (Occipital channels only)']);
        xlim([2 maxFreq])
        ymax = ceil(max(mean(mean(ft(t).snr,3),1)));
        ylim([0.2 ymax+ymax/10])
        set(gca,'XTick',(0:1:maxFreq))
        set(gca,'YTick',(0.2:ymax/10:ymax))
        xlabel('Freq (Hz)', 'FontSize',10)
        ylabel('SNR', 'FontSize',10)
        
        % Plot Time-Frequency domain using Morlet Wavelets.
        subplot(2,2,[3 4])
        title(['Time Frequency Representation (Channels Averaged)'],'FontSize',...
            10);
        [ft(t).ft.ersp,ft(t).ft.itc,ft(t).ft.powbase,...
            ft(t).ft.times,ft(t).ft.freqs,ft(t).ft.erspboot,...
            ft(t).ft.itcboot] = newtimef(mean(EEG.data,1),...
            EEG.pnts,[3000 10000], EEG.srate,[7],...
            'freqs',[2 20],'plotitc','off','erspmax', [0 4]);
        
        % Save pdf file.
        fig.PaperPositionMode = 'manual';
        orient(fig,'landscape')
        print(fig,'-dpdf', [path outputfilename,'_eeglab','.pdf'])
    end
end
% Save processed time-frequency data structure.
save([path,path(end-5:end-1),'_',num2str(datTimeWin),'.mat'],'ft','datFreqList');
disp('<<<<<DONE!>>>>>')
end