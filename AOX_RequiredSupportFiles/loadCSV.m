function savePath = loadCSV(cva,output_location,mode)
% This function pre-loads the csv's and saves the data as .mat for quicker
% reading.
% Input: type - String that changes depending on whether loading
% calibration, validation, or approximation data.

% unicode2ascii(convertCharsToStrings(cva.Path))


switch cva.type
    case 'calibrate'
        cal = cva;
        
        if mode==1
            loadCapacities =     csvread(cal.Path,cal.CSV(1,1),cal.CSV(1,2),cal.Range{1});
            try %Try to read gage capacities
                gageCapacities= csvread(cal.Path,cal.CSV(1,1),cal.CSV(5,2),[cal.CSV(1,1),cal.CSV(5,2),cal.CSV(1,1),cal.voltend(1,2)]);
            catch
                gageCapacities=0;
            end
            natzeros =           csvread(cal.Path,cal.CSV(2,1),cal.CSV(2,2),cal.Range{2});
            
            %Read series labels using 'readtable': JRP 19 June 19
            A=extractAfter(cal.Range{3},'..');
            bottom=str2double(regexp(A,'\d*','Match'));
            opts=delimitedTextImportOptions('DataLines',[cal.CSV(3,1)+1 bottom]);
            series_bulk=readtable(cal.Path,opts);
            series=str2double(table2array(series_bulk(:,cal.CSV(3,2)+1)));
            series2=table2array(series_bulk(:,cal.CSV(3,2)+2));
            pointID=table2array(series_bulk(:,cal.CSV(3,2)));
            clear A bottom opts series_bulk
        end
        
        %         series =             csvread(cal.Path,cal.CSV(3,1),cal.CSV(3,2),cal.Range{3});
        
        targetMatrix0 =      csvread(cal.Path,cal.CSV(4,1),cal.CSV(4,2),cal.Range{4});
        excessVec0 =         csvread(cal.Path,cal.CSV(5,1),cal.CSV(5,2),cal.Range{5});
        
        try
            %START: new approach, JRP 11 June 19
            file=fopen(cal.Path); %open file
            all_text1 = textscan(file,'%s','Delimiter','\n'); %read in all text
            splitlabelRow=cellstr(strsplit(string(all_text1{1}{cal.CSV(4,1)}),',','CollapseDelimiters',false)); %Extract row with labels
            fclose(file); %close file
            loadlabels=splitlabelRow(cal.CSV(4,2)+1:cal.loadend(2)+1); %extract load labels
            voltlabels=splitlabelRow(cal.CSV(5,2)+1:cal.voltend(2)+1); %extract voltage labels
            
            try
                %Eliminate rows with ";" in first column
                lastrow=a12rc(extractAfter(cal.Range{4},".."));
                all_text_points=all_text1{1}(cal.CSV(4,1)+1:lastrow(1)+1);
                for i=1:size(all_text_points,1)
                    all_text_points_split(i,:)=cellstr(strsplit(string(all_text_points(i)),',','CollapseDelimiters',false)); %Extract row with labels
                end
                first_col=all_text_points_split(:,1);
                ignore_row=find(contains(first_col,';')); %Find rows with semicolons in the first column
                
                excessVec0(ignore_row,:)=[];
                targetMatrix0(ignore_row,:)=[];
                if mode==1
                    pointID(ignore_row,:)=[];
                    series(ignore_row,:)=[];
                    series2(ignore_row,:)=[];
                end
                
            catch
                fprintf('\n UNABLE TO REMOVE ROWS FLAGGED WITH ";" FROM INPUT FILE \n')
            end
            
            try
                %START: find file description and balance name: JRP 25 July 19
                description_i=find(contains(all_text1{1},'DESCRIPTION,'),1,'last');
                assert(any(description_i)) %intentional error to get to cach block if 'BALANCE_NAME' is not found
                descriptionRow=cellstr(strsplit(string(all_text1{1}{description_i}),',','CollapseDelimiters',false)); %Extract row with data description
                description=descriptionRow(find(contains(descriptionRow,'DESCRIPTION'))+1);
            catch
                description={'NO DESCRIPTION FOUND'};
            end
            clear description_i descriptionRow
            
            try
                unit_i=find(contains(all_text1{1},'units'),1,'last');
                assert(any(unit_i)) %intentional error to get to cach block if 'units' is not found
                % read in load and voltage units, JRP 11 July 19
                splitunitRow=cellstr(strsplit(string(all_text1{1}{unit_i+1}),',','CollapseDelimiters',false)); %extract row with units
                loadunits=splitunitRow(cal.CSV(4,2)+1:cal.loadend(2)+1); %extract load units
                voltunits=splitunitRow(cal.CSV(5,2)+1:cal.voltend(2)+1); %extract voltage units
            end
            clear unit_i splitunitRow
            
            if mode==1
                try
                    balance_i=find(contains(all_text1{1},'BALANCE_NAME,'),1,'last');
                    assert(any(balance_i)) %intentional error to get to cach block if 'BALANCE_NAME' is not found
                    if contains(all_text1{1}{balance_i},'"')
                        balance_type=extractBetween(all_text1{1}{balance_i},'"','"');
                    else
                        balanceRow=cellstr(strsplit(string(all_text1{1}{balance_i}),',','CollapseDelimiters',false)); %Extract row with balance name
                        balance_type=balanceRow(find(contains(balanceRow,'BALANCE_NAME'))+1);
                    end
                    
                catch
                    balance_type={'NO BALANCE NAME FOUND'};
                end
                clear balance_i balanceRow
                %END:find file description and balance name: JRP 25 July 19
            end
            clear file label_text1 splitlabelRow splitunitRow
            %END: new approach, JRP 11 June 19
            
        end
        
        [~,calName,~] = fileparts(cal.Path);
        fileName = [calName,'.cal'];
        savePath=fullfile(output_location,fileName);
        
        clear cva calName CurrentPath
        save(savePath);
    case 'validate'
        val = cva;
        
        if mode==1
            loadCapacitiesvalid =    csvread(val.Path,val.CSV(1,1),val.CSV(1,2),val.Range{1});
            natzerosvalid =          csvread(val.Path,val.CSV(2,1),val.CSV(2,2),val.Range{2});
            
            %Read series labels using 'readtable': JRP 19 June 19
            A=extractAfter(val.Range{3},'..');
            bottom=str2double(regexp(A,'\d*','Match'));
            opts=delimitedTextImportOptions('DataLines',[val.CSV(3,1)+1 bottom]);
            series_bulk=readtable(val.Path,opts);
            seriesvalid=str2double(table2array(series_bulk(:,val.CSV(3,2)+1)));
            series2valid=table2array(series_bulk(:,val.CSV(3,2)+2));
            pointIDvalid=table2array(series_bulk(:,val.CSV(3,2)));
            clear A bottom opts series_bulk
            %         seriesvalid =            csvread(val.Path,val.CSV(3,1),val.CSV(3,2),val.Range{3});
        end
        
        targetMatrixvalid =      csvread(val.Path,val.CSV(4,1),val.CSV(4,2),val.Range{4});
        excessVecvalid =         csvread(val.Path,val.CSV(5,1),val.CSV(5,2),val.Range{5});
        
        try
            file=fopen(val.Path); %open file
            all_text1 = textscan(file,'%s','Delimiter','\n'); %read in all text
            fclose(file); %close file
            %Eliminate rows with ";" in first column
            lastrow=a12rc(extractAfter(val.Range{4},".."));
            all_text_points=all_text1{1}(val.CSV(4,1)+1:lastrow(1)+1);
            for i=1:size(all_text_points,1)
                all_text_points_split(i,:)=cellstr(strsplit(string(all_text_points(i)),',','CollapseDelimiters',false)); %Extract row with labels
            end
            first_col=all_text_points_split(:,1);
            ignore_row=find(contains(first_col,';')); %Find rows with semicolons in the first column
            
            excessVecvalid(ignore_row,:)=[];
            targetMatrixvalid(ignore_row,:)=[];
            if mode==1
                pointIDvalid(ignore_row,:)=[];
                seriesvalid(ignore_row,:)=[];
                series2valid(ignore_row,:)=[];
            end
            
        catch
            fprintf('\n UNABLE TO REMOVE ROWS FLAGGED WITH ";" FROM INPUT FILE \n')
        end
        
        [~,valName,~] = fileparts(val.Path);
        fileNamevalid = [valName,'.val'];
        savePathvalid=fullfile(output_location,fileNamevalid);
        
        clear cva valName CurrentPath
        save(savePathvalid);
        savePath = savePathvalid;
    case 'approximate'
        app = cva;
        
        if mode==1
            loadCapacitiesapprox =    csvread(app.Path,app.CSV(1,1),app.CSV(1,2),app.Range{1});
            natzerosapprox =          csvread(app.Path,app.CSV(2,1),app.CSV(2,2),app.Range{2});
            
            %Read series labels using 'readtable': JRP 19 June 19
            A=extractAfter(app.Range{3},'..');
            bottom=str2double(regexp(A,'\d*','Match'));
            opts=delimitedTextImportOptions('DataLines',[app.CSV(3,1)+1 bottom]);
            series_bulk=readtable(app.Path,opts);
            seriesapprox=str2double(table2array(series_bulk(:,app.CSV(3,2)+1)));
            series2approx=table2array(series_bulk(:,app.CSV(3,2)+2));
            pointIDapprox=table2array(series_bulk(:,app.CSV(3,2)));
            clear A bottom opts series_bulk
            %         seriesapprox =            csvread(app.Path,app.CSV(3,1),app.CSV(3,2),app.Range{3});
        end
        
        excessVecapprox =         csvread(app.Path,app.CSV(4,1),app.CSV(4,2),app.Range{4});
        
        try
            file=fopen(app.Path); %open file
            all_text1 = textscan(file,'%s','Delimiter','\n'); %read in all text
            fclose(file); %close file
            %Eliminate rows with ";" in first column
            lastrow=a12rc(extractAfter(app.Range{4},".."));
            all_text_points=all_text1{1}(app.CSV(4,1)+1:lastrow(1)+1);
            for i=1:size(all_text_points,1)
                all_text_points_split(i,:)=cellstr(strsplit(string(all_text_points(i)),',','CollapseDelimiters',false)); %Extract row with labels
            end
            first_col=all_text_points_split(:,1);
            ignore_row=find(contains(first_col,';')); %Find rows with semicolons in the first column
            
            excessVecapprox(ignore_row,:)=[];
            if mode==1
                pointIDapprox(ignore_row,:)=[];
                seriesapprox(ignore_row,:)=[];
                series2approx(ignore_row,:)=[];
            end
        catch
            fprintf('\n UNABLE TO REMOVE ROWS FLAGGED WITH ";" FROM INPUT FILE \n')
        end
        
        [~,appName,~] = fileparts(app.Path);
        fileNameapprox = [appName,'.app'];
        savePathapprox=fullfile(output_location,fileNameapprox);
        
        clear cva appName CurrentPath all_text1 all_text_points all_text_points_split ans first_col i lastrow         
        save(savePathapprox);
        savePath = savePathapprox;
end