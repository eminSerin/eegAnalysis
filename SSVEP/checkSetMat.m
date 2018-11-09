%% Compare each pairs from .set and .mat files.
% Load set file and set some parameters.
EEG = pop_loadset('WA2EEG_expS.set','/Users/eminserin/Documents/MATLAB/eegAnalysis/SSVEP/data/wa_data'); % Load data.
baseIdx = [101:201]; % Baseline index -1000 to 0ms.
times = linspace(-2000,10990,1300); % times.
subjects = [9 10 15 16 19 20 21 22 23 24 25 26 30 31 32 37 38 39 40 41 42 43 44]; % Subjects used.
for ns = 1:length(subjects)
    % Plot time series data from Oz from .mat and .set file.
    load(['/Users/eminserin/Documents/MATLAB/eegAnalysis/SSVEP/data/wa_data/' num2str(subjects(ns)) '_expS.mat']);
    s = EEG.data(29,:,ns); % .set file.
    m = WA_data(29,:,4); % .mat file.
    
    mBaseSet = mean(s(:,baseIdx),2); % baseline for .mat data.
    mBaseMat = mean(m(:,baseIdx),2); % baseline for .set data.
    for i = 1:size(m,2)
        % Relative relative baseline.
        ss(:,i) = (s(:,i)./mBaseSet)-1;
        mm(:,i) = (m(:,i)./mBaseMat)-1;
    end
    
    % Plot files to compare data.
    figure;
    hold on;
    plot(times,ss)
    plot(times,mm)
    title(['subject ',num2str(subjects(ns))])
    legend('.set','.mat')
    hold off;
    
    % Set outputDir, create if not exist
    outputDir = ['plots_&_datatables' filesep 'plots' filesep 'checkSetMat' filesep];
    if ~exist(outputDir)
        mkdir(outputDir)
    end
    % Save fig as png file. 
    saveas(gca,[outputDir int2str(subjects(ns)) '_.png'])
end

%% Compare a specific .set data with each .mat files.
% Load set file and set some parameters.
EEG = pop_loadset('WA2EEG_impS.set','/Users/eminserin/Documents/MATLAB/eegAnalysis/SSVEP/data/wa_data'); % Load data.
baseIdx = [101:201]; % Baseline index -1000 to 0ms.
times = linspace(-2000,10990,1300); % times.
subjects = [9 10 15 16 19 20 21 22 23 24 25 26 30 31 32 37 38 39 40 41 42 43 44]; % Subjects used.
sub = 26;
s = EEG.data(29,:,find(sub==subjects)); % .set file.
for ns = 1:length(subjects)
    % Plot time series data from Oz from .mat and .set file.
    load(['/Users/eminserin/Documents/MATLAB/eegAnalysis/SSVEP/data/wa_data/' num2str(subjects(ns)) '_impS.mat']);
    m = WA_data(29,:,4); % .mat file.
    
    mBaseSet = mean(s(:,baseIdx),2); % baseline for .mat data.
    mBaseMat = mean(m(:,baseIdx),2); % baseline for .set data.
    for i = 1:size(m,2)
        % Relative relative baseline.
        ss(:,i) = (s(:,i)./mBaseSet)-1;
        mm(:,i) = (m(:,i)./mBaseMat)-1;
    end
    
    % Plot files to compare data.
    figure;
    hold on;
    plot(times,ss)
    plot(times,mm)
    title(['.set: ',num2str(sub),'.mat: ',num2str(subjects(ns))])
    legend('.set','.mat')
    hold off;
end


%%
close all