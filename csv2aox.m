%Jimin Park
%11/3/2020
%csv2aox.m

%This code will take an engine deck in .csv and format it for AOX_BalCal

clear
clc

%% Reading in data
filename = 'FPR120_engine_ColumnData';                                      %name of the input engine deck2
foutname = 'FPR120_engine_AOX_Format';                                      %name of the output file

fileID = fopen([filename '.csv'],'r'); 
C_text1 = fgetl(fileID);                                                    %get first 2 lines of headers
C_text2 = fgetl(fileID);
data = readmatrix([filename '.csv']);                                       %read data

fclose('all');
%%
fileID = fopen([foutname '.csv'],'w');                                      %create or rewrite output file
fprintf(fileID, ';,%s\n', C_text1);                                         %print the 2 headers
fprintf(fileID, ';,%s\n', C_text2);

fprintf(fileID, '\n\n\n\n\n\n;\n');                                         %print headers, load capacities, etc
fprintf(fileID, ';load and response symbols\n');
fprintf(fileID, ',,,,Net Thrust, Fuel Flow, WC2, EINOx,ALT,T4/T2,Mach\n');
fprintf(fileID, ';load and response units\n');
fprintf(fileID, ',,,,lbs,lbs/min,lbs/min,1,ft,1,1\n');
fprintf(fileID, ';,load capacities\n');

loadcap = [ceil(max(abs(data(:,7)))/100)*100,ceil(max(abs(data(:,8)))/100)*100, ...     %find the max absolute values of each data column and round appropriately for load capacities
    ceil(max(abs(data(:,11)))/100)*100,ceil(max(abs(data(:,14)))/10)*10,...
    ceil(max(abs(data(:,4)))/1000)*1000,ceil(max(abs(data(:,13)./data(:,12)))),...
    round(max(abs(data(:,3))),1)];


fprintf(fileID, ',,,,%d,%d,%d,%d,%d,%d,%f\n', loadcap(1), loadcap(2), loadcap(3), loadcap(4), loadcap(5), loadcap(6), loadcap(7));      %print load capacities
fprintf(fileID, ';,natural zeros\n');
for i = 1:4                                                                 %natural zeros section
    fprintf(fileID, ',%d,A,%d,,,,,0,0,0\n',1000+i, 90*(i-1));
end
fprintf(fileID,'\n;,Point ID,Series1,Series2,Net Thrust,Fuel Flow,WC2,EINOx,Alt,T4/T2,M\n');

for i = 1:length(data)                                                      %printing data
   fprintf(fileID,',%d,1,A,%f,%f,%f,%f,%d,%f,%f\n',i,data(i,7),data(i,8),data(i,11),data(i,14),data(i,4),data(i,13)./data(i,12),data(i,3)); 
end
fclose('all');