% NIRAF Data Extraction
% Created by: Jenna Grieshop
% Date created: 5/16/2023
%
% Edited by Aliya Siddiqui 11/1/24 & 2/22/25 to allow for either RGB or grayscale
% inputs. See lines 132-142.
%
% Purpose: Interactive script to calculate average intensity at specific
% samping points (spacing) with specific bin (window) sizes from the fovea.
% 
% Requirements: 
%   - LUT file containing subject ID, nominal scale in umpp, gray
%     level offset from device (different for each subject), axial length, 
%     eye (OS/OD).
%   - Input rgb or gray scale tif files containing the subject ID and eye in the name.
% 
% Inputs: Script prompts user to select LUT file, then prompts to select
% folder containing data files, then prompts for spacing and window sizes.
% The user can select if they'd like automatic or manual contrast adjustment. 
% If manual is chosen, when the image is shown, moments later an image 
% contrast gui appears to be utilized. User is then asked to select the 
% fovea for each image.
% 
% The script uses the foveal coordinates to create a 5px wide region across
% the image horizontally through the fovea. It then averages the 5 pixels 
% for the average intensity at each pixel location across the image. Then 
% it changes the orientation of all the left eye images to match the right
% eye and it begins averaging the values in each window for each sampling 
% point location.
% 
% Outputs: A csv file for each subject (containing bin center from fovea in
% mm (T(-) N(+)), average pixel intensity, and items in bin (# of pixel 
% locations contributing to the average)) will be generated in a 'Results'
% folder in the data folder, another csv containing the fovea x and y coordinates for 
% all subjects is generated in the same location.
% 
% Note: If the window size will overlap with the selections made
% it will give a warning and another chance to set the sampling and window
% size.

% Note: If you interact with the manual contrast gui and then click the seed point
% too quickly after the interaction, warning messages may appear in the
% command window, these do not interfere with the function of the script
% and can be ignored.


clear all
close all
clc


% constants
ideal_AL = 24;
unit_conversion = 1000;

%% User Inputs

% User selects the LUT:
[LUTfile, LUTpath] = uigetfile('.csv','Select the LUT');

fid = fopen(fullfile(LUTpath,LUTfile),'r');
lutData = textscan(fid , '%s %f %f %f %s', 'delimiter', ',');
fclose(fid);

LUT = readcell(fullfile(LUTpath,LUTfile));
% batch_info = table2cell(readtable(fullfile(batch_dir{1,2},batch_dir{1,1})));

% User selects folder with input data
data_dir_path = uigetdir('.','Select directory containing input data');
    
% Find the files within the chosen directory:
data_dir = dir(data_dir_path);
temp = data_dir;

% Fix the DOS era issue with the dir function (loads in the parent
% directories '.' and '..')
data_dir = temp(~ismember({temp.name}, {'.', '..'}));
fname_list = {data_dir.name}';
fname_list = fname_list(randperm(numel(fname_list)));

% Create output 'Results' folder
mkdir(fullfile(data_dir_path,'Results'));
output_folder = fullfile(data_dir_path,'Results');

% set up messages to be displayed to user to set spacing and window in the desired lateral unit
m1 = 'Please enter desired SPACING (mm)';
m2 = 'Please enter the desired WINDOW (mm)';

% user sets spacing and window
spacing = inputdlg(m1);
spacing = str2double(spacing{1});
window = inputdlg(m2);
window = str2double(window{1});

% spacing must be >= window for no overlap
% if not loop until it is or the user can override and use the overlap
while spacing < (window)
    contin = questdlg('WARNING: Window overlap with current spacing and window selections Continue with current selection?', ...
      '', ...
      'YES', 'NO', 'NO');
  if strcmpi(contin, 'YES')
    break;
  else
    % user sets spacing and window
    spacing = inputdlg(m1);
    spacing = str2double(spacing{1});
    window = inputdlg(m2);
    window = str2double(window{1});
  end
end

% user selects automatic or manual contrast adjustment mode
list = {'Automatic','Manual'};
% index = 1 is automatic, index = 2 is manual
[indx,tf] = listdlg('PromptString', 'Select Contrast Adjustment Mode:', 'ListString',list,'SelectionMode','single');

fovea_coords = [];
tracker = 1;

%% Reading in information from LUT file and loading data

% loop to go through each file in folder
for i = (1:length(data_dir))

    index=find( cellfun(@(s) ~isempty(strfind(fname_list{i},s )), lutData{1} ) ); %finds locations in lutData{1} that have matching IDs or eyes as the file names
    if isempty(index)
        fprintf("No item matching %s in LUT file", fname_list{i})
        continue
    end

    for x=1:size(index, 1)
        if x == size(index, 1) % if it is the last/only item in the LUT 
            index = index(x);
            break
        end
        val = index(x+1) - index(x); % checking if there are two eyes from the same subject in LUT
        if val == 1
            index = index(x);
            break
        end
    end

    % Pulling information from LUT:
    subject_ID = LUT{index,1};
    nominal_scale = LUT{index,2}; %umpp
    gl_offset = LUT{index,3};
    axial_length = LUT{index,4};
    eye = LUT{index,5};

    %% open image input data

    % open RGB image and convert to gray scale, OR open grayscale image if
    % already grayscale: [AS Edit on 2/22/25]
    image = im2gray(imread(fullfile(data_dir_path,fname_list{i})));

    if indx == 1
    % show the image with adjusted contrast
        num_dev = 3;
        data_mean = mean(image(:));
        data_std = std2(image(:));
        data_max = max(image(:));
        data_min = min(image(:));
        cmax = min(data_max, data_mean + num_dev * data_std);
        cmin = max(data_min, data_mean - num_dev * data_std);
        imshow(image, [cmin, cmax])
    else
        imshow(image);
        imcontrast;

    end
    
    % draw seed point
    seed = drawpoint;
    % extract coordinates from the seed
    fovea_y = round(seed.Position(2));
    fovea_x = round(seed.Position(1));

    % storing the user selected coordinates into an array
    fovea_coords{tracker,1} = num2str(fovea_x);
    fovea_coords{tracker,2} = num2str(fovea_y);
    name_list{tracker} = fname_list{i};
    tracker = tracker+1;
   

    % get the 5 px tall rectangle centered on the fovea value and average
    % the columns to get profile values
    maxY = fovea_y + 2;
    minY = fovea_y - 2;

    slice = image(minY:maxY, :);

    avgSlice = mean(slice, 1);
    data.X = (0:length(avgSlice)-1)';
    data.Y = avgSlice';
    
    

    %% Preparing the data

    % convert data
    xy_converted = zeros(length(data.X), 2);
    for j= (1:length(data.X))
        % check what eye - if left flip sign so that temporal is negative
        if strcmp(eye,'OD')
            xy_converted(j, 1) = ((data.X(j) - fovea_x) * ((axial_length * nominal_scale)/ideal_AL))/unit_conversion; % now in mm
        else
            xy_converted(j, 1) = -(((data.X(j) - fovea_x) * ((axial_length * nominal_scale)/ideal_AL))/unit_conversion); % now in mm
        end
        xy_converted(j, 2) = data.Y(j) - gl_offset; % now adjusted with offset
    end

    % get list of bin centers
    x_max = max(xy_converted(:,1));
    x_min = min(xy_converted(:,1));

    bin_centers_temporal = (0:-spacing:x_min);
    bin_centers_nasal = (0:spacing: x_max);

    bin_centers_nasal(1) = []; % get rid of second zero before combining
    bin_centers = [flip(bin_centers_temporal), bin_centers_nasal]; % combine

    %%  get averaged value in the bin and number of items in the bin

    % initialize values and arrays
    sum = 0;
    count = 0;
    averages = zeros(length(bin_centers), 1); 
    items_in_bin = zeros(length(bin_centers),1); 

    % loops to go through bin centers and x values
    for m = bin_centers 
        for n = xy_converted(:,1)' 
            if (n >= (m - (window/2))) && (n < (m + (window/2))) % check if the x value is within the bin range
                value_index = find(xy_converted(:,1)==n);
                sum = sum + xy_converted(value_index,2); % add y value to the sum
                count = count + 1;
            end
        end
        bin_index = find(bin_centers==m);
        averages(bin_index) = sum/count;
        items_in_bin(bin_index) = count;
        sum = 0; % reset value
        count = 0; % reset value
    end

    %% format output and save to file

    output_fname = strcat(fname_list{i}, '_NIRAF_Data_Extraction_(', num2str(fovea_x), ',', num2str(fovea_y), ')_', string(datetime('now','TimeZone','local','Format','yyyyMMdd')), '.csv');

    % setting up for table creation
    BinCenter = num2cell(bin_centers');
    Average = num2cell(averages);
    ItemsInBin = num2cell(items_in_bin);
    % Table creation
    T = table(BinCenter, Average, ItemsInBin);
    
    
    % write output file
    writetable(T, fullfile(output_folder,output_fname));
    
end

name_list = name_list';
results = [name_list, fovea_coords];
writecell(results, fullfile(output_folder, strcat('NIRAF_Data_Extraction_Fovea_Coords_', string(datetime('now','TimeZone','local','Format','yyyyMMdd')) ,'.csv')));
close all



        
        

