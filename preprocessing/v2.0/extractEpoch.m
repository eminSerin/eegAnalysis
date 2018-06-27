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
dataName = input('Subject number: ','s');
load([eegpath,'FPVS_',dataName,'_rejIndex.mat');

%% Reference to average.
% This step needs fullRankAveRef plugin.
% http://sccn.ucsd.edu/eeglab/plugins/fullRankAveRef0.10.zip Please check
% following link about why we need to use this function.
% https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline#Re-reference_the_data_to_average_.2811.2F29.2F2017_updated.29
EEG = fullRankAveRef(EEG);

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

tmpdata(rejIndex) = []; % remove trials with artifacts. 
tmpdata = rmfield(tmpdata,'trial');
%%
% Create epoch index for each condition.
cond.imp4Hzself = []; cond.imp4Hzfam = [];
cond.exp4Hzself = []; cond.exp4Hzfam = [];
for t = 1 : length(tmpdata)
    if tmpdata(t).block < 3
        if strcmpi(tmpdata(t).imType,'self')...,
                && ~(strcmpi(tmpdata(t).responseType,'pink') || (~tmpdata(t).accuracy))
            cond.imp4Hzself = [cond.imp4Hzself,t];
        elseif strcmpi(tmpdata(t).imType,'familiar')...,
                && ~(strcmpi(tmpdata(t).responseType,'pink') || (~tmpdata(t).accuracy))
            cond.imp4Hzfam = [cond.imp4Hzfam,t];
        end
    else
        if strcmpi(tmpdata(t).imType,'self') && tmpdata(t).accuracy
            cond.exp4Hzself = [cond.exp4Hzself,t];
        elseif strcmpi(tmpdata(t).imType,'familiar') && tmpdata(t).accuracy
            cond.exp4Hzfam = [cond.exp4Hzfam,t];
        end
    end
end
%%
% Create separate ".set" file for each condition.
condfields = fieldnames(cond);
oriEEG = EEG;
for s = 1: length(condfields)
    % Ouput directory
    outputDir = [eegpath condfields{s} filesep];
    if ~exist(outputDir)
        mkdir(outputDir)
    end
    
    EEG = pop_selectevent( EEG, 'epoch',[cond.(condfields{s})] ,'deleteevents','off',...
        'deleteepochs','on','invertepochs','off');
    EEG.setname = dataName;
    pop_saveset( EEG, 'filename', dataName, 'filepath', outputDir);
    EEG = oriEEG;
end

disp('<<<<<<<DONE.>>>>>>>')
fprintf('Trials \n impSelf: %d, \n impFam: %d \n expSelf: %d \n expFam: %d \n',...
    length(cond.imp4Hzself),length(cond.imp4Hzfam),...
    length(cond.exp4Hzself), length(cond.exp4Hzfam))

fprintf('<<<%d epochs are rejected.>>>\n',...
    (length(tmpdata)-(length(cond.imp4Hzself)...
    + length(cond.imp4Hzfam)...
    +length(cond.exp4Hzfam)...
    +length(cond.exp4Hzself))))
end

