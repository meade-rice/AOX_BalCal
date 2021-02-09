% Version 1.3: Last modified on 5/15/18
function plotResPages(series, targetRes, loadlist, stdDevPercentCapacity, loadCapacities)
%Function generates figure with subplots for residuals as percentage of max load capacity in each channel as function of datapoint #

%INPUTS:
%  series = Labels of series number for each point
%  targetRes  =  Residual input.  (Tare-corrected load approximation)-(Target Load)
%  loadCapacities = Vector for max load capacity in each channel
%  stdDevPercentCapacity = Standard deviation of residuals in each channel as percentage of max load capacity
%  loadlist = Labels for load in each channel

%OUTPUTS:
% []

loadlist=cellfun(@(x) strrep(x,'_','\_'),loadlist,'UniformOutput',false);
n_data = size(targetRes,1); %Number of datapoint
n_dim = size(targetRes,2); %Number of dimensions (channels) in data

if exist('loadCapacities','var')
    targetResPct = 100 * targetRes ./ (ones(n_data,1)*loadCapacities); %Calculate percent load capacity for each residual
else
    targetResPct = targetRes;
end

thr = 0.25; %residual threshold: desired residual percentage

srs = unique(series); %Determine unique series numbers
n_series = length(srs); %Count number of series

ind_s = zeros(n_series,2); %Initialize variable for series start and end index
for i = 1:n_series %Loop through each series
    ind_s(i,1) = find(series==srs(i), 1 ); %Find series start index
    ind_s(i,2) = find(series==srs(i), 1, 'last' ); %Find series end index
end

%Generate subplot for each series for residuals: Max of 6 subplots per
%Figure window
%sub = 0;
%r = min(n_dim,6);
t = tiledlayout(n_dim, 1);
for i = 1:n_dim %subplot for each series
%    if i>1 && rem(i,6) == 1 %If first subplot for new window
%        h1=gcf;
%        figure('Name',h1.Name,'NumberTitle','off','WindowState','maximized');
%        sub = 6;
        %         r = n_dim - 6;
%        r = 6;
%    end
%    subplot(r, 1, i-sub); hold on
    
    
    nexttile(t);
    %Shades blocks to distinguish series
    for j = 1:n_series
        if mod(j,2) == 0
            patch([ind_s(j,1)-0.5 ind_s(j,2)+0.5 ind_s(j,2)+0.5 ind_s(j,1)-0.5], [-1 -1 1 1], [0.8 0.8 0.8])
        end
    end
    hold on
    plot([1:n_data],targetResPct(:,i)) %Plot residuals
    hold on
    if exist('loadCapacities','var')
        plot([1:n_data],thr*ones(1,n_data),'k--',[1:n_data],-thr*ones(1,n_data),'k--') %Plot desired threshold cutoff
    end
    xlabel('Data point index');
    ylabel(strcat('\Delta',loadlist{i}));
    if exist('loadCapacities','var')
        title(sprintf('Residual; %% of Load Capacity; Standard Deviation = %0.4f%%',stdDevPercentCapacity(i)));
    else
        title(sprintf('Residual; Standard Deviation = %0.4f',stdDevPercentCapacity(i)));
    end
    %     set(gcf,'Position',[100 50 825 min(r*175.5,900)]);
    
    if exist('loadCapacities','var')
        axis([1 n_data -1 1]);
    else
        xlim([1 n_data]);
    end
    hold off
end

end