function [nTrials] = extractEpoch()
%   extractEpoch segments data into conditions and save each conditions into 
%   input directory (e.g. impS, expF).
%
%   Input: 
%       Please load (subID)_icaRej.set file (i.e. EEGLAB file after ICA component rejection). 
%       This function assumes subjects' logfiles (subID.mat) and (subID_rejIndex.mat, index of rejected trials)  
%           are in the same folder with eegfiles.
%
%   Output:
%       nTrials: A structure that includes number of trials in each condition. 
%       Output file: (subjectNumber)_(condition).set
%
%    Usage:
%       [nTrials] = extractEpoch();
%
%    06/10/18 - Added function to segment data according to qrs complex events. 
%
%    Author: Emin Serin / Berlin School of Mind and Brain
%
%% Load files.
[files,eegpath] = uigetfile('*_icaRej.set','Please select ".set" files.'...
    ,'MultiSelect','on');

if ischar(files)
    nfile = 1;
else
    nfile = length(files);
end

for k = 1: nfile
    if nfile ~= 1
        cfile = files{k};
    else
        cfile = files;
    end
    fprintf('<<<<<Data: %d/%d >>>>>', k, nfile);
    spstr = strsplit(cfile,'_');
    cDataName = spstr{1}; % dataname
    
    EEG = pop_loadset(cfile, eegpath);
    load([eegpath,cDataName,'_rejIndex.mat']);
    
    %% Reference to average.
    EEG = pop_reref( EEG, []);
    
    %% Reject epochs with pink dot and false positive and create separate .set file for each condition
    
    % Load logfile.
    load([eegpath,'FPVS_beh_',cDataName,'_S2.mat'],'expInfo');
    
    % Remove experiment structure without actual trials.
    t = 1;
    clear tmpdata;
    for i = 1 : length(expInfo)
        if ~isempty(expInfo(i).accuracy)
            tmpdata(t) = expInfo(i);
            t = t + 1;
        end
    end
    
    tmpdata(rejIndex) = []; % remove trials with artifacts.
    tmpdata = rmfield(tmpdata,'trial');
    %%
    % Create epoch index for each condition.
    cond.impS = []; cond.impF = [];
    cond.expS = []; cond.expF = [];
    for t = 1 : length(tmpdata)
        if tmpdata(t).block < 3
            cond.(['imp',upper(tmpdata(t).imType(1))]) = [cond.(['imp',upper(tmpdata(t).imType(1))]),t];
        else
            cond.(['exp',upper(tmpdata(t).imType(1))]) = [cond.(['exp',upper(tmpdata(t).imType(1))]),t];
        end
    end
    
    EEG=pop_fmrib_qrsdetect(EEG,66,'qrs','no'); % add qrs events. 
    %% Save files
    % Create separate ".set" file for each condition.
    condfields = fieldnames(cond);
    oriEEG = EEG;
    nTrials(k).subID = cDataName;
    for s = 1: length(condfields)
        % Ouput directory
        outputDir = [eegpath condfields{s} filesep];
        if ~exist(outputDir)
            mkdir(outputDir)
        end
        
        EEG = pop_selectevent( EEG, 'epoch',[cond.(condfields{s})] ,'deleteevents','off',...
            'deleteepochs','on','invertepochs','off');
        nTrials(k).(condfields{s}) = length(cond.(condfields{s}));
        EEG = pop_epoch( EEG, {  'qrs'  }, [-0.2 1], 'epochinfo', 'yes'); % segment data according to qrs.
        EEG.setname = cDataName;
        pop_saveset( EEG, 'filename', cDataName, 'filepath', outputDir);
        EEG = oriEEG;
    end
    
end
disp('<<<<DONE!>>>>')
end

