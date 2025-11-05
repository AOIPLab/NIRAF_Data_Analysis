% NIRAF Data Compilation
% Created by: Jenna Grieshop
% Date created: 4/30/2024
% 
% Purpose: Script to analyze results from the NIRAF_Data_Extraction.m script
% This script organizes data from all subjects into two csv files. 
% 
% Inputs: Folder with subjects' NIRAF Data Extraction results only NOT
% including the summary results that are also created by the previous
% script. Do not have any other files in the folder before running.
% 
% Outputs: saves to Summary Files folder within input folder
% 
% NIRAF_Data_Compilation_ALL_Data_date:
% Has a summary of all the data - each location, if the subjects' data
% contributed to the location (1 - yes, 0 - no), average intensity at that
% location, and the number of subjects' data that is included in the
% average.
% 
% NIRAF_Data_Compilation_[-4.0,4.0]_Data_date:
% Lists all locations between -4 to 4 across all subjects. Each location is
% listed for each subject, and the average value for that subject and
% location is also listed. This was added at Z. Hahn's request

% NIRAF_Data_Compilation_ALL_LISTED_Data_date:
% Lists all locations across all subjects. Each location is
% listed for each subject, and the average value for that subject and
% location is also listed. This is mainly created for statistical purposes
% and was added at J. Carroll's request 11/4/2025
% 
% NIRAF_Data_Compilation_COMMON_Data_date:
% Lists all common locations across all subjects. Each common location is
% listed for each subject, and the average value for that subject and
% location is also listed. This is mainly created for statistical purposes.


clear all
close all
clc


% User selects folder with input data
data_dir_path = uigetdir('.','Select directory containing analysis data');

% Find the files within the chosen directory:
data_dir = dir(data_dir_path);
temp = data_dir;


data_dir_out = strcat(data_dir_path, "\Summary Files");
mkdir(data_dir_out);

% Fix the DOS era issue with the dir function (loads in the parent
% directories '.' and '..')
data_dir = temp(~ismember({temp.name}, {'.', '..', 'Summary Files'}));
fname_list = {data_dir.name}';

% Initialize data cell
data = cell(1, length(data_dir));

% Initialize min and max locations
min_loc = 0;
max_loc = -10;
common_min_loc = -100;
common_max_loc = 100;

subject_ids = zeros(1, length(data_dir));
Header{1} = ' ';

% Find the min and max locations of the bin centers across all subjects
for i = (1:length(data_dir))

    % Finding ultimate min and max across all subjects
    data{i} = readtable(fullfile(data_dir_path, fname_list{i}));
    if min_loc > min(data{i}.BinCenter)
        min_loc = min(data{i}.BinCenter);
    end
    if max_loc < max(data{i}.BinCenter)
        max_loc = max(data{i}.BinCenter);
    end

    
    % Finding common min and max across all subjects
    if common_min_loc < min(data{i}.BinCenter)
        common_min_loc = min(data{i}.BinCenter);
    end
    if common_max_loc > max(data{i}.BinCenter)
        common_max_loc = max(data{i}.BinCenter);
    end

    % Putting file names in the header
    Header{i+1} = data_dir(i).name;
       
end

% Get the step size betweeen the bin centers
step = abs(data{1}.BinCenter(1)-data{1}.BinCenter(2));

all_bin_locs = min_loc:step:max_loc;

% Initialize results tables
results_all = zeros(length(all_bin_locs), length(data_dir));
results_locs_all(:,1) = all_bin_locs;
results_sum = zeros(length(all_bin_locs),1);
results_tot = zeros(length(all_bin_locs),1);
% results_list = zeros(length(all_bin_locs),1);
results_stdev = zeros(length(all_bin_locs),1);


% Find which subjects have data at each possible location
for z = 1:length(results_locs_all)
    count = 1;
    clear results_list;
    for j = 1:length(data_dir)
        for k = 1:length(data{j}.BinCenter)
            if data{j}.BinCenter(k) == results_locs_all(z,1)
                results_all(z,j) = 1;
                results_list(count) = data{j}.Average(k);
                results_sum(z) = results_sum(z) + data{j}.Average(k);
                results_stdev(z) = std(results_list);
                results_tot(z) = results_tot(z) + 1;
                count = count+1;
                break
            else
                results_all(z,j) = 0;
            end
        end    
    end
end


Add additional titles to the headers
Header{length(data_dir)+2} = 'AVG';
Header{length(data_dir)+3} = 'STDEV';
Header{length(data_dir)+4} = 'Subjects';

% Concatenate the results and header matrices
results_combine1 = [results_locs_all, results_all, results_sum./results_tot, results_stdev, results_tot];
results_combine2 = [Header;num2cell(results_combine1)];

% Write the total data results to a csv
writecell(results_combine2, fullfile(data_dir_out, strcat('NIRAF_Data_Compilation_ALL_Data_', string(datetime('now','TimeZone','local','Format','yyyyMMdd')) ,'.csv')));


% Finding and compiling the bins that all subjects have in common
count = 1;
for x = 1:length(data_dir)
    spl = split(data_dir(x).name, '_');
    sub_id = strcat(spl{1},'_',spl{2});
    for y = 1:length(data{x}.BinCenter)
        if data{x}.BinCenter(y) >= common_min_loc && data{x}.BinCenter(y) <= common_max_loc
            common_res{count,1} = data{x}.BinCenter(y);
            common_res{count,2} = data_dir(x).name;
            common_res{count,3} = sub_id;
            common_res{count,4} = data{x}.Average(y);
            count = count+1;
        end
    end
end

% Write the common data results to a csv
writecell(common_res, fullfile(data_dir_out, strcat('NIRAF_Data_Compilation_COMMON_Data_', string(datetime('now','TimeZone','local','Format','yyyyMMdd')) ,'.csv')));


% Finding and compiling the bins that are between -4 to 4 (Request from
% Zach)
count = 1;
for x = 1:length(data_dir)
    spl = split(data_dir(x).name, '_');
    sub_id = strcat(spl{1},'_',spl{2});
    for y = 1:length(data{x}.BinCenter)
        if data{x}.BinCenter(y) >= -4.0 && data{x}.BinCenter(y) <= 4.0
            common_4_res{count,1} = data{x}.BinCenter(y);
            common_4_res{count,2} = data_dir(x).name;
            common_4_res{count,3} = sub_id;
            common_4_res{count,4} = data{x}.Average(y);
            count = count+1;
        end
    end
end

% Write the common data results to a csv
writecell(common_4_res, fullfile(data_dir_out, strcat('NIRAF_Data_Compilation_[-4.0,4.0]_Data_', string(datetime('now','TimeZone','local','Format','yyyyMMdd')) ,'.csv')));

% Finding and compiling the bins that are between overall min to max (Request from
% Joe)
count = 1;
for x = 1:length(data_dir)
    spl = split(data_dir(x).name, '_');
    sub_id = strcat(spl{1},'_',spl{2});
    for y = 1:length(data{x}.BinCenter)
        if data{x}.BinCenter(y) >= min_loc && data{x}.BinCenter(y) <= max_loc
            all_res{count,1} = data{x}.BinCenter(y);
            all_res{count,2} = data_dir(x).name;
            all_res{count,3} = sub_id;
            all_res{count,4} = data{x}.Average(y);
            count = count+1;
        end
    end
end
    
% Write the common data results to a csv
writecell(all_res, fullfile(data_dir_out, strcat('NIRAF_Data_Compilation_ALL_LISTED_Data_', string(datetime('now','TimeZone','local','Format','yyyyMMdd')) ,'.csv')));

    

  











