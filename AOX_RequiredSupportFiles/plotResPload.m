function [] = plotResPload(targetLoad,targetRes, loadCapacities, loadlist,series) %added seriesJP
%plotResPload Plots the residuals vs. the applied load as a percent of load
%capacity
npoint = size(targetLoad,1);
n_dim = size(targetLoad,2);
% Input Data Processing
pload = (targetLoad./loadCapacities)*100; % percent load
resPCT = (targetRes./loadCapacities)*100; % residual as percent of load capacity
maxRes = max(resPCT(resPCT>0)); % largest positive residual (upper axis limit)
minRes = min(resPCT(resPCT<0)); % largest negative residual (lower axis limit)
% resP = (targetRes./targetLoad)*100; % residual as a percent of the target (=% error)
[~,ASC] = sort(targetLoad,1,'ascend'); % ASC = sort index--target load in ascending order by column
% uses tiles instead of subplots(matlab 2019b)

%find the indicies where the series changes
series_adjusted =series;
seriesVal = unique(series);% unique series values
for i = 1:length(seriesVal)
    series_adjusted(series_adjusted == seriesVal(i)) = i;%revalue the series so that the numbers start at 1 and increment up by 1
end

%create array of colors and shapes 
pointcolor=['ys','ms','cs','rs','gs','bs','ks',...
            'yd','md','cd','rd','gd','bd','kd',...
            'yo','mo','co','ro','go','bo','ko',...
            'yx','mx','cx','rx','gx','bx','kx'];


sub=0;
r = min(n_dim,6);
% figure() % uncomment this if running outside of AOX_Balcal
h1=tiledlayout(6, 1);
%figure('Name',h1.Name,'NumberTitle','off','WindowState','maximized');


for i = 1:n_dim %subplot for each series
   % if i>1 && rem(i,6) == 1 %If first subplot for new window
   %     h1=gcf;
   %     figure('Name',h1.Name,'NumberTitle','off','WindowState','maximized');
   %     sub = 6;
        %         r = n_dim - 6;
   %     r = 6;
   % end
    %tiledlayout(r, 1, i-sub); hold on
    yhigh = max(1, maxRes);
    ylow = min(-1, minRes);
    xthresh = linspace(-100,100,100);
    ythreshl = -0.25;
    ythreshh =  0.25;
    axis([-100 100 ylow yhigh]); % axis limits
    x = pload(ASC(:,i),i);
    y = resPCT(ASC(:,i),i); 
    ax=nexttile;
    plot(x,y);
    hold on
    if length(seriesVal)<(length(pointcolor)/2)+1 %only plot different series if there are enough shapes/colors
        for j=1:length(seriesVal)%plot each series
            ind=find(series_adjusted==j);
            x1 = pload(ind,i);
            y1 = resPCT(ind,i);
            scatter(x1,y1,pointcolor(j));
            hold on
        end
    end
    
    yline(ythreshl, '--k');
    hold on
    yline(ythreshh, '--k');
    hold on
    text(0,-0.35,'Residual -0.25%');
    hold on
    text(0,0.4,'Residual -0.25%');
%     plot(xthresh, ythreshl, '--k');
%     plot(xthresh, ythreshh, '--k');
    title("Residual; % Load Capacity vs. Applied Load; % Load Capacity");
    xlabel("Applied Load: " + string(loadlist{1,i}) + ", % of load capacity");
    ylabel("\Delta " + string(loadlist{1,i}) + "(% Load Capacity)");
    hold on
end


if length(seriesVal)<(length(pointcolor)/2)+1 %only place legend if there are enough shapes/colors
    leglabel{1} = 'All Residuals';
    for i=1:length(seriesVal)
        leglabel{i+1} = strcat('Series ',string(seriesVal(i)));
    end
    leglabel{end+1} = 'Residual -.25%';
    leglabel{end+1} = 'Residual -.25%';
    l = legend(ax,leglabel,'Location','Northoutside','orientation','horizontal','NumColumns',10);
    if ~verLessThan('matlab','9.9')
        l.Layout.Tile = 'North';
    end
end
end

