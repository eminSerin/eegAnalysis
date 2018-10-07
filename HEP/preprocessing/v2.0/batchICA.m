function [] = batchICA()
% batchICA runs ICA on multiple pre-ICA EEG data. 
%
% Required input structure:
%   subID_preICA_toICA.set - The dataset that ICA will run on. Should be at
%       least 0.5Hz highpass filtered.
%   subID_preICA_org.set - Original dataset which will be used in further
%       analysis. ICA weights of "toICA" dataset is copied in this file.   
%
% Usage: 
%   batchICA();
%
% CAUTION: 
%   It needs an original date set file in addition to toICA set to copy ICA
%       weights in it. Please read README.md file. 
%   
% Please import multiple files using the pop-up window. Input EEG files
% must be preprocessed with preICA steps (e.g. resampled,
% bandpass-filtered, interpolated and averaged).
%
% Redesigned for heartbeat evoked potentials analysis. 
%
% Emin Serin - Berlin School of Mind and Brain
%

%% ICA Batch.
% Load multiple preICA *.set files. 
[files,eegpath] = uigetfile('*_toICA.set','Please select ".set" files you want to ICA on.'...
    ,'MultiSelect','on');

binica = 1; % run binica (set 0 if no binary on the computer). 

if ischar(files) 
    nfile = 1; 
else
    nfile = length(files); 
end

% ICA loop.
for i = 1: nfile
    if nfile ~= 1
        cfile = files{i};
    else
        cfile = files;
    end
    EEG = pop_loadset(cfile, eegpath); % import current file. 
    spstr = strsplit(cfile,'_'); 
    cDataName = [spstr{1},'_ica']; % dataname
    if binica 
        EEG = pop_runica(EEG, 'icatype','binica','extended',1,'interupt','on'); % run binica. 
    else
        EEG = pop_runica(EEG, 'extended',1,'interupt','on'); % run ica. 
    end
    % Import original dataset.
    TMP = pop_loadset([spstr{1},'_',spstr{2},'_org.set']);
    
    % Change ICA weights. 
    TMP.icawinv = EEG.icawinv;
    TMP.icasphere = EEG.icasphere;
    TMP.icaweights = EEG.icaweights;
    TMP.icachansind = EEG.icachansind;
    
    EEG = TMP; % change current dataset to original set. 
    EEG.setname = cDataName; % change setname with current dataname
    pop_saveset( EEG, 'filename', EEG.setname, 'filepath', eegpath); % save ICA .set file. 
end

end