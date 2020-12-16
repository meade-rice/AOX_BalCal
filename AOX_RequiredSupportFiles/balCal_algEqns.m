function [in_comb,high,high_CELL] = balCal_algEqns(model_FLAG,in,series,intercept_FLAG,voltagelist,normFLAG)
    %Function creates matrix of predictor variables for algebraic model by
    %combining measured variables (voltages).  Combined terms are determined by
    %the model selected

    %INPUTS:
    %  model_FLAG = Flag for model selected: 3=linear, 2=Trunctated, 1=Full, 4= Custom (assembled same as full)
    %  in  =  Matrix of measured voltages.  Each row is observation, columns are channels
    %  series  =  Series labels for each point
    %  intercept_FLAG  =  Flag if series intercepts should be included. Included for calibration, not validation
    %  voltagelist  =  Chanel labels for voltages
    %  normFlag  =  Flag for if predictor variables should be normalized

    %OUTPUTS:
    %  in_comb = Maxtrix of predictor variables. Each row is an observation, each column is predictor variable
    %  high = Matrix of term hierarchy
    %  high_CELL = Matrix of term hierarchy with labels, mainly for debugging purposes

    %'high' is matrix of term hierarchy.  To find terms needed for a variable
    %to be supported: Find variable in row, go accross row to find '1' in
    %columns
    %'high_CELL' includes labels, mainly for debugging purposes

    % Term order for full equation set:
    % INTERCEPT, F, |F|, F*F, F*|F|, F*G, |F*G|, F*|G|, |F|*G, F*F*F, |F*F*F|, F*G*G, F*G*H

    if nargin <6 % checks number of arguments into function to assign normFLAG. 
        normFLAG = 0; % nominally 0
    end

    if normFLAG == 1
        range = max(in) - min(in);
        scale = max(max(abs(in)));
        shift = min(in) + range/2;
        in_n = (in - shift)./(range/2);
%         in_n = in./scale;
    else
        in_n = in;
    end
    fprintf("\n Normflag = " + string(normFLAG) + "\n");
    % Detect the size of the input
    nPoint = size(in_n,1); %number of data points
    d = size(in_n,2); %data dimensionality.

    % Number of combinations for each term type
    termNum=zeros(1,13);
    termNum(1)=1;
    termNum([2,3,4,5,10,11])=d;
    if d >= 2
        termNum([6,7,8,9])=(d^2-d)/2;
        termNum(12)=factorial(d)/factorial(d-2);
    end
    if d >= 3
        termNum(13)=factorial(d)/(factorial(3)*factorial(d-3));
    end

    glob_intercept=ones(nPoint,1); %Global Intercept Term

    %Generate labels for hierarchy table
    loadlist(1:d)=num2cell(1:d);
    if nargin <5
        voltagelist(1:d)=num2cell(1:d);
    end
    [term_labels, ~]=customMatrix_labels(loadlist,voltagelist,d,d,model_FLAG,'voltages');
    %FOR HIERARCHY OF TERMS: TO FIND TERMS NEEDED FOR VARIABLE TO BE SUPPORTED:
    %FIND VARIABLE IN ROW, GO ACCROSS ROW TO FIND '1' IN COLUMNS

    if model_FLAG == 3
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%LINEAR MODEL
        in_comb = [glob_intercept,in_n];%                                                        3
        
        %Assemble hierarchy matrix
        high=zeros(size(in_comb,2));
        high_CELL=[[{" "};term_labels],[term_labels';num2cell(high)]];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        in_comb = interceptTerms(in_comb,series,intercept_FLAG);
        return
    end

    in_sq = in_n.^2;
    in_sq_high=eye(d); %hierarchy for squared terms



    if d>=2
        j = 1;
        ini_inj = zeros(nPoint,(d^2-d)/2);
        ini_inj_high=zeros((d^2-d)/2,d); %hierarchy for cross terms
        for k = 1:d-1
            for m = k+1:d
                ini_inj(:,j) = in_n(:,k).*in_n(:,m);
                ini_inj_high(j,k)=1; %hierarchy for cross terms
                ini_inj_high(j,m)=1; %hierarchy for cross terms
                
                j = j+1;
            end
        end
    else
        ini_inj=[];
    end

    if model_FLAG == 2
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%TRUNCATED MODEL
        in_comb = [glob_intercept,in_n,      ...                                               2
            in_sq,   ...
            ini_inj];
        
        %Assemble hierarchy matrix
        high=zeros(size(in_comb,2));
        high(1+(d+1:2*d),1+(1:d))=in_sq_high;
        if d>=2
            high(1+(2*d+1:2*d+((d^2-d)/2)),1+(1:d))=ini_inj_high;
        end
        high_CELL=[[{" "};term_labels],[term_labels';num2cell(high)]];
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        in_comb = interceptTerms(in_comb,series,intercept_FLAG);
        return
    end


    abs_in = abs(in);
    if normFLAG == 1
        range = max(abs_in) - min(abs_in);
        shift = min(abs_in) + range/2;
        abs_in = (abs_in - shift)./(range/2);
    end

    in_absin = in_n.*abs_in;
    in_absin_high=[eye(d),eye(d)]; %hierarchy for in_absin terms

    if d>=2
        j = 1;
        abs_iniinj = zeros(nPoint,(d^2-d)/2);
        ini_absinj = zeros(nPoint,(d^2-d)/2);
        absini_inj = zeros(nPoint,(d^2-d)/2);
        
        abs_iniinj_high=zeros((d^2-d)/2,d); %hierarchy for absolute value cross terms
        ini_absinj_high=zeros((d^2-d)/2,2*d); %hierarchy for ini_absinj terms
        absini_inj_high=zeros((d^2-d)/2,2*d); %hierarchy for absini_inj terms
        
        for k = 1:d-1
            for m = k+1:d
                abs_iniinj(:,j) = abs_in(:,k).*abs_in(:,m);
                abs_iniinj_high([j,j],[k,m])=1; %hierarchy for absolute value cross terms
                ini_absinj(:,j) = in_n(:,k).*abs_in(:,m);
                ini_absinj_high([j,j],[k,d+m])=1; %hierarchy for ini_absinj terms
                absini_inj(:,j) = abs_in(:,k).*in_n(:,m);
                absini_inj_high([j,j],[k+d,m])=1; %hierarchy for absini_inj terms
                
                j = j+1;
            end
        end
    else
        abs_iniinj = [];
        ini_absinj = [];
        absini_inj = [];
    end

    if d>=2
        j=1;
        ini_inj_inj= zeros(nPoint, factorial(d)/factorial(d-2)); % Term F*G*G
        ini_inj_inj_high= zeros(termNum(12), sum(termNum)); %Hierarchy for Term F*G*G
        %For assembling term 'F*G*G' a slightly different approach is needed
        %because the order matters:
        % For example, if we have 3 input variables x, y, and z, we want all the
        % following combinations (6): x*y*y, x*z*z, y*x*x, y*z*z, z*x*x, z*y*y
        for k = 1:d
            j_ind=setdiff([1:d],k); %Indices for inner loop
            for m= 1:length(j_ind)
                ini_inj_inj(:,j)=in_n(:,k).*(in_n(:,j_ind(m)).^2);
                
                ini_inj_inj_high([j,j],1+[k,j_ind(m)])=1; %Requires F and G for support
                ini_inj_inj_high(j,sum(termNum(1:3))+j_ind(m))=1; %Requires G*G for support
                
                [ij_rowf,~]=find(ini_inj_high(:,[k,j_ind(m)])); %find indices of terms in 'F*G' (ini_inj) supported by F, G, or H.
                [~,ia,~]=unique(ij_rowf); %Find rows that are supported by only 1 of these terms (F or G)
                ij_rowf(ia)=[]; %Remove rows only supported by 1 term, leaving indices of terms supported by both terms (F and G)
                ini_inj_inj_high(j,sum(termNum(1:5))+ij_rowf)=1;
                j=j+1;
            end
        end
    else
        ini_inj_inj=[];
    end

    if d>=3
        j=1;
        ini_inj_ink= zeros(nPoint, factorial(d)/(factorial(3)*factorial(d-3))); %Term F*G*H
        ini_inj_ink_high= zeros(termNum(13), sum(termNum)); %hierarchy for term F*G*H
        for k = 1:d-1
            for m = k+1:d
                for n = m+1:d
                    ini_inj_ink(:,j)=in_n(:,k).*in_n(:,m).*in_n(:,n);
                    
                    [ij_rowf,~]=find(ini_inj_high(:,[k,m,n])); %find indices of terms in 'F*G' (ini_inj) supported by F, G, or H.
                    [~,ia,~]=unique(ij_rowf); %Find rows that are supported by only 1 of these terms (F, G, or H)
                    ij_rowf(ia)=[]; %Remove rows only supported by 1 term, leaving indices of terms supported by 2 out of 3 terms (F, G, H)
                    ini_inj_ink_high([j,j,j],1+[k,m,n])=1; %Hierarchy requires F, G, and H for support
                    ini_inj_ink_high([j,j,j],sum(termNum(1:5))+ij_rowf)=1;
                    j=j+1;
                end
            end
        end
    else
        ini_inj_ink=[];
    end

    in_cu = in_n.^3;
    in_cu_high=[eye(d),zeros(d),eye(d)]; %hierarchy for cubic terms
    abs_incu = abs_in.^3;
    abs_incu_high=[zeros(d),eye(d),eye(d)]; %hierarchy for absolute value cubic terms
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%FULL MODEL
    in_comb = [glob_intercept, in_n,        ...                                                 1
        abs_in,    ...
        in_sq,     ...
        in_absin,  ...
        ini_inj,   ...
        abs_iniinj,...
        ini_absinj,...
        absini_inj,...
        in_cu,     ...
        abs_incu, ...
        ini_inj_inj, ...
        ini_inj_ink];

    %Assemble hierarchy matrix
    % Term order for full equation set:
    % F, |F|, F*F, F*|F|, F*G, |F*G|, F*|G|, |F|*G, F*F*F, |F*F*F|, F*G*G, F*G*H

    high=zeros(size(in_comb,2));
    high((sum(termNum(1:3))+1:sum(termNum(1:4))),1+(1:d))=in_sq_high;
    high((sum(termNum(1:4))+1:sum(termNum(1:5))),1+(1:2*d))=in_absin_high;
    if d>=2
        high((sum(termNum(1:5))+1:sum(termNum(1:6))),1+(1:d))=ini_inj_high;
        high((sum(termNum(1:6))+1:sum(termNum(1:7))),1+(d+1:2*d))=abs_iniinj_high;
        high((sum(termNum(1:7))+1:sum(termNum(1:8))),1+(1:2*d))=ini_absinj_high;
        high((sum(termNum(1:8))+1:sum(termNum(1:9))),1+(1:2*d))=absini_inj_high;
    end
    high((sum(termNum(1:9))+1:sum(termNum(1:10))),1+(1:3*d))=in_cu_high;
    high((sum(termNum(1:10))+1:sum(termNum(1:11))),1+(1:3*d))=abs_incu_high;
    if d>=2
        high((sum(termNum(1:11))+1:sum(termNum(1:12))),:)=ini_inj_inj_high;
    end
    if d>=3
        high((sum(termNum(1:12))+1:sum(termNum(1:13))),:)=ini_inj_ink_high;
    end
    high_CELL=[[{" "};term_labels],[term_labels';num2cell(high)]];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    in_comb = interceptTerms(in_comb,series,intercept_FLAG);
end

function in_comb = interceptTerms(in_comb,series,intercept_FLAG)
    %Function creates series specific intercept terms for calculating tares

    %INPUTS:
    %  in_comb = Maxtrix of predictor variables. Each row is an observation, each column is predictor variable
    %  series  =  Series labels for each point
    %  intercept_FLAG  =  Flag if series intercepts should be included. Included for calibration, not validation

    %OUTPUTS:
    %  in_comb = Maxtrix of predictor variables. Each row is an observation, each column is predictor variable

    n = size(in_comb,1);
    [~,s_1st,s_id] = unique(series);
    nseries = length(s_1st);
    ints = zeros(n,nseries);
    ids = sub2ind(size(ints),[1:n]',s_id);
    ints(ids) = 1;

    if intercept_FLAG==1 %If preference for series intercepts is on, add 1's for intercept terms: (These are not included for validation)
        in_comb = [in_comb, ints];
    end
end
