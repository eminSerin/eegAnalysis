function [] = prepareEEGdataTable()
%   PREPAREEEGDATATABLE prepares EEG data for further statistical analyses.
%   It loads .set files (which in form of electrodes x data bins x subjects)
%   Saves prepared data into .mat and .csv files. 
%
%   Emin Serin - Berlin School of Mind and Brain
%
%
%% Load data.
[files, path] = uigetfile('.set','Please load .set eeg datafile',...
    'MultiSelect','on');

% Ask for data path.
if ischar(files)
    nfile = 1;
else
    nfile = length(files);
end
%%
% Set Some Parameters
subjects = [9 10 15 16 17 19 20 23 24 25 26 29 30 31 32]; % Subjects used.
baseIdx = [101:201]; % Baseline index -1000 to 0ms.
datTWin = [3000,4000]; % data time window
times = linspace(-2000,10990,1300);
datIdx = [find(times == datTWin(1)):find(times == datTWin(2))]; % EEG signal after trigger.
baseMethod = 'rel'; % 'abs': absolute ,'rel': relative,'db' :decibel

% Electrodes
posterior = [20 21 22 23 24 25 26 27 28 29 30 31 57 58 59 60 61 62 63 64]; % occipital electrodes.
anterior = [1,2,3,4,5,6,7,33,34,35,36,37,38,39,40,41,42]; % frontal electrodes
oz = [29]; fcz = [47]; p7 = [23]; p8 = [60];
electrodes = {posterior,anterior,oz,fcz,p7,p8}; % List of electrodes.
elLabels = {'anterior','posterior','Oz','FCz','P7','P8'};

% Reject subjects.
eSubject = [15 17 23 31 32]; % subjects to be excluded. 
subList = []; 
for s = 1: length(subjects)
    subList = [subList ~ismember(subjects(s),eSubject)];
end
subList = logical(subList); 
subjects = subjects(subList);

% Main loop.
eegDataTable = [];
for t = 1 : nfile
    if nfile ~= 1
        cfile = files{t};
    else
        cfile = files;
    end
    EEG = pop_loadset(cfile,path); % Load data.
    baseCor = [];
    for part = 1: length(subjects)
        for el = 1: length(elLabels)
            % baseline correction.
            mBase = mean(EEG.data(electrodes{el},baseIdx,part),2);
            switch baseMethod
                case 'rel'
                    for i = 1:size(EEG.data,2)
                        % Relative signal change.
                        baseCor(:,i) = mean((EEG.data(electrodes{el},i,part)./mBase)-1,1);
                    end
                case 'db'
                    for i = 1:size(EEG.data,2)
                        % dB.
                        baseCor(:,i) = mean(10*log10(EEG.data(electrodes{el},i,part)./mBase),1);
                    end
                case 'abs'
                    for i = 1:size(EEG.data,2)
                        % Absolute power.
                        baseCor(:,i) = mean((EEG.data(electrodes{el},i,part)-mBase),1);
                    end
            end
            
            eegDataTable(part).subID = subjects(part);
            %         eegDataTable(part).([cfile(end-7:end-4),'_raw']) = mean(mean(EEG.data(electrodes,datIdx,part),1),2);
            eegDataTable(part).([cfile(end-7:end-4),'_',elLabels{el},'_baseCor'])...
                = mean(baseCor(:,datIdx),2);
        end
    end
end


%% Load and prepare SNR data.

% Ask for data path.
[files, path] = uigetfile('.mat','Please load .mat eeg datafile',...
    'MultiSelect','on');

% Ask for data path.
if ischar(files)
    nfile = 1;
else
    nfile = length(files);
end

for t = 1 : nfile
    if nfile ~= 1
        cfile = files{t};
    else
        cfile = files;
    end
    
    % Load file
    load([path cfile]);
    for part = 1:numel(subjects)
        eegDataTable(part).([cfile(1:end-4),'_SNR']) = mean2(ft(part).snr(electrodes,freqList==4,:));
    end
end

eegDataTable = eegDataTable(subList);
%% Save into .mat and .csv files.
% Ouput directory
outputDir = [pwd filesep 'plots_&_datatables' filesep 'dataTables'...
    filesep];
if ~exist(outputDir)
    mkdir(outputDir)
end

outputfile = [outputDir 'EEGdataTable_','_',num2str(datTWin),'_',baseMethod,'_',date,'.mat'];
save(outputfile,'eegDataTable');
struct2csv(outputfile,'eegDataTable');
end

