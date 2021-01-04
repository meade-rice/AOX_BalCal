clearvars;
%% Loads list of files to be tested (edit list in acsvtest.mat)
load acsvtest.mat; % contains path to test files starting at first subfolder
n = whos; % structure containing information of all loaded variables (= loaded files)
nf = length(n);
%add directory for balcal support files to enable testing on all of them
addpath(genpath('AOX_RequiredSupportFiles'))
rootpath = pwd+"\"; % finds the root path to fully define the path for each test file
% EXPECTED TO RUN FROM ROOT AOX_BALCAL folder
%% Tests .csv data range autopopulation on example .cal files
fpaths = [];
results = struct();
ftype = "cal";
fprintf("****BEGIN TEST: AUTOCSV WITH EXAMPLE .CAL FILES****\n");
warning("off",'AutoCSV:calvalFallback'); % trying to catch the error and report it without showing warning. Currently not working.
for i = 1:length(n)
    f = eval(n(i).name);
    f = rootpath + f;
    fpaths = [fpaths; f];
    find_name = strfind(f,"\");
    find_name  = find_name(end);
    abbr = n(i).name; % used to name fields in results structure
    fc = char(f);
    fname = fc(find_name+1:end);    
    fprintf("Testing: " + fname + "\n");
    ranges = autoCSV(eval(n(i).name),ftype);
    disp(ranges.cap);
    disp(ranges.nat);
    disp(ranges.s1);
    disp(ranges.V);
    disp(ranges.L);
    results.(abbr) = ranges;
    fprintf("_________________\n");
    
end
fprintf("TESTING SUCCESSFULLY COMPLETED. SEE 'results' STRUCTURE.\n");
    
    