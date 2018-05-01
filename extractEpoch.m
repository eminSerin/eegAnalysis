function [] = extractEpoch()
% extractEpoch epochs given EEG datasets, rejects trials with pink dot
% appears or false positive as well as trials with artifacts. 
% Following the artifact rejection, create separate datasets for each 
% condition (e.g. imp4Hzself, exp4Hzfam), and saves into input directory.
%
% Usage: 
% extractEpoch()
% 
% Please use this function after ICA. Please enter subject number and load
% EEGLAB .set file and log file (.mat file). 
%
% Output file: FPVS_(subjectNumber)_(condition).set
%
% Author: Emin Serin / Berlin School of Mind and Brain

%% Load files. 
disp('<<<<<Please import EEG ".set" file>>>>>')
[eegfile, eegpath] = uigetfile('.set','Please select .set file');
EEG = pop_loadset(eegfile, eegpath);
dataName = ['FPVS_',input('Subject number: ','s')];
cDataName = [dataName,'_epochs'];

%% Epoch Extraction
EEG.setname = cDataName;
EEG = pop_epoch( EEG, {  '111'  '112'  '113'  '121'  '122'  '123'  '211'  '212'  '213'  '221'  '222'  '223'  },...
    [-2  11], 'newname', cDataName, 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-2000     0]);

%% Reject epochs with Artifact (only in OCC channels).
epochRejTh = 250; % Epoch rejection threshold.
fprintf('<<<<Epochs with amplitude above %d uV is being rejected.>>>>',epochRejTh)
occEEG = EEG;
occEEG = pop_select(occEEG,'channel',{'PO7' 'PO3' 'O1' 'Oz' 'POz' 'PO8' 'PO4' 'O2'});
[~, rejIndex] = pop_eegthresh(occEEG,1,[1:8] ,-epochRejTh,epochRejTh,-2,10.998,2,0);

%% Reject epochs with pink dot and false positive and create separate .set file for each condition

% Ask behavioral data. 
disp('<<<<<Please import logfile *.mat>>>>>')
[behfile, behpath] = uigetfile('.mat','Please select .mat file');
behData = load([behpath,behfile],'expInfo');
behData = behData.expInfo;

% Remove experiment structure without actual trials. 
t = 1;
for i = 1 : length(behData)
    if ~isempty(behData(i).accuracy) 
        tmpdata(t) = behData(i);
        t = t + 1;
    end
end

tmpdata(rejIndex) = []; % remove epochs with artifact. 
tmpdata = rmfield(tmpdata,'trial');

% Create epoch index for each condition. 
cond.imp4Hz = []; cond.imp4Hzself = []; cond.imp4Hzfam = [];
cond.exp4Hz = []; cond.exp4Hzself = []; cond.exp4Hzfam = [];
for t = 1 : length(tmpdata)
    if tmpdata(t).block < 3
        if strcmpi(tmpdata(t).imType,'self')...,
                && ~(strcmpi(tmpdata(t).responseType,'pink') || (~tmpdata(t).accuracy))
            cond.imp4Hz = [cond.imp4Hz,t];
            cond.imp4Hzself = [cond.imp4Hzself,t];
        elseif strcmpi(tmpdata(t).imType,'familiar')...,
                && ~(strcmpi(tmpdata(t).responseType,'pink') || (~tmpdata(t).accuracy))
            cond.imp4Hz = [cond.imp4Hz,t];
            cond.imp4Hzfam = [cond.imp4Hzfam,t];
        end
    else
        if strcmpi(tmpdata(t).imType,'self') && tmpdata(t).accuracy
            cond.exp4Hz = [cond.exp4Hz,t];
            cond.exp4Hzself = [cond.exp4Hzself,t];
        elseif strcmpi(tmpdata(t).imType,'familiar') && tmpdata(t).accuracy
            cond.exp4Hz = [cond.exp4Hz,t];
            cond.exp4Hzfam = [cond.exp4Hzfam,t];
        end
    end
end

% Create separate ".set" file for each condition. 
condfields = fieldnames(cond);
oriEEG = EEG;
for s = 1: length(condfields)
    EEG = pop_selectevent( EEG, 'epoch',[cond.(condfields{s})] ,'deleteevents','off',...
        'deleteepochs','on','invertepochs','off');
    outputName = [dataName, '_', condfields{s}];
    EEG.setname = outputName;
    pop_saveset( EEG, 'filename', outputName, 'filepath', eegpath);
    EEG = oriEEG;
end

disp('<<<<<<<DONE.>>>>>>>')
fprintf('Trials \n impSelf: %d, \n impFam: %d \n expSelf: %d \n expFam: %d \n',...
    length(cond.imp4Hzself),length(cond.imp4Hzfam),...
    length(cond.exp4Hzself), length(cond.exp4Hzfam))

fprintf('<<<%d epochs are rejected.>',...
    (length(tmpdata)-(length(cond.imp4Hz)+length(cond.exp4Hz))))
end

