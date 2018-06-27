function [EEG] = preICA()
%   PREICA performs preprocessing steps prior to ICA.
%
%   Usage:
%   [EEG] = preICA(); returns EEG structure that is ready for ICA.
%
%   Output: Saves FPVS_(subjecNumber)_preICA.set
%
%   Author: Emin Serin / Berlin School of Mind and Brain

%% Load EEG files.
% Import bdf file.
disp('<<<<<Please load EEG ".bdf" file>>>>>')
[eegfile, eegpath] = uigetfile('.bdf','Please select .bdf file');
dataName = ['FPVS_',input('Subject number: ','s')];
EEG.path = eegpath;

% channel locations directory
channelLocs = which('standard-10-5-cap385.elp');

%% Step 1: Import data.
EEG = pop_biosig([eegpath eegfile],'channels',[]);
EEG.setname = dataName;
chanChange = 1; % Bypass broken channel.
if chanChange
    [~,locExt] = ismember('A2L',{EEG.chanlocs.labels});
    [~,locInt] = ismember('Oz',{EEG.chanlocs.labels});
    EEG.data(locExt,:) = EEG.data(locInt,:);
end
EEG = pop_select(EEG,'channel',[1:64]);

%% Step 2: Resample data.
EEG = pop_resample(EEG,500); % resample to 500Hz.
 
%% Step 3: Bandpass filter.
EEG = pop_eegfiltnew(EEG, 1,100,1690,0,[],1); % filter data. 1 - 100 Hz.

%% Step 4: import channel locations.
EEG = pop_chanedit(EEG, 'lookup',channelLocs);

%% Step 5: Epoch Extraction
EEG = pop_epoch( EEG, {  '111'  '112'  '113'  '121'  '122'  '123'  '211'  '212'  '213'  '221'  '222'  '223'  },...
    [-2  11], 'newname', [dataName,'_epochs'], 'epochinfo', 'yes');

%% Step 6: Reject epochs with Artifact.
epochRejStd = 6; % Epoch rejection threshold.
fprintf('<<<<Epochs with std above %d is being rejected.>>>>',epochRejStd)
EEG = pop_jointprob(EEG,1,[1:64] ,epochRejStd,epochRejStd,1,0); 
rejIndex = find(EEG.reject.rejjp); % find epoch index rejected. 
EEG = pop_select(EEG,'notrial',rejIndex); % reject epochs. 
save([eegpath,dataName,'_rejIndex.mat'],'rejIndex'); % save rejIndex. 

%% Step 7: plot data and check if there is a bad channel and reject.
kValue = 10; % kurtosis threshold.
fprintf('<<<<<Channels whose kurtosis value above %d>>>>>',kValue);
[~,indelec] = pop_rejchan(EEG, 'elec',[1:64] ,'threshold',kValue,'norm','on','measure','kurt');

% Plot channels whose kurtosis value above given value.
color = {}; color(1:length(EEG.chanlocs)) = {'k'}; color(indelec) = {'r'};
eegplot(EEG.data, 'srate', EEG.srate, 'title', 'Scroll component activities -- eegplot()', ...
    'limits', [EEG.xmin EEG.xmax]*1000, 'color', color,'eloc_file',EEG.chanlocs);

% Ask for channels being rejected.
defaultRej = []; % Default channels to be rejected. Fp1 and Fpz (broken).
chaninterpolate = askNumList(['Enter channels you want to interpolate:']);
chaninterpolate = [defaultRej,chaninterpolate];

% Interpolate selected regions.
if ~isnan(chaninterpolate)
    EEG = pop_interp(EEG, chaninterpolate, 'spherical');
end


%% Save preICA dataset.
pop_saveset( EEG, 'filename', [dataName, '_preICA'], 'filepath', EEG.path);
eeglab redraw; % open EEG lab.

%% Nested functions
    function numlist = askNumList(prompt)
        % Ask and returns list of numbers.
        numlist = input(prompt,'s');
        numlist = arrayfun(@(i) str2double(i),strsplit(numlist,{' ',','}));
        if isnan(numlist)
            numlist = [];
        end
    end

end

