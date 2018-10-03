function [] = plot_topomap()
%PLOT_TOPOMAP Summary of this function goes here
%   Detailed explanation goes here

%% Importing and Descriptive Statistics
clc;
clear;

% Load eeglab set file.
[files, path] = uigetfile('.set','Please load .set eeg datafile',...
    'MultiSelect','on');

%%
% Set some parameters. 
pic = 1; % 1: save topoplots as png file, 0: save as pdf(vector based).
ind = 'avg'; % ind or avg.
subjects = [9 10 15 16 17 19 20 23 24 25 26 29 30 31 32]; % Subjects used.
times = linspace(-2000,10990,1300); % times.
datTimeWin = [4000,5000]; % task Time Window
baseTimeWin = [-1000 0]; % baseline time window.
baseIdx = [find(times == baseTimeWin(1)):find(times == baseTimeWin(2))]; % Baseline index
datIdx = [find(times == datTimeWin(1)):find(times == datTimeWin(2))]; % Task index.
baseMethod = 'rel'; % 'abs': absolute ,'rel': relative,'db' :decibel

% Reject subjects.
% eSubject = [15 17 23 31 32]; % subjects to be excluded. 
eSubject = [];
subList = []; 
for s = 1: length(subjects)
    subList = [subList ~ismember(subjects(s),eSubject)];
end
subList = logical(subList); 
subjects = subjects(subList);

% Ouput directory
outputDir = [pwd filesep 'plots_&_datatables' filesep 'plots'...
    filesep 'topoplots' filesep 'topoplot' '_' int2str(datTimeWin) '_' baseMethod filesep];
if ~exist(outputDir)
    mkdir(outputDir)
end

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
    EEG = pop_loadset(cfile,path); % Load data.
    EEG.data = EEG.data(:,:,subList); 
    
    % baseline correction.
    mBase = mean(EEG.data(:,baseIdx,:),2);
    switch baseMethod
        case 'db'
            for i = 1:size(EEG.data,2)
                % Decibel baseline
                data.(cfile(end-7:end-4)).baseCor(:,i,:) = 10*log10(EEG.data(:,i,:) ./mBase);
                yLabel = 'dB';
            end
        case 'rel'
            for i = 1:size(EEG.data,2)
                % Relative relative baseline.
                data.(cfile(end-7:end-4)).baseCor(:,i,:) = (EEG.data(:,i,:) ./mBase)-1;
                yLabel = '\muV^{2}';
            end
        case 'abs'
            for i = 1:size(EEG.data,2)
                % absolute baseline
                data.(cfile(end-7:end-4)).baseCor(:,i,:) = (EEG.data(:,i,:) - mBase);
                yLabel = '\muV^{2}';
            end
    end
    
end

% Conditions and plot types.
plotType = {'GrandMean','S','F','Diff'};
cond = {'exp','imp'};
% Grand mean and difference.
for c = 1: numel(cond)
    data.([cond{c},'GrandMean']).baseCor = (data.([cond{c},'F']).baseCor...
        +data.([cond{c},'S']).baseCor)./2;
    data.([cond{c},'Diff']).baseCor = data.([cond{c},'S']).baseCor...
        - data.([cond{c},'F']).baseCor;
end
%% Topoplots
for c = 1:numel(cond)
    if strcmpi(ind,'ind')
        for part = 1: numel(subjects)
            fig = figure;
            fig.Name = cond{c};
            for p = 1: 4
                subplot(2,2,p);
                topoplot(mean(data.([cond{c},plotType{p}]).baseCor(:,datIdx,part),2),...
                    EEG.chanlocs,'maplimits','maxmin','conv','off', 'headrad',0);
                title(plotType{p});
                caxis([0 2]);
                cbar;
            end
%             colormap('hot');
            if pic
                saveas(gca,[outputDir 'Topoplot_',cond{c},'licit','_',...
                    int2str(subjects(part)),'_',...
                    int2str(datTimeWin) '_' baseMethod,'.png'])
            else
                % Save into pdf file.
                fig.PaperPositionMode = 'manual';
                orient(fig,'landscape')
                print(fig,'-dpdf', [outputDir 'Topoplot_',cond{c},'licit','_',...
                    int2str(subjects(part)),'_',...
                    int2str(datTimeWin) '_' baseMethod, '.pdf'])
            end
        end
    else
        fig = figure;
        fig.Name = cond{c};
        for p = 1: 4
            subplot(2,2,p);
            topoplot(mean(mean(data.([cond{c},plotType{p}]).baseCor(:,datIdx,:),2),3),...
                EEG.chanlocs,'maplimits','maxmin','conv','on', 'headrad',0);
            title(plotType{p});
            caxis([0 3]);
            cbar;
        end
%         colormap('hot');
        if pic
            saveas(gca,[outputDir 'Topoplot_',cond{c},'licit','_avg','_',...
                    int2str(datTimeWin) '_' baseMethod,'.png'])
        else
            % Save into pdf file.
            fig.PaperPositionMode = 'manual';
            orient(fig,'landscape')
            print(fig,'-dpdf', [outputDir 'Topoplot_',cond{c},'licit','_avg','_',...
                    int2str(datTimeWin) '_' baseMethod,'.pdf'])
        end
    end
end
close all;
end

