function []= struct2csv(struct,specify)

if nargin < 2
    % if no specific structure name, use below.
    specify = 'expInfo';
end
% load struct
data = load(struct);
data = data.(specify);

% Output file name.
splitName = strsplit(struct,'.mat');
csvName = [splitName{1},'.csv'];

% Open csv file.
outputFile = fopen(csvName,'w');

% Write fieldnames as header.
fieldName = fieldnames(data);
nField = length(fieldName);
for fName = 1: nField
    if isnumeric(fieldName{fName})
        data_format = '%f';
    else
        data_format = '%s';
    end
    fprintf(outputFile, data_format, fieldName{fName});
    if fName < nField
        fprintf(outputFile, ',');
    else
        fprintf(outputFile, '\n');
    end
end


% Write data into csv.
for nd = 1 : length(data)
    for fName = 1: nField
        cData = data(nd).(fieldName{fName});
        if isnumeric(cData)
            data_format = '%.3f';
        else
            data_format = '%s';
        end
        fprintf(outputFile, data_format, cData);
        if fName < nField
            fprintf(outputFile, ',');
        else
            fprintf(outputFile, '\n');
        end
    end
end

fclose(outputFile);

end