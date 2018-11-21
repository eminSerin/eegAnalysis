function [] = bypass_channel(varargin)
%   bypass_channel change the date inside the broken channel with a channel
%   used instead. It uploads the datafile and copies the data of the
%   specific channel to the channel that has problem. 
%   
%   Input:
%       .bdf files: Subject files to be bypassed.
%       extEl: External electrode used to bypass the faulty internal one. 
%       intEl: Problematic internal electrode. 
%   
%   Output: 
%       .bdf file with the same name of given file and suffix "bypassed"
%   
%   Usage:
%       bypass_channel('A2L','Oz');
%
%   Emin Serin - Berlin School of Mind and Brain
%
%% Input parser
if nargin < 1
    % Set external and internal electrodes if no specific given. 
    extEl = 'A2L';
    intEl = 'Oz';
end 
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

for i = 1:nfile
    if nfile ~= 1
        cfile = eegfiles{i};
    else
        cfile = eegfiles;
    end
    
    fprintf('<<<<<Data: %d/%d >>>>>', i, nfile);
    EEG = pop_biosig([eegpath cfile],'channels',[]);
    
    % Bypass broken channel.
    [~,locExt] = ismember(extEl,{EEG.chanlocs.labels});
    [~,locInt] = ismember(intEl,{EEG.chanlocs.labels});
    EEG.data(locExt,:) = EEG.data(locInt,:);
    
    % Save the processed file into same directory.
    pop_saveset( EEG, 'filename', [cfile(1:end-4),'_bypassed.bdf'], 'filepath', eegpath);
end
end

