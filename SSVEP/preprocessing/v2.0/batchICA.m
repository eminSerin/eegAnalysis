function [] = batchICA()
% batchICA runs ICA on multiple pre-ICA EEG data. 
% 
% Usage: 
% batchICA();
%
% Please import multiple files using the pop-up window. Input EEG files
% must be preprocessed with preICA steps (e.g. resampled,
% bandpass-filtered, interpolated and averaged).

%% ICA Batch.
% Load multiple preICA *.set files. 
[files,eegpath] = uigetfile('.set','Please select ".set" files you want to ICA on.'...
    ,'MultiSelect','on');

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
    spstr = strsplit(EEG.setname,'_'); 
    cDataName = [spstr{1}, '_',spstr{2},'_ica']; % dataname
    EEG.setname = cDataName; % change setname with current dataname
    EEG = pop_runica(EEG, 'extended',1,'interupt','on'); % run ica. 
    pop_saveset( EEG, 'filename', EEG.setname, 'filepath', eegpath); % save ICA .set file. 
end

end