function [comIN_RBF]=create_comIN_RBF(dainputs,epsHist,center_daHist,h_GRBF)
%Function places a single GRBF for the validation or approximation section.

%INPUTS:
%  dainputs  = Current Section (voltage - (global zeros) )
%  epsHist  =  History of GRBF epsilon values, as determined from calibration section
%  center_daHist = Voltages of GRBF centers. Dim 1= RBF #, Dim 2= Channel for voltage, Dim 3= Dimension center is placed in ( what load channel it is helping approximate)
%  h  =  h value for GRBFs, as determined by point spacing in calib section

%OUTPUTS:
%  comIN_RBF  =  Input for load approximation, to be multiplied by
%  coefficients with algebraic comIN to determine load value

[numRBF,dimFlag]=size(epsHist); %Determine number of RBFs in each channel and number of channels

%Reshape centers to long matrix of center positions, in blocks by RBF
%number (alternating channels)
center_daFlip=permute(center_daHist,[3 2 1]); % dim 1= channel helping approximate, dim 2= channel voltage, dim 3= rbf number
center_da_long=zeros(numRBF*dimFlag,dimFlag);
eps_long=zeros(1,numel(epsHist));
for i=1:numRBF
    center_da_long(dimFlag*(i-1)+1:dimFlag*i,:)=center_daFlip(:,:,i);
    eps_long(:,dimFlag*(i-1)+1:dimFlag*i)=epsHist(i,:); %Reshape into long vector of epsilon, in blocks RBF number (alternating channels) 
end

dist=zeros(size(dainputs,1),size(center_da_long,1),size(dainputs,2));
for i=1:size(dainputs,2)
    dist(:,:,i)=center_da_long(:,i)'-dainputs(:,i); %solve distance in each dimension, Eqn 16 from Javier's notes
end
R_square=sum(dist.^2,3); %Eqn 17 from Javier's notes: squared distance between each point

comIN_RBF=((eps_long.^dimFlag)/(sqrt(pi^dimFlag))).*exp(-((eps_long.^2).*(R_square))/h_GRBF^2); %From 'Iterated Approximate Moving Least Squares Approximation', Fasshauer and Zhang, Equation 22
comIN_RBF=comIN_RBF-mean(comIN_RBF,1);

end