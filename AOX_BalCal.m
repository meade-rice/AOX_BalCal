% Copyright 2019 Andrew Meade, Ali Arya Mokhtarzadeh and Javier Villarreal.  All Rights Reserved.
%
%balanceCalibration_with_RBF_8D.m
%requires "balCal_meritFunction.m" to run
%input file: "BuffetBalance-CalDataOfOct2015-3F3M.csv"
%output file: "balCal_output_ALGB.xls"
%output file: "balCal_output_GRBF.xls"
%%
%initialize the workspace
clc;
clearvars;
close all;
workspace;
fprintf('Copyright 2019 Andrew Meade, Ali Arya Mokhtarzadeh and Javier Villarreal.  All Rights Reserved.\n')
% The mean of the approximation residual (testmatrix minus local approximation) for each section is taken as the tare for that channel and section. The tare is subtracted from the global values to make the local loads. The accuracy of the validation, when compared to the known loads, is very sensitive to the value of the tares (which is unknown) and NOT the order of the calibration equations.
% Because of measurement noise in the voltage the APPROXIMATION tare is computed by post-processing. The average and stddev is taken of all channels per section. If the stddev is less than 0.25% of the capacity for any station the tare is equal to the average for that channel. If the stddev is greater than 0.25% then the approximation at the local zero is taken as the tare for that channel and section. The global approximation is left alone but the tare is subtracted from the values to make the local loads. Line 3133.
%
% AJM 6_14_19 This version doesn't seem to have an intercept vector at the global zero. We can calculate the intercept by adding a line to the data set where that tare = the intercepts.
%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       USER INPUT SECTION
out = AOX_GUI;
if out.cancel == 1
    return
end
%TO SELECT Algebraic Model                             set FLAGS.balCal = 1;
%TO SELECT Algebraic and GRBF Model                    set FLAGS.balCal = 2;
FLAGS.balCal = out.grbf;
%DEFINE THE NUMBER OF BASIS FUNCTIONS
numBasis = out.basis;
%
%TO SELECT INDIRECT APPROACH                         set FLAGS.approach = 1;
FLAGS.approach = 0;%out.approach;
%
%SELECT ALGEBRAIC MODEL
%          set FLAGS.model = 1 (full), 2 (trunc), 3 (linear), or 4 (custom);
FLAGS.model = out.model;
%
%TO PRINT LOAD PERFORMANCE PARAMETERS                   set FLAGS.print = 1;
FLAGS.print = out.tables;
%
%TO SAVE DATA TO CSV                                    set FLAGS.excel = 1;
FLAGS.excel = out.excel;
%
%TO PRINT INPUT/OUTPUT CORRELATION PLOTS                 set FLAGS.corr = 1;
FLAGS.corr = out.corr;
%
%TO PRINT INPUT/RESIDUALS CORRELATION PLOTS           set FLAGS.rescorr = 1;
FLAGS.rescorr = out.rescorr;
%
%TO PRINT ORDER/RESIDUALS PLOTS                          set rest_FLAG = 1;
FLAGS.res = out.res;
%
%TO PRINT RESIDUAL HISTOGRAMS                            set FLAGS.hist = 1;
FLAGS.hist = out.hist;
%
%TO SELECT Validation of the Model                     set FLAGS.balVal = 1;
FLAGS.balVal = out.valid;
%
%TO SELECT Approximation from Cal Data              set FLAGS.balApprox = 1;
FLAGS.balApprox = out.approx;
%
%TO FLAG POTENTIAL OUTLIERS                            set FLAGS.balOut = 1;
FLAGS.balOut = out.outlier;
numSTD = out.numSTD;  %Number of standard deviations for outlier threshold.
%
%TO REMOVE POTENTIAL OUTLIERS                          set FLAGS.zeroed = 1;
FLAGS.zeroed = out.zeroed;
%
%TO USE LATIN HYPERCUBE SAMPLING set                          FLAGS.LHS = 1;
FLAGS.LHS = out.lhs;
numLHS = out.numLHS; %Number of times to iterate.
LHSp = out.LHSp; %Percent of data used to create sample.
%
%Uncertainty button outputs
numBoot=out.numBoot;
FLAGS.boot=out.bootFlag;
FLAGS.volt=out.voltFlag;
voltTrust=out.voltTrust;

FLAGS.anova = out.anova;
%                       END USER INPUT SECTION
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       INITIALIZATION SECTION
fprintf('\nWorking ...\n')
% Load data and characterize series
load(out.savePathcal,'-mat');
series0 = series;
[~,s_1st0,~] = unique(series0);
nseries0 = length(s_1st0);
[numpts0, dimFlag] = size(excessVec0);
% Loads:
% loadlabes, voltlabels (if they exist)
% loadCapacities, natzeros, targetMatrix0, excessVec0, series0

% Load the custom equation matrix if using a custom algebraic model
% SEE: CustomEquationMatrixTemplate.csv
if FLAGS.model == 4
    customMatrix = out.customMatrix;
    customMatrix = [customMatrix; ones(nseries0,dimFlag)];
else
    customMatrix = 1;
end

% Load data labels if present, otherwise use default values.
if exist('loadlabels','var')
    loadlist = loadlabels;
    voltagelist = voltlabels;
    reslist = strcat('res',loadlist);
else
    loadlist = {'NF','BM','S1','S2','RM','AF','PLM', 'PCM', 'MLM', 'MCM'};
    voltagelist = {'rNF','rBM','rS1','rS2','rRM','rAF','rPLM','rPCM','rMLM','rMCM'};
    reslist = strcat('res',loadlist);
end

% Prints output vs. input and calculates correlations
if FLAGS.corr == 1
    figure('Name','Correlation plot','NumberTitle','off');
    correlationPlot(targetMatrix0, excessVec0, loadlist, voltagelist);
end

%                       END INITIALIZATION SECTION
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%             VOLTAGE TO LOAD (DIRECT) - ALGEBRAIC SECTION                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initialize structure for unique outputs for section
uniqueOut=struct();

% Finds the average  of the natural zeros (called global zeros)
globalZeros = mean(natzeros);

% Subtracts global zeros from signal.
dainputs0 = excessVec0 - ones(numpts0,1)*globalZeros;

% Determines how many terms are in the algebraic model; this will help
% determine the size of the calibration matrix
switch FLAGS.model
    case {1,4}
        % Full Algebraic Model or Custom Algebraic Model
        % The Custom model calculates all terms, and then excludes them in
        % the calibration process as determined by the customMatrix.
        nterms = 2*dimFlag*(dimFlag+2);
    case 2
        % Truncated Algebraic Model
        nterms = dimFlag*(dimFlag+3)/2;
    case 3
        % Linear Algebraic Model
        nterms = dimFlag;
end

% Creates the algebraic combination terms of the inputs.
% Also creates intercept terms; a different intercept for each series.
comIN0 = balCal_algEqns(FLAGS.model,dainputs0,series0,1);

%%% Balfit Stats and Regression Coeff Matrix AJM 5_31_19
balfitdainputs0 = targetMatrix0;
balfittargetMatrix0 = balCal_algEqns(3,dainputs0,series0,0);
balfitcomIN0 = balCal_algEqns(FLAGS.model,balfitdainputs0,series0,1);
%%% Balfit Stats and Regression Coeff Matrix AJM 5_31_19

if FLAGS.LHS == 0
    numLHS = 1;
end
lhs_check = zeros(length(excessVec0),1);
lhs_ind = 1:length(excessVec0(:,1));

if FLAGS.LHS == 1
    fprintf('\nNumber of LHS Iterations Selected: %i\n',numLHS)
end
fprintf('\nStarting Calculations\n')

for lhs = 1:numLHS
    
    % Creates an LHS sub-sample of the data.
    if FLAGS.LHS == 1
        sample = AOX_LHS(series0,excessVec0,LHSp);
        lhs_check(sample) = 1;
        lhs_ind(find(lhs_check-1)); % This line outputs which data points haven't been sampled yet
        pct_sampled = sum(lhs_check)/length(lhs_check); % This line outputs what percentage of points have been sampled
    else
        sample = (1:length(series0))';
    end
    
    % Uses the sampling indices in "sample" to create the subsamples
    series = series0(sample);
    targetMatrix = targetMatrix0(sample,:);
    comIN = comIN0(sample,:);
    
    %%% Balfit Stats and Regression Coeff Matrix AJM 5_31_19
    balfittargetMatrix = balfittargetMatrix0(sample,:);
    balfitcomIN = balfitcomIN0(sample,:);
    %%% Balfit Stats and Regression Coeff Matrix AJM 5_31_19
    
    %Calculate xcalib (coefficients)
    [xcalib, ANOVA] = calc_xcalib(comIN,targetMatrix,series,nterms,nseries0,dimFlag,FLAGS.model,customMatrix,FLAGS.anova);
    
    [balfitxcalib, balfitANOVA] = calc_xcalib(balfitcomIN,balfittargetMatrix,series,nterms,nseries0,dimFlag,FLAGS.model,customMatrix,FLAGS.anova);
    
    if FLAGS.LHS == 1
        x_all(:,:,lhs) = xcalib;
    end
end
if FLAGS.LHS == 1
    xcalib = mean(x_all,3);
    xcalib_std = std(x_all,[],3);
end

% APPROXIMATION
% define the approximation for inputs minus global zeros (includes
% intercept terms)
aprxIN = comIN0*xcalib;

% RESIDUAL
targetRes = targetMatrix0-aprxIN;

% Identify Outliers After Filtering
% (Threshold approach) ajm 8/2/17
if FLAGS.balOut == 1
    
    %Identify outliers based on residuals
    [OUTLIER_ROWS,num_outliers,prcnt_outliers,rowOut,colOut]=ID_outliers(targetRes,loadCapacities,numpts0,dimFlag,numSTD,FLAGS);
    
    newStruct=struct('num_outliers',num_outliers,'prcnt_outliers',prcnt_outliers,'rowOut',rowOut,'colOut',colOut,'numSTD',numSTD);
    uniqueOut = cell2struct([struct2cell(uniqueOut); struct2cell(newStruct)],  [fieldnames(uniqueOut); fieldnames(newStruct)], 1);
    
    % Use the reduced input and target files
    if FLAGS.zeroed == 1
        
        % Remove outlier rows for recalculation and all future calculations:
        numpts0 =  numpts0 - num_outliers;
        targetMatrix0(OUTLIER_ROWS,:) = [];
        excessVec0(OUTLIER_ROWS,:) = [];
        series0(OUTLIER_ROWS) = [];
        comIN0(OUTLIER_ROWS,:) = [];
        [~,s_1st0,~] = unique(series0);
        nseries0 = length(s_1st0);
        
        %Calculate xcalib (coefficients)
        [xcalib,ANOVA]=calc_xcalib(comIN0,targetMatrix0,series0,nterms,nseries0,dimFlag,FLAGS.model,customMatrix,FLAGS.anova);
        
        %%% Balfit Stats and Regression Coeff Matrix AJM 5_31_19
        [balfitxcalib, balfitANOVA] = calc_xcalib(balfitcomIN,balfittargetMatrix,series,nterms,nseries0,dimFlag,FLAGS.model,customMatrix,FLAGS.anova); % AJM 5_31_19
        if FLAGS.anova==1
            filename = 'Testing_Sig.csv';
            dlmwrite(filename,balfitANOVA(1).sig,'precision','%.16f');
        end
        %%% Balfit Stats and Matrix AJM 5_31_19
        
        % APPROXIMATION
        % define the approximation for inputs minus global zeros (includes
        % intercept terms)
        aprxIN = comIN0*xcalib;
        
        % RESIDUAL
        targetRes = targetMatrix0-aprxIN;
        
    end
end

% Splits xcalib into Coefficients and Intercepts (which are negative Tares)
coeff = xcalib(1:nterms,:);
tares = -xcalib(nterms+1:end,:);
intercepts=-tares;
taretal=tares(series0,:);
aprxINminGZ=aprxIN+taretal; %Approximation that does not include intercept terms %QUESTION: 29 MAR 2019: JRP

%%% AJM 6_11_19%    QUESTION: JRP; IS THIS NECESSARY/USEFUL?
[~,tares_STDDEV_all] = meantare(series0,aprxINminGZ-targetMatrix0);
tares_STDDEV = tares_STDDEV_all(s_1st0,:);
%%% AJM 6_11_19

%%% Balfit Stats and Regression Coeff Matrix AJM 5_31_19
balfit_C1INV = xcalib((1:dimFlag), :); % AJM 5_31_19
balfit_D1 = zeros(dimFlag,dimFlag); % AJM 5_31_19
balfit_INTERCEPT = globalZeros; % AJM 6_14_19
balfit_C1INVC2 = balfitxcalib((dimFlag+1:nterms), :)*balfit_C1INV; % AJM 5_31_19

balfit_regress_matrix = [globalZeros ; balfit_INTERCEPT ; balfit_C1INV ; balfit_D1 ; balfit_C1INVC2 ];

filename = 'BALFIT_DATA_REDUCTION_MATRIX_IN_AMES_FORMAT.csv';
dlmwrite(filename,balfit_regress_matrix,'precision','%.16f');
fprintf('\nBALFIT DATA REDUCTION MATRIX IN AMES FORMAT FILE: ');
fprintf(filename);
fprintf('\n');
%%% Balfit Stats and Matrix AJM 5_31_19

%Start uncertainty section
if FLAGS.boot==1
    %%start bootstrapfunction
    bootalpha=.05;
    f=@calc_xcalib;
    xcalib_ci=bootci(numBoot,{f,comIN0,targetMatrix0,series0,nterms,nseries0,dimFlag,FLAGS.model,customMatrix,0});
else
    xcalib_ci=zeros(2, size(xcalib,1),size(xcalib,2));
end
% END: bootstrap section

%ANOVA data for uncertainty
beta_CI_comb=zeros(size(xcalib,1),dimFlag);
y_hat_PI_comb=zeros(size(targetMatrix,1),size(targetMatrix,2));
if FLAGS.anova==1
    for j=1:dimFlag
        if FLAGS.model == 4
            beta_CI_comb(boolean(customMatrix(:,j)),j)=ANOVA(j).beta_CI;
        else
            beta_CI_comb(:,j)=ANOVA(j).beta_CI;
        end
        y_hat_PI_comb(:,j)=ANOVA(j).y_hat_PI;
    end
end
%END: ANOVA data for uncertainty

if FLAGS.volt==1
    %uncertainty due to uncertainty in volt readings
    uncert_comIN=balCal_algEquations_partialdiff(FLAGS.model, dimFlag, dainputs0);
else
    uncert_comIN=zeros(nterms,numpts0,dimFlag);
end

[combined_uncert,tare_uncert, FL_uncert,xcalibCI_includeZero, xcalib_error,coeff_uncert_boot]=uncert_prop(xcalib,xcalib_ci,comIN0,dimFlag,uncert_comIN,s_1st0,nterms,targetMatrix0,series0,voltTrust,FLAGS.boot,FLAGS.volt);
[combined_uncert_anova,tare_uncert_anova, FL_uncert_anova,coeff_uncert_anova]=uncert_prop_anova(xcalib,beta_CI_comb,comIN,dimFlag,uncert_comIN,s_1st0,nterms,targetMatrix,series,voltTrust,FLAGS.anova,FLAGS.volt);
%end uncertainty section

%OUTPUT FUNCTION
%Function creates all outputs for calibration, algebraic section
section={'Calibration Algebraic'};
newStruct=struct('aprxIN',aprxIN,'coeff',coeff,'nterms',nterms,'ANOVA',ANOVA,'balfitcomIN',balfitcomIN,'balfitxcalib',balfitxcalib,'balfittargetMatrix',balfittargetMatrix,'balfitANOVA',balfitANOVA);
uniqueOut = cell2struct([struct2cell(uniqueOut); struct2cell(newStruct)],  [fieldnames(uniqueOut); fieldnames(newStruct)], 1);
output(section,FLAGS,targetRes,loadCapacities,fileName,numpts0,nseries0,tares,tares_STDDEV,loadlist,series0,excessVec0,dimFlag,voltagelist,reslist,uniqueOut)

%END CALIBRATION DIRECT APPROACH ALGEBRAIC SECTION
%%
if FLAGS.balCal == 2
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %             VOLTAGE TO LOAD (DIRECT) - RBF SECTION                         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %goal to minimize: minimize the sum of the squares (dot product) of each of the 8
    %residual vectors 'targetRes' 'target1' ... 'target8'
    %dt1 = dot(target1,target1);
    %find centers by finding the index of max residual, using that index to
    %subtract excess(counter)-excess(indexMaxResid) and then taking the dot
    %product of the resulting column vector
    
    %Initialize structure for unique outputs for section
    uniqueOut=struct();
    
    
    targetRes2=targetRes;
    aprxINminGZ2 = aprxINminGZ;
    dainputscalib = excessVec0-globalZeros;
    
    %Initialize Variables
    etaHist = cell(numBasis,1);
    aprxINminGZ_Hist = cell(numBasis,1);
    tareGRBFHist = cell(numBasis,1);
    centerIndexLoop=zeros(1,dimFlag);
    eta=zeros(length(excessVec0(:,1)),dimFlag);
    w=zeros(1,dimFlag);
    rbfINminGZ=zeros(length(excessVec0(:,1)),dimFlag);
    coeffRBF=zeros(1,dimFlag);
    rbfc_INminGZ=zeros(length(excessVec0(:,1)),dimFlag);
    wHist=zeros(numBasis,dimFlag);
    cHist=zeros(numBasis,dimFlag);
    centerIndexHist=zeros(numBasis,dimFlag);
    resSquareHist=zeros(numBasis,dimFlag);
    
    for u=1:numBasis
        for s=1:dimFlag
            [~,centerIndexLoop(s)] = max(abs(targetRes2(:,s)));
            
            for r=1:length(excessVec0(:,1))
                eta(r,s) = dot(dainputscalib(r,:)-dainputscalib(centerIndexLoop(s),:),dainputscalib(r,:)-dainputscalib(centerIndexLoop(s),:));
            end
            
            %find widths 'w' by optimization routine
            w(s) = fminbnd(@(w) balCal_meritFunction2(w,targetRes2(:,s),eta(:,s)),0,1 );
            
            rbfINminGZ(:,s)=exp(eta(:,s)*log(abs(w(s))));
            
            coeffRBF(s) = dot(rbfINminGZ(:,s),targetRes2(:,s)) / dot(rbfINminGZ(:,s),rbfINminGZ(:,s));
            
            rbfc_INminGZ(:,s) = coeffRBF(s)*rbfINminGZ(:,s);
        end
        
        %Store basis parameters in Hist variables
        wHist(u,:) = w;
        cHist(u,:) = coeffRBF;
        centerIndexHist(u,:) = centerIndexLoop;
        etaHist{u} = eta;
        
        %update the approximation
        aprxINminGZ2 = aprxINminGZ2+rbfc_INminGZ;
        aprxINminGZ_Hist{u} = aprxINminGZ2;
        
        % SOLVE FOR TARES BY TAKING THE MEAN
        [taresAllPointsGRBF,taretalGRBFSTDDEV] = meantare(series0,aprxINminGZ2-targetMatrix0);
        taresGRBF = taresAllPointsGRBF(s_1st0,:);
        taresGRBFSTDEV = taretalGRBFSTDDEV(s_1st0,:);
        tareGRBFHist{u} = taresGRBF;
        
        %Calculate and store residuals
        targetRes2 = targetMatrix0-aprxINminGZ2+taresAllPointsGRBF;      %0=b-Ax
        newRes2 = targetRes2'*targetRes2;
        resSquare2 = diag(newRes2);
        resSquareHist(u,:) = resSquare2;
    end
    
    %OUTPUT FUNCTION
    %Function creates all outputs for calibration, GRBF section
    section={'Calibration GRBF'};
    newStruct=struct('aprxINminGZ2',aprxINminGZ2,'wHist',wHist,'cHist',cHist,'centerIndexHist',centerIndexHist,'numBasis',numBasis);
    uniqueOut = cell2struct([struct2cell(uniqueOut); struct2cell(newStruct)],  [fieldnames(uniqueOut); fieldnames(newStruct)], 1);
    output(section,FLAGS,targetRes2,loadCapacities,fileName,numpts0,nseries0,taresGRBF,taresGRBFSTDEV,loadlist,series0,excessVec0,dimFlag,voltagelist,reslist,uniqueOut)

end
%END CALIBRATION GRBF SECTION

%%
if FLAGS.balVal == 1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                       VALIDATION SECTION      AJM 7/1/17                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Initialize structure for unique outputs for section
    uniqueOut=struct();
    
    load(out.savePathval,'-mat');
    [validSeries,s_1stV,~] = unique(seriesvalid);
    xvalid=coeff; %JUST USE COEFF FOR VALIDATION (NO ITERCEPTS)
    
    % num of data points
    numptsvalid = length(seriesvalid);
    dimFlagvalid = length(excessVecvalid(1,:));
    
    %find the average natural zeros (also called global zeros)
    globalZerosvalid = mean(natzerosvalid);
    
    %load capacities
    loadCapacitiesvalid(loadCapacitiesvalid == 0) = realmin;
    
    %find number of series0; this will tell us the number of tares
    nseriesvalid = max(seriesvalid);
    
    %find zero points of each series0 and number of points in a series0
    %localZerosAllPoints is the same as localZeroMatrix defined in the RBF
    %section
    globalZerosAllPointsvalid = ones(numptsvalid,1)*globalZerosvalid;
    
    % Subtract the Global Zeros from the Inputs and Local Zeros
    dainputsvalid = excessVecvalid-globalZerosvalid;
    
    %%% 5/16/18
    %Remember that  excessVec0 = excessVec0_complete - globalZerosAllPoints;
    excessVecvalidkeep = excessVecvalid  - globalZerosAllPointsvalid;
    %%%
    
    % Call the Algebraic Subroutine
    comINvalid = balCal_algEqns(FLAGS.model,dainputsvalid,seriesvalid,0);
    
    %VALIDATION APPROXIMATION
    %define the approximation for inputs minus global zeros
    aprxINvalid = comINvalid*xvalid;        %to find approximation AJM111516
    
    %%%%% 3/23/17 Zap intercepts %%%
    aprxINminGZvalid = aprxINvalid;
    checkitvalid = aprxINminGZvalid-targetMatrixvalid;
    
    % SOLVE FOR TARES BY TAKING THE MEAN
    [taresAllPointsvalid,taretalstdvalid] = meantare(seriesvalid,checkitvalid);
    taresvalid     = taresAllPointsvalid(s_1stV,:);
    tares_STDEV_valid = taretalstdvalid(s_1stV,:);
    
    %RESIDUAL
    targetResvalid = targetMatrixvalid-aprxINminGZvalid+taresAllPointsvalid;
    
    %OUTPUT FUNCTION
    %Function creates all outputs for validation, algebraic section
    newStruct=struct('aprxINminGZvalid',aprxINminGZvalid);
    uniqueOut = cell2struct([struct2cell(uniqueOut); struct2cell(newStruct)],  [fieldnames(uniqueOut); fieldnames(newStruct)], 1);
    section={'Validation Algebraic'};
    output(section,FLAGS,targetResvalid,loadCapacitiesvalid,fileNamevalid,numptsvalid,nseriesvalid,taresvalid,tares_STDEV_valid,loadlist,seriesvalid,excessVecvalidkeep,dimFlag,voltagelist,reslist,uniqueOut)

    %END VALIDATION DIRECT APPROACH ALGEBRAIC SECTION
    
    %%
    if FLAGS.balCal == 2
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                    RBF SECTION FOR VALIDATION     AJM 12/10/16                         %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %goal to use centers, width and coefficients to validate parameters against
        %independent data
        
        %Initialize structure for unique outputs for section
        uniqueOut=struct();

        targetRes2valid = targetResvalid;
        aprxINminGZ2valid = aprxINminGZvalid;
        
        % Subtract the Global Zeros from the Inputs
        dainputsvalid = excessVecvalid-globalZerosvalid;
        
        %Initialize Variables
        aprxINminGZ_Histvalid = cell(numBasis,1);
        tareHistvalid = cell(numBasis,1);
        resSquareHistvalid=zeros(numBasis,dimFlagvalid);
        
        for u=1:numBasis
            %Call function to place single GRBF
            [rbfc_INminGZvalid]=place_GRBF(u,dainputscalib,dainputsvalid,centerIndexHist,wHist,cHist);
            
            %update the approximation
            aprxINminGZ2valid = aprxINminGZ2valid+rbfc_INminGZvalid;
            aprxINminGZ_Histvalid{u} = aprxINminGZ2valid;
            
            % SOLVE FOR TARES BY TAKING THE MEAN
            [~,s_1st,~] = unique(seriesvalid);
            [taresAllPointsvalid2,taretalstdvalid2] = meantare(seriesvalid,aprxINminGZ2valid-targetMatrixvalid);
            taresGRBFvalid = taresAllPointsvalid2(s_1st,:);
            taresGRBFSTDEVvalid = taretalstdvalid2(s_1st,:);
            tareHistvalid{u} = taresGRBFvalid;
            
            %Residuals
            targetRes2valid = targetMatrixvalid+taresAllPointsvalid2-aprxINminGZ2valid;      %0=b-Ax
            newRes2valid = targetRes2valid'*targetRes2valid;
            resSquare2valid = diag(newRes2valid);
            resSquareHistvalid(u,:) = resSquare2valid;
        end
        
        %OUTPUT FUNCTION
        %Function creates all outputs for validation, GRBF section
        section={'Validation GRBF'};
        newStruct=struct('aprxINminGZ2valid',aprxINminGZ2valid,'numBasis',numBasis);
        uniqueOut = cell2struct([struct2cell(uniqueOut); struct2cell(newStruct)],  [fieldnames(uniqueOut); fieldnames(newStruct)], 1);
        output(section,FLAGS,targetRes2valid,loadCapacitiesvalid,fileNamevalid,numptsvalid,nseriesvalid,taresGRBFvalid,taresGRBFSTDEVvalid,loadlist,seriesvalid,excessVecvalid,dimFlagvalid,voltagelist,reslist,uniqueOut)
    end
    %END GRBF SECTION FOR VALIDATION
end
%END VALIDATION SECTION

%%
if FLAGS.balApprox == 1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                        APPROXIMATION SECTION      AJM 6/29/17           %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %DEFINE THE PRODUCTION CSV INPUT FILE AND SELECT THE RANGE OF DATA VALUES TO READ
    load(out.savePathapp,'-mat');
    
    %natural zeros (also called global zeros)
    globalZerosapprox = mean(natzerosapprox);
    
    % Subtract the Global Zeros from the Inputs
    dainputsapprox = excessVecapprox-globalZerosapprox;
    
    % Call the Algebraic Subroutine
    comINapprox = balCal_algEqns(FLAGS.model,dainputsapprox,seriesapprox,0);
    
    %LOAD APPROXIMATION
    %define the approximation for inputs minus global zeros
    aprxINapprox = comINapprox*coeff;        %to find approximation AJM111516
    aprxINminGZapprox = aprxINapprox;
    
    fprintf('\n ********************************************************************* \n');
    if FLAGS.excel == 1
        filename = 'GLOBAL_ALG_APPROX.csv';
        csvwrite(filename,aprxINminGZapprox)
        dlmwrite(filename,aprxINminGZapprox,'precision','%.16f');
        fprintf('\n APPROXIMATION ALGEBRAIC MODEL LOAD APPROXIMATION FILE: ');
        fprintf(filename); 
        fprintf('\n');
    else
        fprintf('\nAPPROXIMATION ALGEBRAIC MODEL LOAD APPROXIMATION RESULTS: Check aprxINminGZapprox in Workspace \n');
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                    RBF SECTION FOR APPROXIMATION     AJM 6/29/17                         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %goal to use centers, width and coefficients to approxate parameters against
    %independent data
    
    if FLAGS.balCal == 2
        
        aprxINminGZ2approx = aprxINminGZapprox;
        aprxINminGZ_Histapprox = cell(numBasis,1);
        
        for u=1:numBasis
            
            %Call function to place single GRBF
            [rbfc_INminGZapprox]=place_GRBF(u,dainputscalib,dainputsapprox,centerIndexHist,wHist,cHist);
            
            %update the approximation
            aprxINminGZ2approx = aprxINminGZ2approx+rbfc_INminGZapprox;
            aprxINminGZ_Histapprox{u} = aprxINminGZ2approx;
            
        end
        
        fprintf('\n ********************************************************************* \n');
        if FLAGS.excel == 1
            filename = 'GLOBAL_ALG+GRBF_APPROX.csv';
            csvwrite(filename,aprxINminGZ2approx)
            dlmwrite(filename,aprxINminGZ2approx,'precision','%.16f');
            fprintf('\n APPROXIMATION ALGEBRAIC+GRBF MODEL LOAD APPROXIMATION FILE: ');
            fprintf(filename);
            fprintf('\n');
        else
            fprintf('\nAPPROXIMATION ALGEBRAIC+GRBF MODEL LOAD APPROXIMATION RESULTS: Check aprxINminGZapprox in Workspace \n');
        end
        
    end
    % END APPROXIMATION GRBF SECTION
    
end
%END APPROXIMATION SECTION

fprintf('\n  ');
fprintf('\nCalculations Complete.\n');
fprintf('\n');
