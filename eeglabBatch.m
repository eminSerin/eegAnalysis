function [EEG] = eeglabBatch()
%%
% eeglabBatch is a function to preprocess the .bdf EEG file for SSVEP
% study. Performs all of the preprocessing steps in semiautomatic way. Asks
% researcher the components/channels to reject. Creates different datasets
% for each condition and saves into input directory.
%
% eeglabBatch requires:
%
% EEGLAB toolbox.
% (https://sccn.ucsd.edu/eeglab/index.php).
%
% fullRankAveRef plugin.
% http://sccn.ucsd.edu/eeglab/plugins/fullRankAveRef0.10.zip
% Please check following link about why we need to use this plugin.
% https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline#Re-reference_the_data_to_average_.2811.2F29.2F2017_updated.29
%
% Usage: [EEG] = eeglabBatch()
%
% Author: Emin Serin / Berlin School of Mind and Brain / 2018

%% Load EEG files.
% Import bdf file.
[eegfile, eegpath] = uigetfile('.bdf','Please select .bdf file');
dataName = input('Subject ID: ','s');
dataName = ['FPVS_', dataName];

% channel locations directory
channelLocs = which('standard-10-5-cap385.elp');

%% Step 1: Import data.
EEG = pop_biosig([eegpath eegfile],'channels',[1:64]);
EEG.setname = ['FPVS_' dataName];

%% Step 2: Resample data.
EEG = pop_resample(EEG,512);

%% Step 3: Bandpass filter.
EEG = pop_eegfiltnew(EEG, 1,100,1690,0,[],1);

%% Step 4: import channel locations.
EEG = pop_chanedit(EEG, 'lookup',channelLocs);
eeglab redraw;

%% Step 5: plot data and check if there is a bad channel and reject.
kValue = 15; % kurtosis threshold.
fprintf('<<<<<Channels whose kurtosis value above %d>>>>>',kValue);
[~,indelec] = pop_rejchan(EEG, 'elec',[1:64] ,'threshold',kValue,'norm','on','measure','kurt');

% Plot channels whose kurtosis value above given value.
color = {}; color(1:length(EEG.chanlocs)) = {'k'}; color(indelec) = {'r'};
eegplot(EEG.data, 'srate', EEG.srate, 'title', 'Scroll component activities -- eegplot()', ...
    'limits', [EEG.xmin EEG.xmax]*1000, 'color', color,'eloc_file',EEG.chanlocs);

% Ask for channels being rejected.
defaultRej = [1,33]; % Default channels to be rejected. Fp1 and Fpz (broken).
chaninterpolate = askNumList(['Enter number of channels you want to interpolate ',...
    '(Fp1,Fpz in default):']);
chaninterpolate = [defaultRej,chaninterpolate];

% Interpolate selected regions.
if ~isnan(chaninterpolate)
    EEG = pop_interp(EEG, chaninterpolate, 'spherical');
end

%% Step 6: Reference to average.
% This step needs fullRankAveRef plugin.
% http://sccn.ucsd.edu/eeglab/plugins/fullRankAveRef0.10.zip Please check
% following link about why we need to use this function.
% https://sccn.ucsd.edu/wiki/Makoto's_preprocessing_pipeline#Re-reference_the_data_to_average_.2811.2F29.2F2017_updated.29
EEG = fullRankAveRef(EEG);

%% Step 8: ICA
% Run ICA and plot components.
EEG = pop_runica(EEG, 'extended',1,'interupt','on');
cDataName = [dataName,'_ica'];
EEG.setname = cDataName;
EEG = pop_saveset( EEG, 'filename', cDataName, 'filepath', eegpath);
% Continue figure.
f = figure('Name','Continue','position',[300, 200, 300, 120]);
t = uicontrol('Style','text',...
    'Position',[0 0 325 100],...
    'String','Please press continue when you decide which components to remove');
h = uicontrol('Position',[20 20 275 40],'String','Continue',...
    'Callback','uiresume(gcbf)');
pop_selectcomps(EEG, [1:64]); % Plot components.
uiwait(gcf); % Wait for response.
close(f);

% Remove selected components.
componentList = askNumList('Enter components you want to remove:');
EEG = pop_subcomp( EEG,componentList, 0);
cDataName = [dataName, '_icaRej'];
EEG.setname = cDataName;
EEG = pop_saveset( EEG, 'filename', cDataName, 'filepath', eegpath);

%% Step 9: Epoch Extraction
cDataName = [dataName,'_epochs'];
EEG.setname = cDataName;
EEG = pop_epoch( EEG, {  '111'  '112'  '113'  '121'  '122'  '123'  '211'  '212'  '213'  '221'  '222'  '223'  },...
    [-2  11], 'newname', cDataName, 'epochinfo', 'yes');
EEG = pop_rmbase( EEG, [-2000     0]);
eeglab redraw;

%% Step 11: Reject epochs with Artifact (only in OCC channels).
epochRejTh = 250; % Epoch rejection threshold.
fprintf('<<<<Epochs with amplitude above %d uV is being rejected.>>>>',epochRejTh)
occEEG = EEG;
occEEG = pop_select(occEEG,'channel',{'PO7' 'PO3' 'O1' 'Oz' 'POz' 'PO8' 'PO4' 'O2'});
[~, rejIndex] = pop_eegthresh(occEEG,1,[1:8] ,-epochRejTh,epochRejTh,-2,10.998,2,0);


%% Reject epochs with pink dot and false positive and create separate .set file for each condition

% Ask behavioral data. 
[behfile, behpath] = uigetfile('.mat','Please select .mat file');
behData = load([behpath,behfile],'expInfo');
behData = behData.expInfo;

% Remove experiment structure without actual trials. 
t = 1;
for i = 1 : length(behData)
    if ~isempty(behData(i).accuracy) 
        tmpdata(t) = behData(i);
        t = t + 1;
    end
end

tmpdata(rejIndex) = []; % remove epochs with artifact. 
tmpdata = rmfield(tmpdata,'trial');

% Create epoch index for each condition. 
cond.imp4Hz = []; cond.imp4Hzself = []; cond.imp4Hzfam = [];
cond.exp4Hz = []; cond.exp4Hzself = []; cond.exp4Hzfam = [];
for t = 1 : length(tmpdata)
    if tmpdata(t).block < 3
        if strcmpi(tmpdata(t).imType,'self')...,
                && ~(strcmpi(tmpdata(t).responseType,'pink') || (~tmpdata(t).accuracy))
            cond.imp4Hz = [cond.imp4Hz,t];
            cond.imp4Hzself = [cond.imp4Hzself,t];
        elseif strcmpi(tmpdata(t).imType,'familiar')...,
                && ~(strcmpi(tmpdata(t).responseType,'pink') || (~tmpdata(t).accuracy))
            cond.imp4Hz = [cond.imp4Hz,t];
            cond.imp4Hzfam = [cond.imp4Hzfam,t];
        end
    else
        if strcmpi(tmpdata(t).imType,'self') && tmpdata(t).accuracy
            cond.exp4Hz = [cond.exp4Hz,t];
            cond.exp4Hzself = [cond.exp4Hzself,t];
        elseif strcmpi(tmpdata(t).imType,'familiar') && tmpdata(t).accuracy
            cond.exp4Hz = [cond.exp4Hz,t];
            cond.exp4Hzfam = [cond.exp4Hzfam,t];
        end
    end
end

% Create separate ".set" file for each condition. 
condfields = fieldnames(cond);
oriEEG = EEG;
for s = 1: length(condfields)
    EEG = pop_selectevent( EEG, 'epoch',[cond.(condfields{s})] ,'deleteevents','off',...
        'deleteepochs','on','invertepochs','off');
    outputName = [dataName, '_', condfields{s}];
    EEG.setname = outputName;
    pop_saveset( EEG, 'filename', outputName, 'filepath', eegpath);
    EEG = oriEEG;
end

disp('<<<<<<<Preprocess finished.>>>>>>>')
%% Nested functions
    function numlist = askNumList(prompt)
        % Ask and returns list of numbers.
        numlist = input(prompt,'s');
        numlist = arrayfun(@(i) str2double(i),strsplit(numlist,{' ',','}));
        if isnan(numlist)
            numlist = [];
        end
    end
end

