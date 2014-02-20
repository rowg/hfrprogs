function [m,n] = nanmean(x,dim)
%NANMEAN  Mean value, ignoring NaNs.
%
%USAGE:
%   [M,COUNT] = NANMEAN(X,DIM)
%
%   M = NANMEAN(X) returns the mean of X, treating NaNs as missing values.
%   For vector input, M is the mean value of the non-NaN elements
%   in X.  For matrices, M is a row vector containing the mean value of
%   non-NaN elements in each column.  For N-D arrays, NANMEAN operates
%   along the first non-singleton dimension.  
%
%   NANMEAN(X,DIM) returns the mean along dimension DIM of X.  DIM is
%   optional.   
%
%   [M,COUNT] = ... COUNT is the number of non-NaN data used in the mean 
%   calculation.
%
%   When X is empty or contains all NaN's along DIM, NANMEAN returns 
%   M = NaN and COUNT = 0.
%
%   This function is a modified version of a matlab stats toolbox function
%   of the same name.

%   Mike Cook, NPS Oceanography Dept., 6 Feb 2007

if nargin == 1 % let nansum deal with figuring out which dimension to use
    [s,n] = nansum(x);
else
    [s,n] = nansum(x,dim);
end

n(n==0) = NaN; % prevent divideByZero warnings
% Divide sum by number of data values.
m = s ./ n;

% Set count to 0 for all NaN's.
n(isnan(n)) = 0;
