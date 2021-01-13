% outputs file of gui inputs


function guiInputs(outStruct,customPath,termList,cal,val,app,actionval,GRBF_defaulteps,output2calibFlag)
%% TITLE
    filename = strcat(outStruct.output_location,'guiInputs.txt');
    fileID = fopen(filename,'w');
    fprintf(fileID,'AOX_BalCal GUI INPUTS\n');
    fprintf(fileID,datestr(datetime('now')));
    fprintf(fileID,'\n\n');
%% APPLICATION MODE
    fprintf(fileID,'\nAPPLICATION MODE\n');
    if outStruct.mode==1    % Application Mode
        fprintf(fileID,'\tBalance Calibration\n');
    elseif outStruct.mode ==2
        fprintf(fileID,'\tGeneral Function Calibration\n'); 
    end
%% ACTION
    fprintf(fileID,'\nACTION\n');
    if actionval==1
        fprintf(fileID,'\tCalibration Only\n');
    elseif actionval==2
        fprintf(fileID,'\tCalibration and Validation\n');
    elseif actionval ==3
        fprintf(fileID,'\tCalibration and Approximation\n');
    end
fprintf(fileID,'\n');
%% ALGEBRAIC MODEL TYPE
    fprintf(fileID,'\nALGEBRAIC MODEL TYPE\n');
    if outStruct.model==1
        fprintf(fileID,'\tFull Equations\n');
    elseif outStruct.model==2
        fprintf(fileID,'\tTruncated Equations\n');
    elseif outStruct.model==3
        fprintf(fileID,'\tLinear Equations\n');    
    elseif outStruct.model==4
        fprintf(fileID,'\tCustom Equation File: ');
        cpath = insertAfter(customPath,'/','/');
        cpath = insertAfter(cpath,'\','\');
        fprintf(fileID,cpath);
        fprintf(fileID,'\n');
    elseif outStruct.model==5 
        fprintf(fileID,'\tBalance Type Equations: ');
         if outStruct.balanceEqn==1
             fprintf(fileID,'BALANCE TYPE 1-A(F,F*F,F*G)\n');
         elseif outStruct.balanceEqn==2
             fprintf(fileID,'BALANCE TYPE 1-B(F,F*F,F*G,F*F*F)\n');
         elseif outStruct.balanceEqn==3
             fprintf(fileID,'BALANCE TYPE 1-C(F,F*G)\n');
         elseif outStruct.balanceEqn==4
             fprintf(fileID,'BALANCE TYPE 1-D(F,F*F)\n');
         elseif outStruct.balanceEqn==5
             fprintf(fileID,'BALANCE TYPE 2-A(F,|F|,F*F,F*G)\n');
         elseif outStruct.balanceEqn==6
             fprintf(fileID,'BALANCE TYPE 2-B(F,|F|,F*F,F*|F|,F*G)\n');
         elseif outStruct.balanceEqn==7
             fprintf(fileID,'BALANCE TYPE 2-C(F,|F|,F*F,F*|F|,F*G,|F*G|,F*|G|,|F|*G)\n');
         elseif outStruct.balanceEqn==8
             fprintf(fileID,'BALANCE TYPE 2-D(F,|F|,F*F,F*|F|,F*G,|F*G|,F*|G|,|F|*G,F*F*F,|F*F*F|)\n');
         elseif outStruct.balanceEqn==9
             fprintf(fileID,'BALANCE TYPE 2-E(F,|F|,F*|F|,F*G)\n');
         elseif outStruct.balanceEqn==10
             fprintf(fileID,'BALANCE TYPE 2-F(F,|F|,F*G)\n');
         elseif outStruct.balanceEqn==11
             fprintf(fileID,'BALANCE TYPE 3-A(F*F*F,|F*F*F|,F*G*G,F*G*H)\n');
         end
    elseif outStruct.model==6
        fprintf(fileID,'\tCustom Term Selection: ');
        for i =1:12
            if outStruct.termInclude(i)==1
                fprintf(fileID,termList(i));
            end
        end
        fprintf(fileID,'\n');
    elseif outStruct.model==0
        fprintf(fileID,'\tNo Algebraic Model\n');
    end
%% GRBF ADDITION 
    fprintf(fileID,'\nGRBF ADDITION\n');
    if outStruct.grbf-1
        fprintf(fileID,'\tIncluding GRBFs\n');
        if outStruct.basis
            fprintf(fileID,'\tNumber of Basis Functions: %d\n', outStruct.basis);
        end
        if ~isempty(outStruct.selfTerm_str)
            fprintf(fileID,'\t');
            fprintf(fileID,string(outStruct.selfTerm_str));
            fprintf(fileID,'\n');
        end
        if strcmp(outStruct.selfTerm_str,'VIF + Prediction Interval Termination')
            if outStruct.GRBF_VIF_thresh
                fprintf(fileID,'\tMax VIF Threshold: %d\n', outStruct.GRBF_VIF_thresh);
            end
        end 
        if GRBF_defaulteps
            fprintf(fileID,'\tUsing Recommended Default Epsilon\n');
        else
            if outStruct.min_eps
                fprintf(fileID,'\tMin Epsilon: %d\n', outStruct.min_eps);
            end
            if outStruct.max_eps
                fprintf(fileID,'\tMax Epsilon: %d\n', outStruct.max_eps);
            end
        end
    end

%% CALIBRATION
    fprintf(fileID,'\nCALIBRATION\n');
    fprintf(fileID,'\tCalibration File: ');
    foutloc = insertAfter(cal.Path,'/','/');
    foutloc = insertAfter(foutloc,'\','\');
    fprintf(fileID,foutloc);
    fprintf(fileID, '\n');
    if outStruct.mode ==2
        fprintf(fileID,'\tOutput Array: ');
        fprintf(fileID,cal.Range{4});
        fprintf(fileID, '\n');
        fprintf(fileID,'\tInput Array: ');
        fprintf(fileID,cal.Range{5});
        fprintf(fileID, '\n');
    else
        fprintf(fileID,'\tLoad Capcities: ');
        fprintf(fileID,cal.Range{1});
        fprintf(fileID, '\n');
        fprintf(fileID,'\tNatural Zeros: ');
        fprintf(fileID,cal.Range{2});
        fprintf(fileID, '\n');
        fprintf(fileID,'\tSeries 1 Column: ');
        fprintf(fileID,cal.Range{3});
        fprintf(fileID, '\n');
        fprintf(fileID,'\tLoad Array: ');
        fprintf(fileID,cal.Range{4});
        fprintf(fileID, '\n');
        fprintf(fileID,'\tVoltage Array: ');
        fprintf(fileID,cal.Range{5});
        fprintf(fileID, '\n');
    end
%% VALIDATION
    if actionval==2&~isempty(fieldnames(val))
        fprintf(fileID,'\nVALIDATION\n');
        fprintf(fileID,'\tValidation File: ');
        foutloc = insertAfter(val.Path,'/','/');
        foutloc = insertAfter(foutloc,'\','\');
        fprintf(fileID,foutloc);
        fprintf(fileID, '\n');
        if outStruct.mode ==2
            fprintf(fileID,'\tOutput Array: ');
            fprintf(fileID,val.Range{4});
            fprintf(fileID, '\n');
            fprintf(fileID,'\tInput Array: ');
            fprintf(fileID,val.Range{5});
            fprintf(fileID, '\n');
        else
            fprintf(fileID,'\tLoad Capcities: ');
            fprintf(fileID,val.Range{1});
            fprintf(fileID, '\n');
            fprintf(fileID,'\tNatural Zeros: ');
            fprintf(fileID,val.Range{2});
            fprintf(fileID, '\n');
            fprintf(fileID,'\tSeries 1 Column: ');
            fprintf(fileID,val.Range{3});
            fprintf(fileID, '\n');
            fprintf(fileID,'\tLoad Array: ');
            fprintf(fileID,val.Range{4});
            fprintf(fileID, '\n');
            fprintf(fileID,'\tVoltage Array: ');
            fprintf(fileID,val.Range{5});
            fprintf(fileID, '\n');
        end
    end
%% APPROXIMATION
    if actionval==3 & ~isempty(fieldnames(app))
        fprintf(fileID,'\nAPPROXIMATION\n');
        fprintf(fileID,'\tApproximation File: ');
        foutloc = insertAfter(app.Path,'/','/');
        foutloc = insertAfter(foutloc,'\','\');
        fprintf(fileID,foutloc);
        fprintf(fileID, '\n');
        if outStruct.mode ==2
            fprintf(fileID,'\t: ');
            fprintf(fileID,app.Range{4});
            fprintf(fileID, '\n');
        else
            fprintf(fileID,'\tLoad Capcities: ');
            fprintf(fileID,app.Range{1});
            fprintf(fileID, '\n');
            fprintf(fileID,'\tNatural Zeros: ');
            fprintf(fileID,app.Range{2});
            fprintf(fileID, '\n');
            fprintf(fileID,'\tSeries 1 Column: ');
            fprintf(fileID,app.Range{3});
            fprintf(fileID, '\n');
            fprintf(fileID,'\tLoad Array: ');
            fprintf(fileID,app.Range{4});
            fprintf(fileID, '\n');
        end 
    end
%% MODEL OPTIONS
    fprintf(fileID,'\nMODEL OPTIONS\n');
    if outStruct.anova
        fprintf(fileID,'\tPerforming Analysis of Variance (ANOVA)\n');
        if outStruct.anova_pct
            fprintf(fileID,'\tANOVA Percent Confidence: %d\n', outStruct.anova_pct);
        end
    end

    if outStruct.mode==1 %Intercept options for Balance Calibration Mode
        if outStruct.intercept==1 %Include series intercepts
            fprintf(fileID,'\tSeries Specific Intercept Terms (Tare Loads)\n');
        elseif outStruct.intercept==2 %Include global intercept
            fprintf(fileID,'\tGlobal Intercept Term\n');
        elseif outStruct.intercept==3 %Include no intercepts
            fprintf(fileID,'\tNo Intercept Term\n');
        end
    else %If in general approximation mode
        if outStruct.intercept==1 %Include global intercept
            fprintf(fileID,'\tGlobal Intercept Term\n');
        else %Include no intercepts
            fprintf(fileID,'\tNo Intercept Term\n');
        end
    end

    if outStruct.outlier&outStruct.model~=0
        fprintf(fileID,'\tIdentifying Possible Outliers\n');
          
        fprintf(fileID,'\tNumber of Standard Deviations: %d\n',outStruct.numSTD);

        if outStruct.zeroed
            fprintf(fileID,'\tRemoving Outliers\n');
        end
    end
    if outStruct.model~=0
        if strcmp(outStruct.AlgModelName_opt,'0')
            fprintf(fileID,'\t');
            fprintf(fileID,'No Model Refinement');
            fprintf(fileID,'\n');
        else 
            fprintf(fileID,'\t');
            fprintf(fileID,outStruct.AlgModelName_opt);
            fprintf(fileID,'\n');
            
            fprintf(fileID,'\tSVD Zero Threshold: %d\n',outStruct.zero_threshold);
            if ~strcmp(outStruct.AlgModelName_opt,'SVD for Non-Singularity (Permitted Math Model)')
                fprintf(fileID,'\tVariance Infation Factor Threshold: %d\n',outStruct.VIF_thresh);
                fprintf(fileID,'\tPercent Confidence for Term Significance: %d\n',outStruct.sig_pct);

                if outStruct.high_con==0
                    fprintf(fileID,'\tTerm Hierarchy Not Enforced\n');
                elseif outStruct.high_con==1
                    fprintf(fileID,'\tTerm Hierarchy Enforced After Search\n');
                elseif outStruct.high_con==2
                    fprintf(fileID,'\tTerm Hierarchy Enforced During Search\n');
                end
                if strcmp(outStruct.AlgModelName_opt,'Forward Selection Recommended Math Model')|strcmp(outStruct.AlgModelName_opt,'Backwards Elimination Recommended Math Model')
                    if ~isEmpty(outStruct.search_metric)
                        fprintf(fileID,'\tOptimization Metric: ');
                        fprintf(fileID,outStruct.search_metric);
                        fprintf(fileID,'\n');
                    end
                end
            end
        end
    end
%% OUTPUTS
    fprintf(fileID,'\nOUTPUTS\n');
    if outStruct.disp 
        fprintf(fileID,'\tDisplaying Performance Parameters\n');
    end
    if outStruct.res
        fprintf(fileID,'\tPlotting Residuals\n');
    end
    if outStruct.hist
        fprintf(fileID,'\tPlotting Residual Histograms\n');
    end
    if outStruct.QQ
        fprintf(fileID,'\tPlotting Residual Q-Q\n');
    end
    if outStruct.corr
        fprintf(fileID,'\tPlotting Correlations\n');
    end
    if outStruct.rescorr
        fprintf(fileID,'\tPlotting Residual Correlations\n');
    end
    if output2calibFlag
        fprintf(fileID,'\tOutputting to Calibration File Location\n');
    else
        fprintf(fileID,'\tFile Output Location: ');
        foutloc = insertAfter(outStruct.output_location,'/','/');
        foutloc = insertAfter(foutloc,'\','\');
        fprintf(fileID,foutloc);
        fprintf(fileID,'\n');
    end
    
    if outStruct.subfolder_FLAG
        fprintf(fileID,'\tCreating Run Subfolder\n');
    end
    if outStruct.calib_model_save_FLAG
        fprintf(fileID,'\tSaving Calibration Model .mat File\n');
    end
    if outStruct.input_save_FLAG
        fprintf(fileID,'\tSaving Input Data to Output Location\n');
    end
    if outStruct.print
        fprintf(fileID,'\tPrinting Performance Parameter xlsx Files\n');
    end
    if outStruct.mode ==2
        if outStruct.excel
            fprintf(fileID,'\tPrinting Output and Coefficient csv Files\n');
        end
    else
        if outStruct.excel
            fprintf(fileID,'\tPrinting Load and Coefficient csv Files\n');
        end
        if outStruct.BALFIT_Matrix
            fprintf(fileID,'\tPrinting BALFIT Coefficient Matrix txt Files\n');
        end
    end
    
    if outStruct.Rec_Model
        fprintf(fileID,'\tPrinting Recommended Alg Model csv File\n');
    end
    
    if outStruct.mode ==2
        if outStruct.approx_and_PI_print
            fprintf(fileID,'\tPrinting Output with Prediction Interval xlsx File\n');
        end
    else
        if outStruct.approx_and_PI_print
            fprintf(fileID,'\tPrinting Load with Prediction Interval xlsx File\n');
        end
    end



    fclose(fileID);




end