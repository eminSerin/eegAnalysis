function [] = plot_timeSeries()
%   PLOT_TIMESERIES plots time series data. 
%   
%
%   Emin Serin - Berlin School of Mind and Brain
%
%% Chose files.
clc;
clear;
rtOverlay = 1; % Reaction time overlay to time series plot.
% Load eeglab set file.
[files, path] = uigetfile('.set','Please load .set eeg datafile',...
    'MultiSelect','on');
if rtOverlay
    % Import behavioral data.
    [behFile, behpath] = uigetfile('.mat','Please load .mat behavioral data table');
    load([behpath behFile]);
end
%% Set some parameters.
ind = 'avg'; % ind or avg.
subjects = [9 10 15 16 17 19 20 23 24 25 26 29 30 31 32]; % Subjects used.
times = linspace(-2000,10990,1300); % times.
baseTimeWin = [-1000 0]; % baseline time window.
baseIdx = [find(times == baseTimeWin(1)):find(times == baseTimeWin(2))]; % Baseline index
rtOverlay = 1; % Reaction time overlay to time series plot.
alphaVal = 1.95; % .95 alpha
baseMethod = 'rel'; % 'abs': absolute ,'rel': relative,'db' :decibel
elSelect = 'posterior';

% Ouput directory
outputDir = [pwd filesep 'plots_&_datatables' filesep 'plots'...
    filesep 'TimeSeries' filesep 'ts_' elSelect '_' baseMethod filesep];
if ~exist(outputDir)
    mkdir(outputDir)
end

% Reject subjects.
% eSubject = [15 17 23 31 32]; % subjects to be excluded. 
eSubject = [];
subList = []; 
for s = 1: length(subjects)
    subList = [subList ~ismember(subjects(s),eSubject)];
end
subList = logical(subList); 
subjects = subjects(subList);
dataTable = dataTable(subList);

% Electrodes
posterior = [20 21 22 23 24 25 26 27 28 29 30 31 57 58 59 60 61 62 63 64]; % occipital electrodes.
anterior = [1,2,3,4,5,6,7,33,34,35,36,37,38,39,40,41,42]; % frontal electrodes
oz = [29]; fcz = [47]; p7 = [23]; p8 = [60];

% Select electrodes
switch elSelect
    case 'posterior'
        electrodes = posterior;
        elTitle = '(posterior electrodes only)';
    case 'anterior'
        electrodes = anterior;
        elTitle = '(anterior electrodes only)';
    case 'all'
        electrodes = [1:64];
        elTitle = '';
    case 'oz'
        electrodes = oz;
        elTitle = '(Oz)';
    case 'fcz'
        electrodes = fcz;
        elTitle = '(FCz)';
    case 'p7'
        electrodes = p7;
        elTitle = '(P7)';
    case 'p8'
        electrodes = p8;
        elTitle = '(P8)';
end 

%% Load and compute
clear EEG data
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
    mBase = mean(EEG.data(electrodes,baseIdx,:),2);
    for i = 1:size(EEG.data,2)
        switch baseMethod
            case 'db'
                % Decibel baseline
                data.(cfile(end-7:end-4)).baseCor(:,i,:) = 10*log10(EEG.data(electrodes,i,:) ./mBase);
                yLabel = 'dB';
            case 'rel'
                % Relative relative baseline.
                data.(cfile(end-7:end-4)).baseCor(:,i,:) = (EEG.data(electrodes,i,:) ./mBase)-1;
                yLabel = '\muV^{2}';
            case 'abs'
                % absolute baseline
                data.(cfile(end-7:end-4)).baseCor(:,i,:) = (EEG.data(electrodes,i,:) - mBase);
                yLabel = '\muV^{2}';
        end
    end
    if ~ismember(elSelect,{'oz','fcz','p7','p8'})
        % standard deviation
        data.(cfile(end-7:end-4)).std = std(mean(data.(cfile(end-7:end-4)).baseCor,1),0,3);
        
        % grand mean
        data.(cfile(end-7:end-4)).gm = mean(mean(data.(cfile(end-7:end-4)).baseCor,3),1);
        
        % standard error
        data.(cfile(end-7:end-4)).se = data.(cfile(end-7:end-4)).std ./ sqrt(size(EEG.data,3));
        
        % lower bound
        data.(cfile(end-7:end-4)).le = data.(cfile(end-7:end-4)).gm - ...
            data.(cfile(end-7:end-4)).se*alphaVal;
        
        % upper bound.
        data.(cfile(end-7:end-4)).ue = data.(cfile(end-7:end-4)).gm + ...
            data.(cfile(end-7:end-4)).se*alphaVal;
    else
        % standard deviation
        data.(cfile(end-7:end-4)).std = std(data.(cfile(end-7:end-4)).baseCor,0,1);
        
        % grand mean
        data.(cfile(end-7:end-4)).gm = mean(data.(cfile(end-7:end-4)).baseCor,1);
        
        % standard error
        data.(cfile(end-7:end-4)).se = data.(cfile(end-7:end-4)).std ./ sqrt(size(EEG.data,1));
        
        % lower bound
        data.(cfile(end-7:end-4)).le = data.(cfile(end-7:end-4)).gm - ...
            data.(cfile(end-7:end-4)).se*alphaVal;
        
        % upper bound.
        data.(cfile(end-7:end-4)).ue = data.(cfile(end-7:end-4)).gm + ...
            data.(cfile(end-7:end-4)).se*alphaVal;
    end
end


%% Plot Time Series with confidence intervals.
cond = {'exp','imp'};
identity = {'F','S'}; % face identity.
cmap = lines(numel(identity)); % colormap
if strcmpi(ind,'ind')
    for part = 1: numel(subjects)
        fig = figure;
        for c = 1 : numel(cond)
            subplot(2,1,c)
            hold on;
            for i = 1 : numel(identity)
                if ~ismember(elSelect,{'oz','fcz','p7','p8'})
                    % Plot time series.
                    hl(i) = line(EEG.times,mean(data.([cond{c},identity{i}]).baseCor(:,:,part),1),...
                        'Color',cmap(i,:));
                else
                    hl(i) = line(EEG.times,data.([cond{c},identity{i}]).baseCor(part,:),...
                        'Color',cmap(i,:));
                end
            end
            xlim([0 10000])
            if rtOverlay
                for i = 1: numel(identity)
                    % Plot mean rt values.
                    if strcmpi(cond{c},'exp')
                        yl = get(gca,'YLim');
                        RT = dataTable(part).(['exp',identity{i},'_rt']);
                        plot([RT,RT],yl,'--','Color',cmap(i,:));
                    end
                end
            end
            hold off;
            
            legend(hl,'F','S')
            xlabel('Time')
            ylabel(yLabel)
            title(strcat(cond(c),'licit',' ',elTitle))
        end
        % Save into pdf file.
        fig.PaperPositionMode = 'manual';
        orient(fig,'landscape')
        print(fig,'-dpdf', [outputDir,'timeSeriesConf','_',int2str(subjects(part)),...
            '_',elSelect, '_' ,baseMethod ,'.pdf'])
    end
else
    fig = figure;
    for c = 1 : numel(cond)
        subplot(2,1,c)
        hold on;
        for i = 1: numel(identity)
            hl(i) = line(EEG.times,data.([cond{c},identity{i}]).gm,...
                'Color',cmap(i,:));
            hp = patch([EEG.times,fliplr(EEG.times)],...
                [data.([cond{c},identity{i}]).le,fliplr(data.([cond{c},identity{i}]).ue)],cmap(i,:));
            set(hp, 'facecolor', [cmap(i,1),cmap(i,2:end)+.2], 'edgecolor', 'none');
        end
        if rtOverlay && strcmpi(cond{c},'exp')
            for i = 1: numel(identity)
                % Plot mean rt values.
                mRT = mean([dataTable.(['exp',identity{i},'_rt'])]); % mean rt
                yl = get(gca,'YLim');
                plot([mRT,mRT],yl,'--','Color',cmap(i,:));
            end
        end
        hold off;
        xlim([0 10000])
        legend(hl,'F','S')
        xlabel('Time')
        ylabel(yLabel)
        title(strcat(cond(c),'licit',' ',elTitle))
        alpha(.2);
    end
    % Save into pdf file.
    fig.PaperPositionMode = 'manual';
    orient(fig,'landscape')
    print(fig,'-dpdf', [outputDir,'timeSeriesConf_avg','_',elSelect,'_',baseMethod,'.pdf'])
end
close all;
end

