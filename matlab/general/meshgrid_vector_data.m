function [X,Y,V] = meshgrid_vector_data(x,y,v,flag)
% MESHGRID_VECTOR_DATA  Generates a rectangular grid for a vector of
% data points.
%
% Usage: [X,Y,V] = meshgrid_vector_data(x,y,v,flag)
% 
% NOTE: A typical use of this function is to grid radial data.  In this
% case, x would be a vector of ranges and y would be a vector of bearings.
%
% Inputs
% ------
% x = length N vector of x values
% b = length N vector of y values
% v = length N vector of values to grid. Defaults to 1:length(x) if empty or
%     absent (i.e., it defaults to an index that can be used later for
%     multiple variables of the same size).
% flag = value to use for missing data values of grid.  Defaults to NaN.
%
% Outputs
% -------
% X, Y, V are the gridded x, y and v (values).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: meshgrid_vector_data.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('v','var') || isempty(v)
   v = 1:length(x);
end
if ~exist('flag','var')
    flag = NaN;
end

% The grid is based on the extent of the data
[x,xI,xJ] = unique(x);
[y,yI,yJ] = unique(y);

% Make grid
[X,Y] = meshgrid(x,y);

% Initialize all data to flag's, then fill with data where it exists.
V = repmat(flag,size(X));
V( sub2ind( size(X), yJ, xJ ) ) = v;
