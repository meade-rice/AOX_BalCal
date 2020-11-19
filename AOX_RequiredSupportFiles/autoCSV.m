% (c) 2020 Akshay Naik, NASA AOX
function [caprange,nat0range,s1range,Irange,Drange] = autoCSV(fname,type)
    % Automatically populates the data ranges requested by BalCal 
    % TO DO: --work for cal and approx files
    %               DETECT the "action" and type of file being read in
    %        --work on button push in balcal gui--COMPLETE
    %       --generalize for any (defined) independent and dependent
    %       variable
    
    % INPUTS:
    % fname: name of the .csv file being read
    % type: type of file to read.
    %       "cal" for calibration files
    %       "val" for validation files
    %       "gen" for general function approximation
    
    % VARIABLE NAMES:
    % NOTE: "Independent" (ind.) and "Dependent" (dep.) variables are only
    % significant in that the first var declared in the input file is
    % considered the "independent" and second var is considered the
    % "dependent"
    % C: cell array of entire input .csv file
    % nr, (nc): number of rows in C (columns)
    % varlocs: holds indices of first and last ind. and dep. vars
    % A: row below which quantitative data in input file begins
    % hrow: row of C that contains the names (symbols) for the ind. and
    % dep. vars
    % 
    %% Initialize
    % makes a string array of the entire .csv file read in (preserves
    % structure of file)
    alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; % to map column numbers to letters--maybe change this to handle any number of excel columns?
    C = string(table2cell(readtable(fname,'Format','auto','ReadVariableNames',0))); %table gets correct size matching csv, convert to string via cell to read data
    [nr,~] = size(C); % number of rows in entire sheet
    
    %% detect name of first and last independent and dependent variables 
    % assume data is arranged as all independent vars followed by all dependent vars, columnwise left to right
    % expected format (see documentation--in progress)
    % independent vars
    
    % first, try to find a header that describes the INDEPENDENT and DEPENDENT variables
    varlocs = zeros(4,2); % preallocate array to hold locations of first and last ind and dep vars
    V = char(C(find(contains(C(:,1),"VARIABLE")),1)); % detect a header with variable names

    switch type
    case {"cal","val"} % Calibration File
         % find first column of data required for input to BalCal
        A = find(contains(C,"symbols")); % numerical values always start below this string in bal file template
        hrow = A+1;
   
    % if caloverride == 1 % for cal or val files only! replace with a check against the BalCal GUI inputs
    %     hrow = A+1; % this find the row that defines ind. and dep. variable symbols
    % else % if header for data analysis part is in a standard format (variable name only)
    %     hrow = vrow; % THIS SHOULDN'T BE HERE. ONCE NON-BALCAL FORMAT IS INTEGRATED THIS HAS TO MOVE
    % end

        %% Assign "varlocs" to determine range of ind. and dep. vars
        if isempty(V) == 0 && size(V,1) == 2   % expects V to exist (variable description header exists) and be size (2,n)
            fallback = 0;
            vcount = 1;
            % iterate over independent and dependent variables (loops twice:
            % 1st for indep., 2nd for dep. 
            for i=1:size(V,1) 
                % detect names of first and last variable
                coms_i = strfind(V(i,:),','); % find commas to separate variable names
                v1 = strfind(V(i,:),'(');
                v2 = strfind(V(i,:),')');
                if isempty(coms_i) == 1 %in the case of only 1 variable
                    solo = 1; % indicates 1 variable
                    v1end = v2-1;
                    v2start = v1+1;
                else
                    solo = 0; % indicates multiple variables
                    v1end = coms_i(1)-1;
                    v2start = coms_i(end)+2;
                end
                nv1 = string(V(i,v1+1:v1end)); % NAME of first var
                nv2 = string(V(i,v2start:v2-1)); % NAME of 2nd var, coms_i+2 because comma + space
                nv = [nv1 nv2];
                [vrow,~] = find(contains(C,nv1),1,'last'); %finds the row containing header for "data for analysis" portion
            
                symbs = C(hrow,:);
                %find columns of the first and last variable
                vcol = zeros(1,2);
                for n=1:length(nv)
                    for j = 1:length(symbs)
                        if strcmp(nv(n),symbs(j)) == 1 % find column of FIRST variable
                            vcol(n) = j;
                        end
                    end
                end
                % assign to varlocs -- stores the limits of independent variable data and dependent variable data
                varlocs(vcount,1) = vrow; % this is the header row for data array
                varlocs(vcount,2) = vcol(1); % column for first variable
                vcount = vcount +1;
                varlocs(vcount,1) = vrow; % this is the header row for data array
                varlocs(vcount,2) = vcol(2); % column for second variable
                vcount = vcount +1;
            end
        else % fallback behavior--assumes ind vars start with "N1" and dep vars start with "rN1" or "R1"
            warning("Unable to detect a header with a description of the independent and dependent variable names. Falling back to standard BALFIT var names detection. \n **Please confirm filled values with source file.**","AutoCSV:calvalFallback");
            fallback = 1;
            [vx,vy] = find(contains(C,"N1"),1,"last"); %check for rN1 as dep var
            nv1 = "N1";
            nv2 = "rN1";
            vrow = vx; % row of data headers
            Vhead = C(vrow,:);
            if vy < (size(Vhead,2)/2 + 3)
                [~,vy] = find(contains(Vhead,"R1"),1,"first"); % check for R1 as dep var
                nv2 = "R1";
            end
            varlocs(:,1) = vrow;
            varlocs(3,2) = vy;
            varlocs(2,2) = vy-1;
            varlocs(4,2) = size(Vhead,2);
            [~,v1y] = find(contains(C(vrow,:),"N1"),1,"first");
            varlocs(1,2) = v1y;
        end
        %% Assign data ranges
        % Range for Load Array (dependent var)
        Irange = [(string(alphabet(varlocs(1,2))) + string(varlocs(1,1)+1)),(string(alphabet(varlocs(2,2)))+string(nr))];
        % Range for Voltage Array (inpendent var)
        Drange = [(string(alphabet(varlocs(3,2))) + string(varlocs(3,1)+1)),(string(alphabet(varlocs(4,2)))+string(nr))];

        % finds and reads out the units for each variable (balcal specific)
        urow = hrow+2; % row that contains unit descriptions
        units = C(urow,:);
        [~,ucol] = find(contains(C(urow,:),"V"));

        % Range for Natural Zeros
        % natural zeros correspond to independent variable (for balcal: gage)
        if C(A+7,1) == "" % some files have a header before natural zeros array--checks for this (cell is not empty if header exists) and adjusts detected location accordingly
            N = A+7;
        else
            N = A+8;
        end
        % check if ind. or dep. variable has natural zeros
        % the variable WITHOUT natural zeros will be defined as the "load"
        % variable
        if isempty(char(C(N,varlocs(1,2)))) == 1 % no natural zeros for ind. var
            nc1 = varlocs(3,2); % nat0's correspond to dependent variables
            nc2 = varlocs(4,2);
            lc1 = varlocs(1,2);
            lc2 = varlocs(2,2);
        elseif isempty(char(C(N,varlocs(3,2)))) == 1 % no natural zeros for dep. var
            nc1 = varlocs(1,2); % nat0's correspond to independent variables
            nc2 = varlocs(2,2);
            lc1 = varlocs(3,2);
            lc2 = varlocs(4,2);
        end
        for ncheck = N:nr % iterate down the rows to find the end of natural zeros array
            if isempty(char(C(ncheck,ucol(1)))) == 1 || strcmp(C(ncheck,ucol(1)),nv2) == 1
                n_end = ncheck-1; % assigns the last row of the natural zeros array
                break;
            else
                continue
            end
        end
        nat0range = [(string(alphabet(nc1)) + string(N)),(string(alphabet(nc2))+string(n_end))];
        
        % Range for Load Capacities
        caprange = [(string(alphabet(lc1)) + string(A+5)),(string(alphabet(lc2))+string(A+5))]; % (range1, range2) for Capacities
        
        % Range for Series 1 Column
        [s1,s2] = find(contains(C(varlocs(1,1),:),"series"),1,"first"); %checks for lowercase series, then capitalized (I've seen both)
        if isempty(s1) || isempty(s2)
            [~,s2] = find(contains(C(varlocs(1,1),:),"Series"),1,"first");
        end
        s1 = varlocs(1,1); % series label always is on the same row as the headers for the analysis data
        s1range = [(string(alphabet(s2)) + string(s1+1)),(string(alphabet(s2))+string(nr))];

    % debug--check the outputs
%     disp(caprange)
%     disp(nat0range)
%     disp(s1range)
%     disp(Irange)
%     disp(Drange)
%     fprintf("stop");
end