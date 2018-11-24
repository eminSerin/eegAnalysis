function [] = gen_plot(varargin)
%   gen_plot generates different plots of given processed eeg data.
%   The function can generate plots for time-frequency, topomap,
%   time-series, power and signal-to-noise ratio data. It asks user to
%   enter the plot method and and load the dataset file that includes data
%   for required plot. 
%   
%   Input: 
%       plotMethod: Plot method to be generated (default: topomap).
%           topomap: topographical mapping of the eeg data of given time
%               window.
%           timeFreq: Time-frequency contour plotting. 
%           timeSeries: Time series plot. 
%           snr: Plot for signal to noise ratio.
%           power: Power plot. 
%       ifInd: Plot for each subject or average (default: avg). 
%       ifSave: Whether or not save the plots (default: false).
%       ifPic: Whether or not save plots in .png format, else save in .pdf
%           format (default: true).
%       elSelect: Data coming from which electrodes is plotted (default:
%           posterior).
%           posterior: Posterior electrodes (O and PO channels).
%           anterior: Frontal electrodes
%           oz; fcz; p7; p8
%       datTimeWin: Time window of data to be plotted (default: [3000 4000]). 
%           
%
%   Emin Serin - Berlin School of Mind and Brain
%
%% Set default parameters and parse input

% Default parameters.
defaultVals.ifInd = 'avg'; defaultVals.ifSave = 0;
defaultVals.ifPic = 1; defaultVals.datTimeWin = [3000,4000];
defaultVals.elSelect= 'posterior';
defaultVals.plotMethod= 'topomap';
elSelectOpt = {'posterior','anterior','oz','fcz','p7','p8'};
ifIndOpt = {'avg','ind'};
plotMethodOpt = {'topomap','timeFreq','timeSeries','snr','power'};

% Input Parser
validationNumeric = @(x) isnumeric(x);
validationElSelOpt = @(x) any(validatestring(x,elSelectOpt));
validationIfIndOpt = @(x) any(validatestring(x,ifIndOpt));
validationPlotMethod = @(x) any(validatestring(x,plotMethodOpt));
p = inputParser();
p.PartialMatching = 0; % deactivate partial matching.
addParameter(p,'plotMethod',defaultVals.plotMethod,validationPlotMethod);
addParameter(p,'ifInd',defaultVals.ifInd,validationIfIndOpt);
addParameter(p,'ifSave',defaultVals.ifSave);
addParameter(p,'ifPic',defaultVals.ifPic);
addParameter(p,'elSelect',defaultVals.elSelect,validationElSelOpt);
addParameter(p,'datTimeWin',defaultVals.datTimeWin,validationNumeric);

%% TESTING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The codes below are for testing the alpha version of the script. Please
% delete this section to make input parsing functional. 
idxFreq = 4; % index of target frequency.
ifPic = 1; % 1: save topoplots as png file, 0: save as pdf(vector based).
ind = 'avg'; % ind or avg.
elSelect = 'posterior';
datTimeWin = [4000,5000]; % task Time Window
plotMethod = 'power';
ifSave = 1;
freqs = [1:25];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Load data and set some parameters.
% Parse inputs.
parse(p,varargin{:});

% Ask mat file to load.
[file, path] = uigetfile('.mat','Please load .mat eeg datafile');
% Load mat file.
data = load([path file]);
fname = fieldnames(data);
data = data.(fname{:});
if ~ismember(plotMethod,{'power','snr'})
    % DataIdx if not power or snr plot requested.
    datIdx = [find(data.times == datTimeWin(1)):find(data.times == datTimeWin(2))]; % Task index.
end
nSub = length(data.subID);

% Extract condition names.
fname = fieldnames(data); % fieldnames.
conds = fname(4:end); % condition names.

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

% Conditions
cond = {'exp','imp'};

%%
nf = 1;
% Select plot method.
switch plotMethod
    case {'topomap','timeFreq'}
        % Conditions and plot types.
        plotType = {'GrandMean','S','F','Diff'};
        % Grand mean and difference.
        for c = 1: numel(cond)
            data.([cond{c},'GrandMean']) = (data.([cond{c},'F'])...
                +data.([cond{c},'S']))./2;
            data.([cond{c},'Diff']) = data.([cond{c},'S'])...
                - data.([cond{c},'F']);
        end
        if strcmpi(plotMethod,'topomap')
            % Load any .set file for importing channel logs.
            [file, path] = uigetfile('.set','Please load any .set eeg datafile');
            EEG = pop_loadset(file,path); % Load data.
            % Topoplots
            for c = 1:numel(cond)
                if strcmpi(ind,'ind')
                    for part = 1: nSub
                        fig(nf) = figure;
                        fig(nf).Name = [num2str(data.subID(part)),'_',cond{c}];
                        for p = 1:numel(plotType)
                            subplot(2,2,p);
                            topoplot(mean(data.([cond{c},plotType{p}])(:,datIdx,idxFreq,part),2),...
                                EEG.chanlocs,'maplimits','maxmin','conv','off', 'headrad',0);
                            title(plotType{p});
                            caxis('auto');
                            cbar;
                        end
                        nf = nf+1;
                    end
                else
                    fig(nf) = figure;
                    fig(nf).Name = ['avg','_',cond{c}];
                    for p = 1:numel(plotType)
                        subplot(2,2,p);
                        topoplot(mean(mean(data.([cond{c},plotType{p}])(:,datIdx,idxFreq,:),2),4),...
                            EEG.chanlocs,'maplimits','maxmin','conv','on', 'headrad',0);
                        title(plotType{p});
                        caxis('auto');
                        cbar;
                    end
                    nf = nf+1;
                end
            end
        else
            % Time Frequency representation
            if strcmpi(ind,'ind')
                for part = 1: nSub
                    for c = 1 : numel(cond)
                        % For each condition.
                        fig(nf) = figure;
                        fig(nf).Name = [num2str(data.subID(part)),'_',cond{c}];
                        for p = 1 : numel(plotType)
                            subplot(2,2,p);
                            contourf(data.times,freqs,squeeze(mean(permute(data.([cond{c},...
                                plotType{p}])(electrodes,:,:,part),[1,3,2]),1)),50  , 'linestyle', 'none');
                            title([plotType{p} ' ' elTitle],'FontSize',10);
                            xlabel('Time (ms)','FontSize',10)
                            ylabel('Hz','FontSize',10)
                            caxis('auto')
                            xlim([0 10000])
                            ylim([2,20]);
                            colormap jet;
                            cbar;
                        end
                        nf = nf+1;
                    end
                end
            else
                for c = 1 : numel(cond)
                    % For each condition.
                    fig(nf) = figure;
                    fig(nf).Name = ['avg','_',cond{c}];
                    for p = 1 : numel(plotType)
                        subplot(2,2,p);
                        contourf(data.times,freqs,squeeze(mean(mean(permute(data.([cond{c},...
                            plotType{p}])(electrodes,:,:,:),[1,3,2,4]),1),4)),50  , 'linestyle', 'none');
                        title([plotType{p} ,' ', elTitle],'FontSize',10);
                        xlabel('Time (ms)','FontSize',10)
                        ylabel('Hz','FontSize',10)
                        caxis('auto')
                        xlim([0 10000])
                        ylim([2,20]);
                        colormap jet;
                        cbar;
                    end
                    nf = nf+1;
                end
            end
        end
    case 'timeSeries'
        % Set some parameters
        alphaVal = 1.95; %
        rtOverlay = true;
        if rtOverlay
            % Import behavioral data.
            [behFile, behpath] = uigetfile('.mat','Please load .mat behavioral data table');
            load([behpath behFile]);
        end
        yLabel = '\muV^{2}';
        for c = 1: numel(conds)
            data.([conds{c},'std']) = std(mean(data.(conds{c})(electrodes,:,idxFreq,:),1),0,4); % std.
            data.([conds{c},'gm']) = mean(mean(data.(conds{c})(electrodes,:,idxFreq,:),1),4); % grand mean
            data.([conds{c},'se']) = data.([conds{c},'std']) ./ nSub; % standard error
            data.([conds{c},'lb']) = data.([conds{c},'gm'])... % lower bound
                - data.([conds{c},'se']).*alphaVal;
            data.([conds{c},'ub']) = data.([conds{c},'gm'])... % upper bound
                + data.([conds{c},'se']).*alphaVal;
        end
        % Plot Time Series with confidence intervals.
        identity = {'F','S'}; % face identity.
        cmap = lines(numel(identity)); % colormap
        if strcmpi(ind,'ind')
            for part = 1: nSub
                fig(nf) = figure;
                fig(nf).Name = num2str(data.subID(part));
                for c = 1 : numel(cond)
                    subplot(2,1,c)
                    hold on;
                    for i = 1 : numel(identity)
                        % Plot time series.
                        hl(i) = line(data.times,mean(data.([cond{c},...
                            identity{i}])(electrodes,:,idxFreq,part),1),'Color',cmap(i,:));
                    end
                    xlim([0 10000])
                    if rtOverlay && strcmpi(cond{c},'exp')
                        for i = 1: numel(identity)
                            % Plot mean rt values.
                            yl = get(gca,'YLim');
                            RT = dataTable(part).(['exp',identity{i},'_rt']);
                            plot([RT,RT],yl,'--','Color',cmap(i,:));
                        end
                    end
                    hold off;
                    legend(hl,'F','S')
                    xlabel('Time')
                    ylabel(yLabel)
                    title(strcat(cond(c),'licit',' ',elTitle))
                end
                nf = nf+1;
            end
        else
            fig(nf) = figure;
            fig(nf).Name = 'avg';
            for c = 1 : numel(cond)
                subplot(2,1,c)
                hold on;
                for i = 1: numel(identity)
                    hl(i) = line(data.times,data.([cond{c},identity{i},'gm']),...
                        'Color',cmap(i,:));
                    hp = patch([data.times,fliplr(data.times)],...
                        [data.([cond{c},identity{i},'lb']),fliplr(data.([cond{c},identity{i},'ub']))],cmap(i,:));
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
            nf = nf+1;
        end
    case {'power','snr'}
        if strcmpi(plotMethod,'snr')
            ylab = 'SNR';
        else
            ylab = '\muV^{2}';
        end
        % Plot
        if strcmpi(ind,'ind')
            for part = 1: nSub
                fig(nf) = figure;
                fig(nf).Name = num2str(data.subID(part));
                for c = 1: numel(cond)
                    subplot(2,1,c)
                    hold on;
                    plot(data.freqs,mean(data.([cond{c},'F']).(plotMethod)(electrodes,:,part),1));
                    plot(data.freqs,mean(data.([cond{c},'S']).(plotMethod)(electrodes,:,part),1));
                    hold off;
                    title([cond{c},'licit condition ',elTitle]);
                    legend('F','S')
                    xlabel('Hz', 'FontSize',10)
                    ylabel(ylab, 'FontSize',10)
                    xlim([3 20])
                end
                nf = nf+1;
            end
        else
            fig(nf) = figure;
            fig(nf).Name = 'avg';
            for c = 1: numel(cond)
                subplot(2,1,c)
                hold on;
                plot(data.freqs,mean(mean(data.([cond{c},'F']).(plotMethod)(electrodes,:,:),3),1));
                plot(data.freqs,mean(mean(data.([cond{c},'S']).(plotMethod)(electrodes,:,:),3),1));
                hold off;
                title([cond{c},'licit condition ',elTitle]);
                legend('F','S')
                xlabel('Hz', 'FontSize',10)
                ylabel(ylab, 'FontSize',10)
                xlim([3 20])
            end
            nf = nf+1;
        end
end
%% Save figures.
if ismember(plotMethod,{'topomap'})
    outputDir = [pwd filesep 'plots_&_datatables' filesep 'plots'...
        filesep plotMethod filesep elSelect '_'...
        int2str(datTimeWin(1)) '_' int2str(datTimeWin(2)) filesep];
else
    outputDir = [pwd filesep 'plots_&_datatables' filesep 'plots'...
        filesep plotMethod filesep elSelect filesep];
end
if ~exist(outputDir)
    mkdir(outputDir)
end
if ifSave
    for nf = 1:length(fig)
        if ifPic
            saveas(fig(nf),[outputDir,fig(nf).Name,'.png'])
        else
            % Save into pdf file.
            fig(nf).PaperPositionMode = 'manual';
            orient(fig(nf),'landscape')
            print(fig(nf),'-dpdf', [outputDir,fig(nf).Name,'.pdf'])
        end
    end
end
close all;
end
