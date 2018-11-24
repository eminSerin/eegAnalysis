function [] = create_fftSNRmat()
%   CREATE_FFTSNRMAT creates matrix with FFT amd SNR values of each subject
%   located in given directory.
%
%   Input:
%       Directory of each subject file is located under a folder named with
%           condition. (e.g. Data\expF\*.set)
%       maxFreq : Maximum frequency value.
%       dataTimeWin = Time window of data which FFT and SNR calculation
%           performs in.
%
%   Output:
%       .mat data structure containing FFT and SNR values of each subject.
%
%   Emin Serin - Berlin School of Mind and Brain
%
%% Pre-FFT

% Set parameters.
maxFreq = 30; % maximum frequency
noisebins = 10; % neighboring bins.
padbins = 2; % number of closest neighbors.
datTimeWin = [3000,9998]; % task Time Window
freqRes = 1/10; % 1/trial time in sec is recommended.

% Load eeglab set file.
path = uigetdir('Please load .set eeg datafile');
folders = dir(path);
folders = folders(cellfun(@isdir,{folders.name}));
folders = folders(3:end);
pset = 0;
tic;

if license('test','distrib_computing_toolbox')
    pool = gcp;
    poolsize = pool.NumWorkers;
else
    poolsize = 0;
end

%% Import and convert eeg files.
for nfol = 1 : numel(folders)
    filePath = dir([path,filesep,folders(nfol).name,filesep,'*.set']);
    for nfi = 1:length(filePath)
        cfile = filePath(nfi).name;
        EEG = pop_loadset(cfile,[path,filesep,folders(nfol).name]);
        if ~pset
            % Set parameters.
            datasize = size(EEG.data);  % datasize.
            Fs = EEG.srate; % sampling frequency.
            datIdx = [find(EEG.times == datTimeWin(1))...
                :find(EEG.times == datTimeWin(2))]; % Task index.
            freq = (0:numel(datIdx)-1)*Fs/(numel(datIdx)); % freqs.
            datFreqList = freq(freq <= maxFreq); % new frequency list.
            data.freqs = datFreqList;
            pset = 1;
            nfreqs = numel(datFreqList);
            noiseband = false(nfreqs,nfreqs);
            stimband = false(nfreqs,nfreqs);
            for i = 1:nfreqs
                % current frequency
                cFreq = datFreqList(i);
                % calculate signal to noise
                stimband(i,:) = datFreqList > cFreq-freqRes &...
                    datFreqList < cFreq+freqRes;
                noiseband(i,:) = ~((datFreqList > cFreq-padbins*freqRes) &...
                    (datFreqList < cFreq+padbins*freqRes)) & ...
                    datFreqList > cFreq-noisebins*freqRes &...
                    datFreqList < cFreq+noisebins*freqRes;
            end
        end
        
        %% FFT
        % Calculate power using fast fourier transformation and filter out data
        % with frequency above max frequency.
        temp = zeros(datasize(1),numel(datFreqList),datasize(3));
        for channel = 1: datasize(1)
            for trial = 1: EEG.trials
                % Normalized Power spectrum in microvolt squared.
                tmp = abs(fft(EEG.data(channel,datIdx,trial))/length(freq)).^2;
                temp(channel,:,trial) = tmp(:,freq <= maxFreq,:);
            end
        end
        data.(folders(nfol).name).power(:,:,nfi) = mean(temp,3);
        
        %% SNR
        tmp = zeros(size(temp));
        parfor (i = 1:nfreqs,poolsize)
            % Calculate SNR and store it in the structure
            tmp(:, i, :) = temp(:, stimband(i,:), :) ./...
                mean(temp(:, noiseband(i,:), :), 2);
        end
        % Make the beginning and end NaNs because they don't have any neighbours
        tmp(:, 1:noisebins,:) = NaN;
        tmp(:, end-noisebins:end,:) = NaN;
        data.(folders(nfol).name).snr(:,:,nfi) = mean(tmp,3);
    end
end
% Read subject IDs.
exp = '\d';
regexpf = @(c) regexp(c,exp);
extnum = @(c) c(regexpf(c));
data.subID = str2double(cellfun(extnum,{filePath.name},'UniformOutput',false));

save('subfftSnr.mat','data'); % save data structure.
fprintf('Done!! Running time: %f\n',toc);
end
