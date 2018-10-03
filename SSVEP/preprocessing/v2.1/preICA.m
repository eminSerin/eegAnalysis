function [rejChanEpoch] = preICA()
%   PREICA performs preprocessing steps prior to ICA.
%   
%   Caution: 
%       Logfiles must be in the same folder with EEG files, and only
%       subject number used for them. (e.g. 09.mat)
%
%   Usage:
%   [rejChanEpoch] = preICA(); returns EEG structure that is ready for ICA.
%
%   Output: Saves FPVS_(subjecNumber)_preICA.set
%
%   Author: Emin Serin / Berlin School of Mind and Brain

%% Load EEG files.
% Import bdf file.
disp('<<<<<Please load EEG ".bdf" file>>>>>')
[eegfiles, eegpath] = uigetfile('.bdf','Please select .bdf file',...
    'MultiSelect','on');

if ischar(eegfiles)
    nfile = 1;
else
    nfile = length(eegfiles);
end

%% Step 1: Import data.
for i = 1:nfile
    if nfile ~= 1
        cfile = eegfiles{i};
    else
        cfile = eegfiles;
    end
    fprintf('<<<<<Data: %d/%d >>>>>', i, nfile);
    EEG = pop_biosig([eegpath cfile],'channels',[]);
    
    spstr = strsplit(cfile,'_');
    cDataName = spstr{2}; % dataname
    rejChanEpoch(i).subject = cDataName;
    EEG.setname = cDataName;
    
    % Bypass broken channel.
    chanChange = 0; 
    if chanChange
        [~,locExt] = ismember('A2L',{EEG.chanlocs.labels});
        [~,locInt] = ismember('Oz',{EEG.chanlocs.labels});
        EEG.data(locExt,:) = EEG.data(locInt,:);
    end
    EEG = pop_select(EEG,'channel',[1:64]);
    
    % Add channel locations
    channelLocs = which('standard-10-5-cap385.elp');
    EEG = pop_chanedit(EEG, 'lookup',channelLocs);
    
    %% Step 2: Resample data.
    EEG = pop_resample(EEG,500); % resample to 500Hz.
    
    %% Step 3: Bandpass filter.
    EEG = pop_eegfiltnew(EEG, 1,100,1650,0,[],0); % filter data. 1 - 100 Hz.
    
    %% Step 4: Epoch Extraction
    EEG = pop_epoch( EEG, {  '111'  '112'  '113'  '121'  '122'  '123'  '211'  '212'  '213'  '221'  '222'  '223'  },...
        [-2  11], 'newname', [cDataName,'_epochs'], 'epochinfo', 'yes');
    
    %% Step 5: plot data and check if there is a bad channel and reject.
    kValue = 8; % kurtosis threshold.
    fprintf('<<<<<Channels whose kurtosis value above %d>>>>>',kValue);
    [~,indelec] = pop_rejchan(EEG, 'elec',[1:64] ,'threshold',kValue,'norm','on','measure','kurt');
    
    % Plot channels whose kurtosis value above given value.
    color = {}; color(1:length(EEG.chanlocs)) = {'k'}; color(indelec) = {'r'};
    eegplot(EEG.data, 'srate', EEG.srate, 'title', 'Scroll component activities -- eegplot()', ...
        'limits', [EEG.xmin EEG.xmax]*1000, 'color', color,'eloc_file',EEG.chanlocs);
    
    % Ask for additional channels that should be rejected (due to electrode issue).
    chaninterpolate = askNumList(['Index of electrodes that are defected: ']);
    chaninterpolate = [indelec,chaninterpolate];
    
    % Interpolate selected regions.
    if ~isnan(chaninterpolate)
        EEG = pop_interp(EEG, chaninterpolate, 'spherical');
    end
    rejChanEpoch(i).channels = {EEG.chanlocs(chaninterpolate).labels};
    %% Step 6: Reject Trials with pink dot and incorrect response.
    % Ask behavioral data.
    behData = load([eegpath,cDataName,'.mat'],'expInfo');
    behData = behData.expInfo;
    
    % Remove experiment structure without actual trials.
    t = 1;
    for bi = 1 : length(behData)
        if ~isempty(behData(bi).accuracy)
            tmpdata(t) = behData(bi);
            t = t + 1;
        end
    end
    
    % Find trials with pink dot or error and add into rejIndex vector.
    rejIndex = [];
    for t = 1 : length(tmpdata)
        if strcmpi(tmpdata(t).responseType,'pink') || ~tmpdata(t).accuracy
            rejIndex = [rejIndex t];
        end
    end
    
    %% Step 7: Reject epochs with Artifact.
    epochRejStdSingle = 6; % std for single channel.
    epochRejStdAll = 2;  % std for all channel.
    epochRejmV = 500; % maximum microvolt value.
    fprintf('<<<<Epoch Rejection Criteria: mV: %d STD Single: %d, STD All: %d.\n>>>>',...
        epochRejmV,epochRejStdSingle,epochRejStdAll)
    [~,idxmV]=pop_eegthresh(EEG,1,[1:64] ,-epochRejmV,epochRejmV,-2,10.998,2,0);
    EEG = pop_jointprob(EEG,1,[1:64] ,epochRejStdSingle,epochRejStdAll,1,0);
    rejIndex = unique([rejIndex, idxmV, find(EEG.reject.rejjp)]); % update rejection Index.
    EEG = pop_select(EEG,'notrial',rejIndex); % reject epochs.
    save([eegpath,cDataName,'_rejIndex.mat'],'rejIndex'); % save rejIndex.
    rejChanEpoch(i).epochs = rejIndex;
    %% Save preICA dataset.
    pop_saveset( EEG, 'filename', [cDataName, '_preICA'], 'filepath', eegpath);
    close all;
    save([eegpath,'_rejChanEpoch',date,'.mat'],'rejChanEpoch');
end
%% Nested functions
    function numlist = askNumList(prompt)
        % Ask and returns list of numbers.
        numlist = input(prompt,'s');
        numlist = arrayfun(@(i) str2double(i),strsplit(numlist,{' ',','}));
        if isnan(numlist)
            numlist = [];
        end
    end

disp('<<<<DONE!>>>>')
end

