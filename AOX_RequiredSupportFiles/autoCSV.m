% (c) 2020 Akshay Naik, NASA AOX
function [ranges] = autoCSV(fname,type)
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
    %
    % OUTPUTS:
    % ranges: structure containing the data ranges required by BalCal
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
    [nr,nc] = size(C); % number of rows, columns in entire sheet
    warning('off','backtrace');
    %% detect name of first and last independent and dependent variables 
    % assume data is arranged as all independent vars followed by all dependent vars, columnwise left to right
    % expected format (see documentation--in progress)
    % independent vars
    
    % first, try to find a header that describes the INDEPENDENT and DEPENDENT variables
    varlocs = zeros(4,2); % preallocate array to hold locations of first and last ind and dep vars
    V = char(C(find(contains(C(:,1),"VARIABLE")),1)); % detect a header with variable names

    switch type
        case {"cal","val","app"} % Calibration File
             % find first column of data required for input to BalCal
            A = find(contains(C,"symbols")); % numerical values always start below this string in bal file template
            hrow = A+1;

            %% Assign "varlocs" to determine range of ind. and dep. vars
            if isempty(V) == 0 && size(V,1) == 2   % expects V to exist (variable description header exists) and be size (2,n)
                fallback = 0;
                vcount = 1;
                % iterate over independent and dependent variables (loops twice:
                % 1st for indep., 2nd for dep. 
                nv = []; % initialize array containing names of first and last variables
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
                        v2start = coms_i(end)+1;
                    end
                    nv1 = string(V(i,v1+1:v1end)); nv1 = strtrim(nv1); % NAME of first var
                    nv2 = string(V(i,v2start:v2-1)); nv2 = strtrim(nv2); % NAME of 2nd var, coms_i+2 because comma + space
                    nv = [nv; [nv1 nv2]]; % NV: FIRST ROW = IND. VAR, 2ND ROW = DEP. VAR
                    [vrow,~] = find(contains(C,nv1),1,'last'); %finds the row containing header for "data for analysis" portion

                    symbs = C(hrow,:);
                    %find columns of the first and last variable
                    vcol = zeros(1,2);
                    for n=1:nv.size(2)
                        for j = 1:length(symbs)
                            if strcmp(nv(i,n),symbs(j)) == 1 % find column of FIRST variable
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
                warning("Unable to detect a header with a description of the independent and dependent variable names. Falling back to standard BALFIT var names detection.\n","AutoCSV:calvalFallback");
                fallback = 1;
                nL = ["N1","NF1","PM1"]; % recommended balfit variable names (loads)
                for i=1:length(nL)
                    try
                        [vx,vy] = find(contains(C,nL(i)),1,"last"); %check each possible balfit variable name for existence of gage variable
                        if isempty(vx) == 0 % as soon as one of the possible names works, break loop and continue
                            bfvar = i;
                            break;
                        end
                    end
                end
                if isempty(vx) == 1 % Irregular naming scheme and no variable names listed is unfortunate
                    % these are hard fallback values
                    varlocs(:,1) = 1;
                    varlocs(3,2) = 1;
                    varlocs(2,2) = 1;
                    varlocs(4,2) = 1;
                    warning("Standard BALFIT detection also failed. **Please add information to input file according to documentation or manually fill data ranges.**\n");
                else % standard balfit detection
                    nv1 = nL(bfvar);
                    nv2 = "r" + nv1;
                    vrow = vx; % row of data headers
                    Vhead = C(vrow,:);
                    if vy < (size(Vhead,2)/2 + 3)
                        [~,vy] = find(contains(Vhead,"R1"),1,"first"); % check for dep var written as "R1"--sometimes used instead of correct terminology ("rN1")
                        nv2 = "R1";
                    end
                    varlocs(:,1) = vrow;
                    varlocs(3,2) = vy;
                    varlocs(2,2) = vy-1;
                    varlocs(4,2) = size(Vhead,2);
                    [~,v1y] = find(contains(C(vrow,:),"N1"),1,"first");
                    varlocs(1,2) = v1y;
                    nv = [nv1,C(varlocs(2,1),varlocs(2,2));nv2,C(varlocs(4,1),varlocs(4,2))];
                end
            end
            %% Assign data ranges
%             % Range for Independent Variable
%             Irange = [(string(alphabet(varlocs(1,2))) + string(varlocs(1,1)+1)),(string(alphabet(varlocs(2,2)))+string(nr))];
%             % Range for Dependent Variable
%             Drange = [(string(alphabet(varlocs(3,2))) + string(varlocs(3,1)+1)),(string(alphabet(varlocs(4,2)))+string(nr))];

            % finds and reads out the units for each variable (balcal specific)
            urow = hrow+2; % row that contains unit descriptions
            units = C(urow,min(varlocs(:,2)):nc); % units of each variable

            % Range for Natural Zeros
            % natural zeros correspond to independent variable (for balcal: gage)
            if C(A+7,1) == "" % some files have a header before natural zeros array--checks for this (cell is not empty if header exists) and adjusts detected location accordingly
                N = A+7;
            else
                N = A+8;
            end
            % check if ind. or dep. variable has natural zeros
            % the variable WITHOUT natural zeros is the LOAD variable
            if isempty(char(C(N,varlocs(1,2)))) == 1 % no natural zeros for ind. var
                nc1 = varlocs(3,2); % nat0's correspond to dependent variables
                nc2 = varlocs(4,2);
                lc1 = varlocs(1,2);
                lc2 = varlocs(2,2);
                nat0nv = 2; % assigns row of nv (variable names) to check when detecting natural zeros array
            elseif isempty(char(C(N,varlocs(3,2)))) == 1 % no natural zeros for dep. var
                nc1 = varlocs(1,2); % nat0's correspond to independent variables
                nc2 = varlocs(2,2);
                lc1 = varlocs(3,2);
                lc2 = varlocs(4,2);
                nat0nv = 1; % assigns row of nv (variable names) to check when detecting natural zeros array
            end
            for ncheck = N:nr % iterate down the rows to find the end of natural zeros array
                % Nat zeros ends either in a blank line or with header. First come first serve
                if isempty(char(C(ncheck,nc1))) == 1 % checks for blank line
                    n_end = ncheck-1; % assigns the last row of the natural zeros array
                    break;
                elseif strcmp(C(ncheck,nc1),nv(nat0nv,1)) == 1 % checks for point ID header
                    n_end = ncheck-1; % assigns the last row of the natural zeros array
                    break;
                else
                    continue
                end
            end
            % Note: For balance mode, varlocs(:,1) are ALL vrow, so identical. Inputted seperately for consistency with general function mode
            % Range for "Loads" (load)
            indL1 = varlocs(1,1)+1;
            Lrange = [(string(alphabet(lc1)) + string(indL1)),(string(alphabet(lc2))+string(nr))];
            % Range for "Voltages" (gage)
            indV1 = varlocs(3,1)+1;
            Vrange = [(string(alphabet(nc1)) + string(indV1)),(string(alphabet(nc2))+string(nr))];
            
            % Range for Natural Zeros
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
            %% Write to output structure
            ranges.cap = caprange;
            ranges.nat = nat0range;
            ranges.s1 = s1range;
            ranges.L = Lrange;
            ranges.V = Vrange;
        case "gen"
            %% Variables Already Detected. Finds their locations and assigns data ranges.
            vcount = 1;
            % iterate over independent and dependent variables (loops twice:
            % 1st for indep., 2nd for dep. 
            nv = []; % initialize array containing names of first and last variables
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
                    v2start = coms_i(end)+1;
                end
                nv1 = string(V(i,v1+1:v1end)); nv1 = strtrim(nv1); % NAME of first var
                nv2 = string(V(i,v2start:v2-1)); nv2 = strtrim(nv2); % NAME of 2nd var, coms_i+2 because comma + space
                nv = [nv; [nv1 nv2]]; % NV: FIRST ROW = IND. VAR, 2ND ROW = DEP. VAR
                [vrow,~] = find(contains(C,nv1),1,'last'); %finds the row containing header for "data for analysis" portion

                symbs = C(vrow,:);
                %find columns of the first and last variable
                vcol = zeros(1,2);
                for n=1:nv.size(2)
                    for j = 1:length(symbs)
                        if strcmp(nv(i,n),symbs(j)) == 1 % find column of FIRST variable
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
                % Range for Independent Variable
            Irange = [(string(alphabet(varlocs(1,2))) + string(varlocs(1,1)+1)),(string(alphabet(varlocs(2,2)))+string(nr))];
            % Range for Dependent Variable
            Drange = [(string(alphabet(varlocs(3,2))) + string(varlocs(3,1)+1)),(string(alphabet(varlocs(4,2)))+string(nr))];
            %% Write to output structure
            ranges.I = Irange;
            ranges.O = Drange;
    end
    ranges.varlocs = varlocs;
    fprintf("CSV Data Detection finished. Refer to warnings, if any.\n");
        % debug--check the outputs
    %     disp(caprange)
    %     disp(nat0range)
    %     disp(s1range)
    %     disp(Irange)
    %     disp(Drange)
    %     fprintf("stop");
end
