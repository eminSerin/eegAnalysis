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
EEG = pop_biosig([eegpath eegfile],'channels',[1:64]);
EEG.setname = dataName;

%% Step 2: Resample data.
EEG = pop_resample(EEG,512);

%% Step 3: Bandpass filter.
EEG = pop_eegfiltnew(EEG, 1,100,1690,0,[],1);

%% Step 4: import channel locations.
EEG = pop_chanedit(EEG, 'lookup',channelLocs);
eeglab redraw;

%% Step 5: plot data and check if there is a bad channel and reject.
kValue = 15; % kurtosis threshold.
fprintf('<<<<<Channels whose kurtosis value above %d>>>>>',kValue);
[~,indelec] = pop_rejchan(EEG, 'elec',[1:64] ,'threshold',kValue,'norm','on','measure','kurt');

% Plot channels whose kurtosis value above given value.
color = {}; color(1:length(EEG.chanlocs)) = {'k'}; color(indelec) = {'r'};
eegplot(EEG.data, 'srate', EEG.srate, 'title', 'Scroll component activities -- eegplot()', ...
    'limits', [EEG.xmin EEG.xmax]*1000, 'color', color,'eloc_file',EEG.chanlocs);

% Ask for channels being rejected.
defaultRej = [1,33]; % Default channels to be rejected. Fp1 and Fpz (broken).
chaninterpolate = askNumList(['Enter channels you want to interpolate ',...
    '(Fp1,Fpz in default):']);
chaninterpolate = [defaultRej,chaninterpolate];

% Interpolate selected regions.
if ~isnan(chaninterpolate)
    EEG = pop_interp(EEG, chaninterpolate, 'spherical');
end

%% Step 6: Reference to average.
% This step needs fullRankAveRef plugin.
% http://sccn.ucsd.edu/eeglab/plugins/fullRankAveRef0.10.zip Please check
% following link about why we need to use this function.
% https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline#Re-reference_the_data_to_average_.2811.2F29.2F2017_updated.29
EEG = fullRankAveRef(EEG);
% Save preICA dataset. 
pop_saveset( EEG, 'filename', [dataName, '_preICA'], 'filepath', EEG.path);
eeglab redraw; % open EEG lab.

end

