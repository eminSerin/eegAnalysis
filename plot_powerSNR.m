function [] = plot_powerSNR()
%PLOT_POWERSNR plots power and signal to noise ratio. 
%   


%% Select directory.
path = uigetdir();

%% Set some parameters.
ind = 'avg'; % ind or avg.
mainEffect = 0; % plot for main effect of task and self identity.
cond = {'expF','expS','impF','impS'};
subjects = [9 10 15 16 17 19 20 23 24 25 26 29 30 31 32]; % Subjects used.
elSelect = 'anterior'; % Electrodes selected.

% Reject subjects.
% eSubject = [15 17 23 31 32]; % subjects to be excluded. 
eSubject = [];
subList = []; 
for s = 1: length(subjects)
    subList = [subList ~ismember(subjects(s),eSubject)];
end
subList = logical(subList); 
subjects = subjects(subList);

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

%% Load data.
for c = 1: numel(cond)
    filedirs = dir([path,filesep,cond{c},'*']);
    load([path,filesep, filedirs.name]);
    ft = ft(subList);
    for d = 1 : numel(ft)
        ave.(cond{c}).power(:,:,d) = mean(ft(d).power,3);
        ave.(cond{c}).snr(:,:,d) = mean(ft(d).snr,3);
    end
    %     ave.(cond{c}) = structfun(@(x) mean(x,1), ave.(cond{c}),'UniformOutput',false);
end
%% Plot
cond = {'exp','imp'};
plotType = {'power','snr'};
ylabels = {'\muV^{2}','SNR'};
for pl = 1: numel(plotType)
    % Ouput directory
    outputDir = [pwd filesep 'plots_&_datatables' filesep 'plots'...
        filesep plotType{pl} filesep elSelect filesep];
    if ~exist(outputDir)
        mkdir(outputDir)
    end  
    % Plot
    if strcmpi(ind,'avg')
        fig = figure;
        for c = 1: numel(cond)
            subplot(2,1,c)
            hold on;
            p = plot(datFreqList,mean(mean(ave.([cond{c},'F']).(plotType{pl})(electrodes,:,:),3),1));
            p = plot(datFreqList,mean(mean(ave.([cond{c},'S']).(plotType{pl})(electrodes,:,:),3),1));
            hold off;
            title([cond{c},'licit condition ',elTitle]);
            legend('F','S')
            xlabel('Hz', 'FontSize',10)
            ylabel(ylabels{pl}, 'FontSize',10)
            xlim([3 20])
        end
        
        % Save into pdf file.
        fig.PaperPositionMode = 'manual';
        orient(fig,'landscape')
        print(fig,'-dpdf', [outputDir,plotType{pl},'_',elSelect,'_avg','.pdf'])
    else
        for part = 1: numel(subjects)
            fig = figure;
            for c = 1: numel(cond)
                subplot(2,1,c)
                hold on;
                p = plot(datFreqList,mean(ave.([cond{c},'F']).(plotType{pl})(electrodes,:,part),1));
                p = plot(datFreqList,mean(ave.([cond{c},'S']).(plotType{pl})(electrodes,:,part),1));
                hold off;
                title([cond{c},'licit condition ',elTitle]);
                legend('F','S')
                xlabel('Hz', 'FontSize',10)
                ylabel(ylabels{pl}, 'FontSize',10)
                xlim([3 20])
            end
            
            % Save into pdf file.
            fig.PaperPositionMode = 'manual';
            orient(fig,'landscape')
            print(fig,'-dpdf', [outputDir,plotType{pl},'_',elSelect,'_',num2str(subjects(part)),'.pdf'])
        end
    end
end
close all;
%% Plot SNR.
if mainEffect
    % SNR difference between conditions
    fig = figure;
    subplot(2,1,1);
    cond = {'exp','imp'};
    hold on;
    for c = 1: numel(cond)
        plot(freqList,(ave.([cond{c},'S']).snr+ave.([cond{c},'F']).snr)./2);
    end
    hold off;
    title(['Signal to noise ratio difference between tasks']);
    legend(cond)
    xlabel('Freq (Hz)', 'FontSize',10)
    ylabel('SNR', 'FontSize',10)
    
    % SNR difference between self and familiar.
    subplot(2,1,2)
    cond = {'F','S'};
    hold on;
    for c = 1: numel(cond)
        plot(freqList,(ave.(['exp',cond{c}]).snr+ave.(['imp',cond{c}]).snr)./2);
    end
    hold off;
    title(['Signal to noise ratio difference between face identities']);
    legend(cond)
    xlabel('Freq (Hz)', 'FontSize',10)
    ylabel('SNR', 'FontSize',10)
    
    % Save into pdf file.
    fig.PaperPositionMode = 'manual';
    orient(fig,'landscape')
    print(fig,'-dpdf', ['SNRmain','.pdf'])
end
close all;

end

