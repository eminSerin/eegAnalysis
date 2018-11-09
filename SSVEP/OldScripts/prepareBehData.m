function [] = prepareBehData()
%   PREPAREBEHDATA creates data table for behavioral data.
%
%
%
%   Emin Serin - Berlin School of Mind and Brain
%
%% Load Data.
% Subjects used.
subjects = [9 10 15 16 19 20 21 22 23 24 25 26 30 31 32 37 38 39 40 41 42 43 44]; % Subjects used.

% Load eeglab set file.
[files, path] = uigetfile('.mat','Please load .set eeg datafile',...
    'MultiSelect','on');

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
    
    if any(subjects==str2double(pID))
        % load data file.
        behData = load([path cfile]);
        behData = behData.expInfo;
        
        % Remove experiment structure without actual trials.
        t = 1;
        for i = 1 : length(behData)
            if ~isempty(behData(i).accuracy)
                tmpdata(t) = behData(i);
                t = t + 1;
            end
        end
        
        % Create indices for each condition
        cond.impself = []; cond.impfam = [];
        cond.expself = []; cond.expfam = [];
        cond.explSelf = []; cond.explFam = [];
        cond.exprSelf = []; cond.exprFam = [];
        for t = 1 : length(tmpdata)
            if tmpdata(t).block < 3
                if strcmpi(tmpdata(t).imType,'self') && tmpdata(t).accuracy
                    cond.impself = [cond.impself,t];
                elseif strcmpi(tmpdata(t).imType,'familiar') && tmpdata(t).accuracy
                    cond.impfam = [cond.impfam,t];
                end
            elseif tmpdata(t).block == 3
                if strcmpi(tmpdata(t).imType,'self') && tmpdata(t).accuracy
                    cond.expself = [cond.expself,t];
                    cond.explSelf = [cond.explSelf, t];
                elseif strcmpi(tmpdata(t).imType,'familiar') && tmpdata(t).accuracy
                    cond.expfam = [cond.expfam,t];
                    cond.exprFam = [cond.exprFam t];
                end
            else
                if strcmpi(tmpdata(t).imType,'self') && tmpdata(t).accuracy
                    cond.expself = [cond.expself,t];
                    cond.exprSelf = [cond.exprSelf, t];
                elseif strcmpi(tmpdata(t).imType,'familiar') && tmpdata(t).accuracy
                    cond.expfam = [cond.expfam,t];
                    cond.explFam = [cond.explFam t];
                end
            end
        end
        
        % subject ID.
        dataTable(pNum).ID = pID;
        
        % Reaction Times in ms.
        dataTable(pNum).expS_rt = round(mean([tmpdata(cond.expself).rt])*1000);
        dataTable(pNum).expF_rt = round(mean([tmpdata(cond.expfam).rt])*1000);
        dataTable(pNum).expS_left_rt = round(mean([tmpdata(cond.explSelf).rt])*1000);
        dataTable(pNum).expS_right_rt = round(mean([tmpdata(cond.exprSelf).rt])*1000);
        dataTable(pNum).expF_left_rt = round(mean([tmpdata(cond.explFam).rt])*1000);
        dataTable(pNum).expF_right_rt =  round(mean([tmpdata(cond.exprFam).rt])*1000);
        
        % Accuracy explicit
        dataTable(pNum).expS_acc = sum([(tmpdata(cond.expself).accuracy)])...
            / sum(ismember({tmpdata([tmpdata.block] > 2).imType},'self'));
        dataTable(pNum).expF_acc = sum([(tmpdata(cond.expfam).accuracy)])...
            / sum(ismember({tmpdata([tmpdata.block] > 2).imType},'familiar'));
        dataTable(pNum).expS_left_acc = sum([(tmpdata(cond.explSelf).accuracy)])...
            / sum(ismember({tmpdata([tmpdata.block] == 3).imType},'self'));
        dataTable(pNum).expS_right_acc = sum([(tmpdata(cond.exprSelf).accuracy)])...
            / sum(ismember({tmpdata([tmpdata.block] == 4).imType},'self'));
        dataTable(pNum).expF_right_acc = sum([(tmpdata(cond.exprFam).accuracy)])...
            / sum(ismember({tmpdata([tmpdata.block] == 3).imType},'familiar'));        
        dataTable(pNum).expF_left_acc = sum([(tmpdata(cond.explFam).accuracy)])...
            / sum(ismember({tmpdata([tmpdata.block] == 4).imType},'familiar'));
        
        % Accuracy implicit
        dataTable(pNum).impS_acc = sum([(tmpdata(cond.impself).accuracy)])...
            / sum(ismember({tmpdata([tmpdata.block] < 3).imType},'self'));
        dataTable(pNum).impF_acc = sum([(tmpdata(cond.impfam).accuracy)])...
            / sum(ismember({tmpdata([tmpdata.block] < 3).imType},'familiar'));
        
        
        pNum = pNum + 1;
    end
    
end


%% Save into .mat and .csv files.
outputfile = ['BehavioralDataTable_',date,'.mat'];
save(outputfile,'dataTable');
struct2csv(outputfile,'dataTable');

end

