function [] = prep_tfDataTable(datTWin)
%   prep_dataTable creates datatable that includes time frequency eeg
%   data of the subjects given in a given time window.
%   The function asks user to load time frequency datafiles, and it returns
%   .mat and .csv file of data set for further statistical analysis. TF
%   data in a given time windows from all electrodes is exported and
%   written in the datatable. 
%
%   Input: 
%       time-frequency eeg dataset created by convert_sub2Mat function 
%           (e.g. subDataMat_rel.mat) 
%       .set file: Any set file used in the project. .set file is loaded
%           for fetching label information. 
%       datTWin: Data time window which time frequency data is averaged 
%           (default: [4000,4500]). 
%
%   Output:
%       dataset in .mat and csv format. 
%
%   Emin Serin - Berlin School of Mind and Brain
%
%
%% Input parse
if nargin < 1
    % Default datTWin values. 
    datTWin = [4000,4500];
elseif nargin > 1
    disp('Too much input! Please only enter datWin');
    help prep_dataTable
end

tarFreq = 4; % target frequency.

%% TF data.

% Load data.
disp('Please select dataset file that includes time frequency data!!!')
[file, path] = uigetfile('subDataMat_rel.mat','Please load .mat file that includes time frequency data');
% Load mat file.
data = load([path file]);
fname = fieldnames(data);
data = data.(fname{:});
fname = fieldnames(data);
conds = fname(4:end); % condition names.

% Get electrode labels and locations. 
disp('Please select any .set data to get electrode information')
[file, path] = uigetfile('*.set','Please load .set data.');
EEG = pop_loadset(file, path);
nChannels = size(EEG.chanlocs,2); % numbers of channels.

datIdx = [find(data.times == datTWin(1)):find(data.times == datTWin(2))]; % Task index.
dataTable.subID = data.subID;
nSub = length([dataTable.subID]);
% Main loop.
for nc = 1:length(conds)
    for part = 1: nSub
        for el = 1: nChannels
            dataTable(part).([conds{nc},'_',EEG.chanlocs(el).labels])...
                = mean(data.(conds{nc})(el,datIdx,tarFreq,part),2);
        end
    end
end

%% Save into .mat and .csv files.
% Ouput directory
outputDir = [pwd filesep 'plots_&_datatables' filesep];
if ~exist(outputDir)
    mkdir(outputDir)
end
outputfile = [outputDir 'dataTable_allEl_', num2str(datTWin(1)),'_',num2str(datTWin(2)),'.mat'];
save(outputfile,'dataTable');
struct2csv(outputfile,'dataTable');

disp('Done!!!')
end

