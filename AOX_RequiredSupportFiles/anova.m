function ANOVA = anova(X,y,nterms,noVIF_FLAG,pct,FLAGS)
% Statistical function collection.
% Reference: http://reliawiki.org/index.php/Multiple_Linear_Regression_Analysis
% These equations are not yet directly used by the code, and they are not
% really even functions, but scripts that hold different statistical
% analysis equations.

%INPUTS:
%  X = Matrix of predictor variables. Each row is different observation, each column is different predictor
%  y  =  Target variable for regression.  Each row is observation
%  nseries  =  Number of series in dataset
%  noVIF_FLAG  =  Flag to turn off VIF calculations. (noVIF_FLAG==0 then calculate VIF) 
%  pct  =  Percent confidence level for ANOVA calculations
%  FLAGS = Global structure containing flags for options

%OUTPUTS:
% ANOVA = Structure containing ANOVA outputs

%% Check if testing
if nargin < 4
    noVIF_FLAG = 0;
    pct = 95;
elseif nargin < 5
    pct = 95;
end



%% Multiple Linear Regression
% Instead of calculating the coefficient matrix using pinv or backslash,
% the coeffciients will be solved for the normal way, that is:
% b = (X' X)^-1 X y
% NOTE: IF THIS METHOD THROWS UP WARNINGS ABOUT ILL-CONDITIONED, DO NOT
% SUPPRESS THEM, IT IS IMPORTANT INFORMATION TO HAVE.
invXtX = pinv(X'*X);
beta = invXtX*X'*y;

%% TEMPORARY
% The current data is extremely ill-conditioned, so warnings are semi-suppressed
% for now if the data is bad, since it can be very repetitive.
% This will be removed later, since those
% warnings can be useful.
warnMsg = lastwarn;
if ~isempty(warnMsg)
    warning('off','MATLAB:nearlySingularMatrix');
    lastwarn('');
end
%%

%% Multicollinearity detection / VIF calcualtion
% Variance inflation factor is calculated first so that when we're
% iterating through test terms in the model, we can eliminate collinear
% data right away, before wasting computer time on unnecessary statistical
% calculations.
%VIF calculations performed if test_FLAG=0: Do not perform during iterated
%recommended equation solving for time saving
if noVIF_FLAG==0
    VIF = vif(X, FLAGS); % function is part of anova.m
    
%     VIF_dl=vif_dl(X(:,2:end))';
    
    if any(VIF>=10)
        warning('VIF calculation indicates strong multicollinearity. Analysis of Variance results are unreliable.')
        VIF_warn = 2; % strong multicollinearity
    elseif any(VIF>=4)
        warning('VIF calculation indicates some multicollinearity. Analysis of Variance results may be unreliable.')
        VIF_warn = 1; % some multicollinearity
    else
        VIF_warn = 0; % no multicollinearity warning
    end
else
%     VIF={'VIF NOT CALCULATED'};
    VIF=-1;
    VIF_warn = -1; % value of -1 indicated VIF was not calculated at all
end
% if test_FLAG == 1 && max(VIF) >= 4
%     ANOVA.test = -1;
%     return
% end

% The approximation can then be made with
% y_hat = X b = X (X' X)^-1 X' y = H y,
% where H is called the "hat" matrix, H = X(X'X)^-1X'
H = X*invXtX*X';
y_hat = H*y;

% The error e = y - y_hat
e = y - y_hat;

%% Covariance matrix and standard error
% The covariance matrix is calculated as C = sigma_hat^2 (X' X)^-1
% sigma_hat is an estimate of the variance (std dev), based on the MSE
%%
% (mean square error).
% MSE = SSE / dof(SSE)
% SSE is the sum square error, and dof() is the degrees of freedom of that
% error. The degrees of freedom will equal the number of points minus the
% number of coefficients that the regression is prediction.

%First, we'll calculate the SSE,
SSE = sum(e.^2);
% then, to calculate the degrees of freedom, we'll need the size
% information of the predictor matrix X
[n,k] = size(X);
dof_e = n-k;
if dof_e<0
    fprintf('WARNING: Negative Degrees of Freedom in ANOVA \n')
end
MSE = SSE/dof_e;
sigma_hat_sq = MSE;

C = sigma_hat_sq*invXtX;

% The standard error of each variable is then the square root of it's
% variance (the diagonal terms in the covariance matrix C.
se = sqrt(diag(C));

%% Hypothesis testing (t-testing and F-testing)

% The F statistic is defined as F_0 = MSR/MSE, where MSR is the mean square
% of the regression.
%First we'll need the mean value of y.
y_bar = sum(y)/n;  %I'm aware mean() exists, writing equations out for clarity)
SSR = sum((y_hat-y_bar).^2);

% NOTE: for MSR, the dof = k (not including intercept term)
if FLAGS.glob_intercept==1 || FLAGS.tare_intercept==1
    dof_r = k-1;
else
    dof_r=k;
end
MSR = SSR/dof_r;

%F-statistic, F = MSR/MSE
F = MSR/MSE;
p_F = 1 - fcdf(F,dof_r,dof_e);
F_cr = finv(pct/100,dof_r,dof_e);
% F0 is the F-statistic of the Null Hypothesis, meaning that y is not a
% function of X at all. If F>F0, then we can reject the null hypothesis,
% and the data suggests that y is a function of X. in the function finv,
% the first input 0.05, is to calculate those tolerance with 95%
% confidence.
if F > F_cr
    %disp('We can reject the null hypothesis');
else
    disp('We cannot reject the null hypothesis');
end

%% T test for individual coefficients b_i
% The t statistic is the ration of a coefficient to its standard error
% The input to tinv is 0.975 is because it is a two-sided test. so .025 is
% subtracted from either end, meaning subtracting 0.05 total from both ends
% -> 95% confidence.
T = beta./se;
p_T = 2*(1 - tcdf(abs(T),dof_e));
T_cr = tinv(1-((1-(pct/100))/2),dof_e);
sig = ~((T<T_cr) & (T>-T_cr));
% If sig == 1, then that coefficient rejects the null hypothesis that b =
% 0, so the data suggests that the terms matters to this regression.
% NOTE: This is a test of statistical significance of a term IN A
% MODEL THAT INCLUDES ALL THE TERMS. In other words, the t-test might have
% different results depending on which all terms were included in the
% regression. Obviously multicollinearity will greatly affect how
% statistically significant or insignificant a term appears to be, given
% different data sets.

%% Confidence Intervals

% The confidence intervals for the coefficients are calculated as
beta_CI = T_cr.*se;

% confidence interval for the predicted values, must be calculated one data
% point at a time
for j = 1:n
    y_hat_CI(j,1) = T_cr*sqrt(sigma_hat_sq*X(j,:)*invXtX*X(j,:)');
end

%% Prediction Intervals
% Prediction intervals are different from confidence intervals. Confidence
% intervals are about how well we believe we regressed the given
% (calibration) data, prediction intervals would be giving a confidence
% interval for a new prediction, given new data.

for j = 1:n
    y_hat_PI(j,1) = T_cr*sqrt(sigma_hat_sq*(1+(X(j,:)*invXtX*X(j,:)')));
end

%% Measures of Model Adequacy
% Including R^2, adjusted R^2, PRESS, and PRESS R^2

% R^2 is calculated as the ratio of SSR to SST, or 1 - (SSE/SST), in either
% case, we'll need SST, which is just SSE + SSR;
SST = SSE + SSR;

% This bit has been commented out because it's no longer necessary.
% % to verify, we'll also calcualte SST the long way.
% SST_v = sum((y - y_bar).^2);
% % In the data set I used, I got a difference of O(e-5), so good enough.

R_sq = 1 - SSE/SST;

% Since R_sq increases as more terms are added to the model, adjusted R_sq
% takes degrees of freedom into account. = 1 - MSE/MST
dof_t = n-1;
MST = SST/dof_t;
R_sq_adj = 1 - MSE/MST;

% The PRESS residuals can be obtained using the diagonal elements of the
% hat matrix.
e_p = e./(1-diag(H));
PRESS = sum(e_p.^2);

% PRESS R_sq
R_sq_p = 1 - (PRESS/SST);

%% Calculate R-Student (externally studentized residual) 
%(Introduction to Linear Regression Analysis 5th Ed., Montgomery, Peck, Vining: pg 135)

Si_2=((dof_e*MSE-(e.^2))./(1-diag(H)))/(dof_e-1);
t=e./sqrt(Si_2.*(1-diag(H))); %R-student

%% Save all the relevant variables to a structure to pass out of the function

ANOVA.test     = 0;        % (to indicate that VIF < 4, so test term is not collinear)

ANOVA.beta     = beta;     % Coefficients
ANOVA.e        = e;        % Residuals

ANOVA.PRESS = PRESS;       % PRESS Statistic
ANOVA.F = F;               % F-value of regression
ANOVA.p_F = p_F;           % P-value of regression

ANOVA.R_sq = R_sq;         % R-square
ANOVA.R_sq_adj = R_sq_adj; % Adjusted R-Square
ANOVA.R_sq_p = R_sq_p;     % PRESS R-square

ANOVA.beta_CI  = beta_CI;  % Coefficient Confidence Intervals
ANOVA.T = T;               % T-statistic of coefficients
ANOVA.p_T = p_T;           % P-value of coefficients
ANOVA.VIF = VIF;           % Variance Inflation Factors
ANOVA.VIF_warn = VIF_warn; % Multicollinearity warning information
if noVIF_FLAG==0
%     ANOVA.VIF_dl=VIF_dl;
end
ANOVA.sig = sig;            %If term is significant

ANOVA.y_hat_PI=y_hat_PI; %Prediction interval for new datapoints

ANOVA.t=t; %R-Student
%% EXPERIMENTAL
% Saving variables to calculate prediction intervals live in approximation
ANOVA.PI.T_cr = T_cr;
ANOVA.PI.sigma_hat_sq = sigma_hat_sq;
if size(X,2)~=nterms
    ANOVA.PI.invXtX = pinv(X(:,1:nterms)'*X(:,1:nterms));
else
    ANOVA.PI.invXtX = invXtX;
end
ANOVA.PI.calc_pi = "T_cr*sqrt(sigma_hat_sq*(1+(x*invXtX*x')))";
ANOVA.PI.dof_e=dof_e;
%START TEST
% for j = 1:n
%     ANOVA.PI.TESTPI(j,1) = T_cr*sqrt(sigma_hat_sq*(1+(X(j,1:(size(X,2)-nseries))*ANOVA.PI.invXtX*X(j,1:(size(X,2)-nseries))')));
% end
%END TEST


%% Coded values for polynomial regressions
% Values of the variables are coded by centering or expressing the levels
% of the variable as deviations from the mean value of the variable and
% then scaling or dividing the deviations obtained by half the range of the
% variable. The reason for using coded predictor variables is that many
% times x and x^2 are highly correlated and, if uncoded values are used,
% there may be computational difficulties while calculating the (X'X)^-1
% matrix to obtain the estimates, beta, of the regression coefficients
% using the equation for the F distribution.

function VIF = vif(X, FLAGS)

% LEGACY VIF CALCULATION
% This code iterated through each input term and regressed it against the
% remaining terms to determine whether there was a linear dependency. The
% new method is much faster and accomplishes nearly identical results
% without iterating through all the terms. The new method depends on a
% matrix inversion, and because of the nature of the data, the inv()
% function does give less reliable results, but pinv appears to be mroe
% reliable. Due to the nature of large matrix inversions, the results are
% still usually different as far as the tare VIF's (which are mostly
% orthogonal by definition), but the difference has not proven to be
% significant.
% % [~,k] = size(X);
% % VIF = zeros(k,1);
% % for j = 1:k
% %     y = X(:,j);
% %     X_j = X; X_j(:,j) = []; %x_vif = [ones(n_data,1),x_vif];
% %     H = X_j*inv(X_j'*X_j)*X_j';
% % 
% %     y_bar = mean(y);
% %     y_hat = H*y;
% % 
% %     SSE = sum((y-y_hat).^2);
% %     SST = sum((y-y_bar).^2);
% % 
% %     R_sq = 1 - SSE/SST;
% %     VIF(j,1) = 1/(1-R_sq);
% % end

% As a correction, VIF's less than one are subtituted to equal one, since
% VIF<1 is theoretically nonsensical, it simply means that trying to find a
% linear correlation yielded a model that was less accurate thannot having
% a model at all -> totally linearly independent
VIF=ones(size(X,2),1);
difCol=~all(~diff(X)); %Find columns that have some variation
VIF(difCol)=max(diag(pinv(corrcoef(X(:,difCol)))),1);
% if FLAGS.glob_intercept==1
%     VIF = max(diag(pinv(corrcoef(X(:,2:end)))),1);
%     VIF=[1;VIF];
% else
%     VIF = max(diag(pinv(corrcoef(X))),1);
% end
%% Turn warnings back on
warning('on','all');
