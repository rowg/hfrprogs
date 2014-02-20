function [y,n] = nansum(x,dim)
%NANSUM  Sum values, ignoring NaNs.
%
%USAGE:
%   [M,COUNT] = NANSUM(X,DIM)
%
%   M = NANSUM(X) returns the sum of X, treating NaNs as missing values.
%   For vector input, M is the sum value of the non-NaN elements
%   in X.  For matrices, M is a row vector containing the sum value of
%   non-NaN elements in each column.  For N-D arrays, NANSUM operates
%   along the first non-singleton dimension.  
%
%   NANSUM(X,DIM) returns the sum along dimension DIM of X.  DIM is
%   optional.   
%
%   [M,COUNT] = ... COUNT is the number of non-NaN data used in the sum 
%   calculation.
%
%   When X is empty or contains all NaN's along DIM, NANSUM returns 
%   M = 0 and COUNT = 0.
%
%   This function is a modified version of a matlab stats toolbox function
%   of the same name.

%   Mike Cook, NPS Oceanography Dept., 6 Feb 2007

% Find NaNs and set them to zero.  Then sum up non-NaNs.  Cols of all NaNs
% will return a sum of zero.
nans = isnan(x);
x(nans) = 0;

if nargin == 1 % let sum figure out which dimension to work along
    % Count up non-NaNs.
    n = sum(~nans);
    y = sum(x);
else           % work along the explicitly given dimension
    % Count up non-NaNs.
    n = sum(~nans,dim);
    y = sum(x,dim);
end
