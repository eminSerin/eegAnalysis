function [] = batchICA()
% batchICA runs ICA on multiple pre-ICA EEG data. 
%
% Required input structure:
%   subID_preICA_toICA.set - The dataset that ICA will run on. Should be at
%       least 0.5Hz highpass filtered. If the current data is filtered at
%       lower than 0.5Hz, it is suggested to run ICA on a data filtered at
%       higher than 0.5Hz, and copy the ICA weights to data with lower
%       highpass filter. 
%       (see: https://github.com/CSC-UW/csc-eeg-tools/wiki/Filtering-and-ICA)
%
% Usage: 
%   batchICA();
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
[files,eegpath] = uigetfile('*preICA_.set','Please select ".set" files you want to ICA on.'...
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
        cfile = files{t};
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
    
    EEG.setname = cDataName; % change setname with current dataname
    pop_saveset( EEG, 'filename', EEG.setname, 'filepath', eegpath); % save ICA .set file. 
end

end