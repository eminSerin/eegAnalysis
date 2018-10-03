function [] = bva_convert()
%   BVA_CONVERT converts bdf files into bva format.  
%   
%   Emin Serin / Berlin School of Economics
%
%% Load bdf files. 
[eegfiles, eegpath] = uigetfile('.bdf','Please select .bdf file',...
    'Multiselect', 'on');

if ischar(eegfiles)
    nfile = 1;
else
    nfile = length(eegfiles);
end
%% Convert files. 
for i = 1 : nfile
    if nfile ~= 1
        cfile = eegfiles{t};
    else
        cfile = eegfiles;
    end
    fprintf('<<<<<Data: %d/%d >>>>>', i, nfile);
    % Import files. 
    dataName = cfile(1:end-4);
    EEG = pop_biosig([eegpath cfile]);
    pop_writebva(EEG,[eegpath 'BVA_export' filesep dataName]);
end

