% NIRAF Data Compilation
% Created by: Jenna Grieshop
% Date created: 11/4/2025
% 
% Purpose: Script to compile ALL_LISTED data sheets into one master sheet. 
% 
% Inputs: Parent Folder with ALL_LISTED data sheets somewhere within the
% nested folder structure within.
% 
% Outputs: saves to the input folder. The compiled sheet along with a key
% of the order of sheets compiled (the file locations where the sheets
% originated from)
%


clear all
close all
clc

data_compiled = [];

% User selects folder all data
data_dir_path = uigetdir('.','Select directory containing analysis data');

% search for files with ALL_LISTED 
filelist = dir(fullfile(data_dir_path, '**\NIRAF_Data_Compilation_ALL_LISTED_Data*'));

% load in the files
for i=1:length(filelist)
    data{i} = readtable(fullfile(filelist(i).folder, filelist(i).name),'Delimiter', ',');
    file_list_order{i,1} = filelist(i).folder;
    data_compiled = [data_compiled; data{i}];
end

% save the compiled sheet and save key
writetable(data_compiled, fullfile(data_dir_path, strcat('NIRAF_Data_ALL_LISTED_Data_Compiled_Sheet_', string(datetime('now','TimeZone','local','Format','yyyyMMdd')) ,'.csv')));
writecell(file_list_order, fullfile(data_dir_path, strcat('NIRAF_Data_ALL_LISTED_Data_Compiled_Sheet_KEY_', string(datetime('now','TimeZone','local','Format','yyyyMMdd')) ,'.csv')));



