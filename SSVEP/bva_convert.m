function [] = bva_convert()
%   bva_convert converts .bdf/.set files into a BrainVisionAnalyzer compatible
%   format and saves into a same directory as input files.
%   
%   Input:
%       .bdf or .set files to be converted (multiple selection is possible).
%
%   Output
%       BrainVisionAnalyzer compatible data format of given files.
%
%   Emin Serin - Berlin School of Mind and Brain
%   
%% Load bdf files.
[eegfiles, eegpath] = uigetfile({'*.bdf';'*.set'},'Please select .bdf file',...
    'Multiselect', 'on');

if ischar(eegfiles)
    nfile = 1;
else
    nfile = length(eegfiles);
end

outputDir = [eegpath 'BVA_export' filesep];
if ~exist(outputDir)
    % Create directory if not existed. 
    mkdir(outputDir)
end

for i = 1: nfile
    
    if nfile ~= 1
        cfile = eegfiles{i};
    else
        cfile = eegfiles;
    end
    
    fprintf('<<<<<Data: %d/%d >>>>>\n', i, nfile);
    % Import files.
    dataName = cfile(1:end-4);
    extName = cfile(end-3:end);
    if strcmpi(extName,'.bdf')
        EEG = pop_biosig([eegpath cfile]);
    else
        EEG = pop_loadset(cfile, eegpath);
    end
    pop_writebva(EEG,[outputDir dataName]);
end
disp('<<<<DONE!>>>>')
end

