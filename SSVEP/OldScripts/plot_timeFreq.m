 function [] = plot_timeFreq()
%   PLOT_TIMEFREQ plots time frequency representation. 
%   
%
%
%
%   Emin Serin - Berlin School of Mind and Brain
%
%% Select directory where .mat files locates.
path = uigetdir('Select eeg data directory');

%% Set some parameters.
conds = {'exp','imp'}; % conditions.
pic = 1; % 1: save topoplots as png file, 0: save as pdf(vector based).
subjects = [9 10 15 16 19 20 21 22 23 24 25 26 30 31 32 37 38 39 40 41 42 43 44]; % Subjects used.
cond = {'expF','expS','impF','impS'}; % conditions.
varName = 'WA_data';
baseIdx = [101:201]; % Baseline index -1000 to 0ms.
times = linspace(-2000,10990,1300); % times.
freqs = linspace(1,25,25); % freqs
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

%% Load files.
for c = 1: length(cond)
    cdir = dir([path, filesep,'*',cond{c},'.mat']);
    for f = 1 : length(cdir)
        tmpdat = load(cdir(f).name);
        data.raw(f).(cond{c}) = tmpdat.(varName)(:,:,:);
    end
end
data.raw = data.raw(subList);
%% preTF Computation
% Baseline correction.
for c = 1: numel(cond)
    for part = 1 : numel(subjects)
        % baseline correction.
        mBase = mean(data.raw(part).(cond{c})(:,baseIdx,:),2);
        switch baseMethod
            case 'db'
                % Decibel baseline
                for i = 1:size(data.raw(part).(cond{c}),2)
                    data.ind(part).(cond{c})(:,i,:) = 10*log10(data.raw(part).(cond{c})(:,i,:)./mBase);
                end
            case 'rel'
                for i = 1:size(data.raw(part).(cond{c}),2)
                    % Relative relative baseline.
                    data.ind(part).(cond{c})(:,i,:) = (data.raw(part).(cond{c})(:,i,:)./mBase)-1;
                end
            case 'abs'
                for i = 1:size(data.raw(part).(cond{c}),2)
                    % absolute baseline
                    data.ind(part).(cond{c})(:,i,:) = (data.raw(part).(cond{c})(:,i,:) - mBase);
                end
        end
        % Average per condition.
        data.avg.(cond{c}) = mean(cat(4,data.ind.(cond{c})),4);
    end
end

% Calculate grand mean and difference.
for c = 1: numel(conds)
    % Average.
    % Calculate average grand mean and difference for each condition
    data.avg.([conds{c},'GrandMean']) = (data.avg.([conds{c},'F'])...
        +data.avg.([conds{c},'S']))./2;
    data.avg.([conds{c},'Diff']) = data.avg.([conds{c},'S'])...
        - data.avg.([conds{c},'F']);
    for part = 1:numel(subjects)
        % each participant
        % Calculate grand mean and difference for each condition
        data.ind(part).([conds{c},'GrandMean']) = (data.ind(part).([conds{c},'F'])...
            +data.ind(part).([conds{c},'S']))./2;
        data.ind(part).([conds{c},'Diff']) = data.ind(part).([conds{c},'S'])...
            - data.ind(part).([conds{c},'F']);
    end
end

ifSave = 1;
if ifSave
    % Save preprocessed data file. 
    save(['timeFreqData_',baseMethod,'.mat'],'data','-v7.3');
end
%% More parameters. 
% Channel Selection
elSelect = 'oz';
ind = 'avg'; % ind or avg.

% Ouput directory
outputDir = [pwd filesep 'plots_&_datatables' filesep 'plots'...
    filesep 'timeFrequency' filesep 'tf_' elSelect '_' baseMethod filesep];
if ~exist(outputDir)
    mkdir(outputDir)
end

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

%% Time Frequency representation
if strcmpi(ind,'avg')
    for c = 1 : numel(conds)
        % For each condition.
        fig = figure;
        fig.Name = conds{c};
        plotType = {'GrandMean','S','F','Diff'};
        for p = 1 : numel(plotType)
            subplot(2,2,p);
            contourf(times,freqs,squeeze(mean(permute(data.avg.([conds{c},plotType{p}])(electrodes,:,:),...
                [1,3,2]),1)),50  , 'linestyle', 'none');
            title([plotType{p} ,' ', elTitle],'FontSize',10);
            xlabel('Time (ms)','FontSize',10)
            ylabel('Hz','FontSize',10)
            caxis([0 1])
            xlim([0 10000])
            ylim([2,20]);
            colormap jet;
            cbar;
        end
        if pic
            saveas(gca,[outputDir,'TF_', conds{c},'_avg_',elSelect,'_',baseMethod,'.png'])
        else
            % Save into pdf file.
            fig.PaperPositionMode = 'manual';
            orient(fig,'landscape')
            print(fig,'-dpdf', [outputDir,'TF_', conds{c},'_avg_',elSelect ,'_' ,baseMethod,'.pdf'])
        end
    end
    
else
    for part = 1: numel(subjects)
        for c = 1 : numel(conds)
            % For each condition.
            fig = figure;
            fig.Name = conds{c};
            plotType = {'GrandMean','S','F','Diff'};
            for p = 1 : numel(plotType)
                subplot(2,2,p);
                contourf(times,freqs,...
                    squeeze(mean(permute(data.ind(part).([conds{c},plotType{p}])(electrodes,:,:),...
                    [1,3,2]),1)),50  , 'linestyle', 'none');
                title([plotType{p} ' ' elTitle],'FontSize',10);
                xlabel('Time (ms)','FontSize',10)
                ylabel('Hz','FontSize',10)
                caxis([0 3])
                xlim([0 10000])
                ylim([2,20]);
                colormap jet;
                cbar;
            end
            if pic
                saveas(gca,[outputDir,'TF_', conds{c},'_',...
                    int2str(subjects(part)),'_',elSelect,'_',baseMethod,'.png'])
            else
                % Save into pdf file.
                fig.PaperPositionMode = 'manual';
                orient(fig,'landscape')
                print(fig,'-dpdf', [outputDir,'TF_', conds{c},'_',...
                    int2str(subjects(part)),'_',elSelect,'_',baseMethod,'.pdf'])
            end
        end
    end
end

close all;
end

