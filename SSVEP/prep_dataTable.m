function [] = prep_dataTable(datTWin)
%   prep_dataTable creates datatable which includes time frequency eeg
%   data, signal to noise ratio and behavioral data of the subjects given. 
%   The function asks user to load behavioral, time frequency and snr
%   datafiles, respectively, and it returns .mat and .csv file of data set
%   for further statistical analysis. 
%
%   Input: 
%       logfiles. 
%       time-frequency eeg dataset created by convert_sub2Mat function 
%           (e.g. subDataMat_rel.mat)       
%       Dataset created by subfftSnr function which includes signal to
%           noise ratio.
%       datTWin: Data time window which time frequency data is averaged 
%           (default: [3000,4000]). 
%
%   Output:
%       dataset includes combination of three different data loaded in .mat
%           and csv format. 
%
%   Emin Serin - Berlin School of Mind and Brain
%
%
%% Input parse
if nargin < 1
    % Default datTWin values. 
    datTWin = [3000,4000];
elseif nargin > 1
    disp('Too much input! Please only enter datWin');
    help prep_dataTable
end

%% Load behavioral data.
% Load eeglab set file.
[files, path] = uigetfile('.mat','Please load log files.',...
    'MultiSelect','on');
disp('Please select log files!!!');

if ischar(files)
    nfile = 1;
else
    nfile = length(files);
end
pNum = 1; % participant count.
for f = 1:nfile
    if nfile ~= 1
        cfile = files{f};
    else
        cfile = files;
    end
    
    % participant number.
    pID = strsplit(cfile, '_');
    pID = pID{3};
    % load data file.
    behData = load([path cfile]);
    behData = behData.expInfo;
    
    % Remove experiment structure without actual trials.
    t = 1;
    for i = 1 : length(behData)
        if ~isempty(behData(i).accuracy)
            tmp(t) = behData(i);
            t = t + 1;
        end
    end
    
    % Create indices for each condition
    cond.impself = []; cond.impfam = [];
    cond.expself = []; cond.expfam = [];
    cond.explSelf = []; cond.explFam = [];
    cond.exprSelf = []; cond.exprFam = [];
    for t = 1 : length(tmp)
        if tmp(t).block < 3
            if strcmpi(tmp(t).imType,'self') && tmp(t).accuracy
                cond.impself = [cond.impself,t];
            elseif strcmpi(tmp(t).imType,'familiar') && tmp(t).accuracy
                cond.impfam = [cond.impfam,t];
            end
        elseif tmp(t).block == 3
            if strcmpi(tmp(t).imType,'self') && tmp(t).accuracy
                cond.expself = [cond.expself,t];
                cond.explSelf = [cond.explSelf, t];
            elseif strcmpi(tmp(t).imType,'familiar') && tmp(t).accuracy
                cond.expfam = [cond.expfam,t];
                cond.exprFam = [cond.exprFam t];
            end
        else
            if strcmpi(tmp(t).imType,'self') && tmp(t).accuracy
                cond.expself = [cond.expself,t];
                cond.exprSelf = [cond.exprSelf, t];
            elseif strcmpi(tmp(t).imType,'familiar') && tmp(t).accuracy
                cond.expfam = [cond.expfam,t];
                cond.explFam = [cond.explFam t];
            end
        end
    end
    
    % subject ID.
    dataTable(pNum).subID = str2double(pID);
    
    % Reaction Times in ms.
    dataTable(pNum).expS_rt = round(mean([tmp(cond.expself).rt])*1000);
    dataTable(pNum).expF_rt = round(mean([tmp(cond.expfam).rt])*1000);
    dataTable(pNum).expS_left_rt = round(mean([tmp(cond.explSelf).rt])*1000);
    dataTable(pNum).expS_right_rt = round(mean([tmp(cond.exprSelf).rt])*1000);
    dataTable(pNum).expF_left_rt = round(mean([tmp(cond.explFam).rt])*1000);
    dataTable(pNum).expF_right_rt =  round(mean([tmp(cond.exprFam).rt])*1000);
    
    % Accuracy explicit
    dataTable(pNum).expS_acc = sum([(tmp(cond.expself).accuracy)])...
        / sum(ismember({tmp([tmp.block] > 2).imType},'self'));
    dataTable(pNum).expF_acc = sum([(tmp(cond.expfam).accuracy)])...
        / sum(ismember({tmp([tmp.block] > 2).imType},'familiar'));
    dataTable(pNum).expS_left_acc = sum([(tmp(cond.explSelf).accuracy)])...
        / sum(ismember({tmp([tmp.block] == 3).imType},'self'));
    dataTable(pNum).expS_right_acc = sum([(tmp(cond.exprSelf).accuracy)])...
        / sum(ismember({tmp([tmp.block] == 4).imType},'self'));
    dataTable(pNum).expF_right_acc = sum([(tmp(cond.exprFam).accuracy)])...
        / sum(ismember({tmp([tmp.block] == 3).imType},'familiar'));
    dataTable(pNum).expF_left_acc = sum([(tmp(cond.explFam).accuracy)])...
        / sum(ismember({tmp([tmp.block] == 4).imType},'familiar'));
    
    % Accuracy implicit
    dataTable(pNum).impS_acc = sum([(tmp(cond.impself).accuracy)])...
        / sum(ismember({tmp([tmp.block] < 3).imType},'self'));
    dataTable(pNum).impF_acc = sum([(tmp(cond.impfam).accuracy)])...
        / sum(ismember({tmp([tmp.block] < 3).imType},'familiar'));
    
    
    pNum = pNum + 1;
end


%% TF data.

% Load data.
[file, path] = uigetfile('.mat','Please load .mat file that includes time frequency data');
disp('Please select dataset file that includes time frequency data!!!')

% Electrodes
posterior = [20 21 22 23 24 25 26 27 28 29 30 31 57 58 59 60 61 62 63 64]; % occipital electrodes.
anterior = [1,2,3,4,5,6,7,33,34,35,36,37,38,39,40,41,42]; % frontal electrodes
oz = [29]; p7 = [23]; p8 = [60];
electrodes = {anterior,posterior,oz,p7,p8}; % List of electrodes.
elLabels = {'anterior','posterior','Oz','P7','P8'};

% Load mat file.
data = load([path file]);
fname = fieldnames(data);
data = data.(fname{:});
fname = fieldnames(data);
conds = fname(4:end); % condition names.

% DataIdx if not power or snr plot requested.
datIdx = [find(data.times == datTWin(1)):find(data.times == datTWin(2))]; % Task index.
nSub = length([dataTable.subID]);
% Main loop.
for nc = 1:length(conds)
    for part = 1: nSub
        for el = 1: length(elLabels)
            dataTable(part).([conds{nc},'_',elLabels{el}])...
                = mean(mean(mean(data.(conds{nc})(electrodes{el},datIdx,:,...
                find(data.subID(part)==[dataTable.subID])),3),2),1);
        end
    end
end

%% Load and prepare SNR data.

% Ask for data path.
[file, path] = uigetfile('.mat','Please load .mat file that includes SNR data');
disp('Please select dataset file that includes snr data!!!')

% Load mat file.
data = load([path file]);
fname = fieldnames(data);
data = data.(fname{:});
for nc = 1:length(conds)
    for part = 1: nSub
        for el = 1: length(elLabels)
            dataTable(part).([conds{nc},'_',elLabels{el},'_SNR'])...
                = mean(mean(mean(data.(conds{nc}).snr(electrodes{el},:,...
                find(data.subID(part)==[dataTable.subID])),3),2),1);
        end
    end
end

%% Save into .mat and .csv files.
% Ouput directory
outputDir = [pwd filesep 'plots_&_datatables' filesep];
if ~exist(outputDir)
    mkdir(outputDir)
end
outputfile = [outputDir 'dataTable','_',num2str(datTWin(1)),'_',num2str(datTWin(2)),'.mat'];
save(outputfile,'dataTable');
struct2csv(outputfile,'dataTable');

disp('Done!!!')
end

