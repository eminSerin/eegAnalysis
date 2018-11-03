function [] = convert_sub2Mat(varargin)
%   covert_sub2mat converts each subject's data into a data matrix. If
%   selected, it also performs baseline correction to given data.
%   
%   Input:
%       .mat files: post time-frequency transformation .mat files of each
%           subjects.
%       ifBase: Whether or not it performs baseline correction. 
%           (default: true) 
%       baseMethod: Method used for baseline correction (default: 'rel').
%           'rel':  Relative change. 
%           'db' :  Decibel change. 
%           'abs':  Absolute difference. 
%       times: Vector of time points of each data point. 
%       baseTimeWin: Baseline time window in ms. (default: [-1000,0])
%
%   Output:
%       .mat structure of raw or baseline corrected data of all subjects
%           given. (e.g. subDataMat_rel.mat)
%           
%   Usage:
%       convert2subMat()
%       convert2subMat(true)
%   
%   
%   Emin Serin - Berlin School of Mind and Brain
%
%% Set default parameters and parse input

% Default parameters.
defaultVals.baseTimeWin = [-1000 0]; 
defaultVals.times= linspace(-2000,10990,1300);
defaultVals.ifBase = 1; defaultVals.baseMethod = 'rel';
baseCorOpt = {'rel','abs','db'};

% Input Parser
validationNumeric = @(x) isnumeric(x);
validationBcorOpt = @(x) any(validatestring(x,baseCorOpt));
p = inputParser();
p.PartialMatching = 0; % deactivate partial matching. 
addParameter(p,'ifBase',defaultVals.ifBase);
addParameter(p,'baseMethod',defaultVals.baseMethod,validationBcorOpt);
addParameter(p,'times',defaultVals.times,validationNumeric);
addParameter(p,'baseTimeWin',defaultVals.baseTimeWin,validationNumeric);

% Parse inputs.
parse(p,varargin{:});

% Some parameters.
data.times = p.Results.times;
baseIdx = [find(p.Results.times == p.Results.baseTimeWin(1)):find(p.Results.times == p.Results.baseTimeWin(2))]; % Baseline index

%% Load eeglab mat file and process.
[files, path] = uigetfile('.mat','Please load .mat eeg datafile',...
    'MultiSelect','on');

% Read subject IDs. 
exp = '\d';
regexpf = @(c) regexp(c,exp);
extnum = @(c) str2double(c(regexpf(c)));
subID = unique(cellfun(extnum,files));
data.subID = subID; 

if ischar(files)
    % Check if a single file.
    nfiles = 1;
else
    nfiles = length(files);
end

if p.Results.ifBase
    switch p.Results.baseMethod
        % Select baseline correction method.
        case 'db'
            % Decibel baseline
            baseCorr = @(m,mb) 10*log10(m./mb);
        case 'rel'
            % Relative relative baseline.
            baseCorr = @(m,mb) (m./mb)-1;
        case 'abs'
            % absolute baseline
            baseCorr = @(m,mb) m - mb;
    end
end

% Load data and perform baseline correction.
tic;
nf = 1; % nfile count
for ns = 1:length(subID)
    for i = 1: nfiles/length(subID)
        if nfiles ~= 1
            cfile = files{nf};
        else
            cfile = files;
        end
        
        % Load data files.
        ss = strsplit(cfile,{'_','.'});
        ss = ss{2}; % condition name.
        tmp = load([path cfile]);
        fname = fieldnames(tmp);
        tmp = tmp.(fname{:});
        
        if p.Results.ifBase
            % baseline correction.
            mBase = mean(tmp(:,baseIdx,:),2);
            tmp = baseCorr(tmp,mBase);
        end
        data.(ss)(:,:,:,ns) = tmp;
        nf = nf+1; 
    end
end
% Save matrix
save(['subDataMat_',p.Results.baseMethod,'.mat'],'data','-v7.3');
disp('Done!');

toc; 
end


