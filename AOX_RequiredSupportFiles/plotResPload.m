function [] = plotResPload(targetLoad,targetRes, loadCapacities, loadlist)
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
% Generates 6 subplot window (maximum 6 subplots per window)--code taken from plotRespages

sub=0;
r = min(n_dim,6);
% figure()
for i = 1:n_dim %subplot for each series
    if i>1 && rem(i,6) == 1 %If first subplot for new window
        h1=gcf;
        figure('Name',h1.Name,'NumberTitle','off','WindowState','maximized');
        sub = 6;
        %         r = n_dim - 6;
        r = 6;
    end
    subplot(r, 1, i-sub); hold on
    yhigh = max(1, maxRes);
    ylow = min(-1, minRes);
    xthresh = linspace(-100,100,100);
    ythreshl = -0.25;
    ythreshh =  0.25;
    axis([-100 100 ylow yhigh]) % axis limits
    x = pload(ASC(:,i),i);
    y = resPCT(ASC(:,i),i); 
    plot(x,y);
    hold on
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

end

