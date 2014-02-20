function [V,notOnGrid] = griddata_nointerp(X,Y,x,y,v,dx,dy,flag)
% GRIDDATA_NOINTERP  Place data on user supplied grid within tolerance.
%
% Usage: [V,noV] = griddata_nointerp(X,Y,x,y,v,dx,dy,flag)
%
% Inputs
% ------
% X = x grid of values (P x Q)
% Y = y grid of values (P x Q) 
%     The X and Y matrices are ordered like the output of meshgrid:
%     [X,Y] = meshgrid(xvec,yvec);
% x = length N vector of x values
% y = length N vector of y values
% v = length N vector of values to grid. This function assumes that every 
%     X(i,j) and Y(i,j) will have at most 1 v mapped to it.  Defaults to 
%     1:length(x) if empty or absent (i.e., it defaults to an index that 
%     can be used later for multiple variables of the same size).
% dx = x tolerance.  |X-x(i)| <= dx for some gridpoint or v(i) not placed
%                    on grid.
% dy = y tolerance.  |Y-y(i)| <= dy for some gridpoint or v(i) not placed
%                    on grid.
%      Any v values outside of either dx or dy, or both will not be
%      gridded.
% flag = value to use for missing data values of grid.  Defaults to NaN.
%
% Outputs
% -------
% v = values on input X and Y grid.  Function doesn't handle multiple v
%     values at same grid location.  Last v(i) to be placed at a location 
%     will be the one used.  All others will be overwritten and lost.
% noV = [x,y,v] data whose x, y were outside of either dx or dy, or both
%       tolerances.
%
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Copyright (C) 2007 Mike Cook, Naval Postgraduate School
% License: GPL (Gnu Public License)
%
% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Issue to resolve:  A better way to indicate a value will overwrite a v
% already on the grid.  See note below.
%
% Mike Cook, NPS Oceanography Dept., 8 Feb 2007.

if ~exist('v','var') || isempty(v)
   v = 1:length(x);
end
if ~exist('flag','var')
    flag = NaN;
end

notOnGrid = [];

% Initialize all data to flag's, then fill with data where it exists.
V = repmat(flag,size(X));

for i = 1:length(v)
    % How far away are they and where are they?
    [xdiff,xi] = min(abs(X(1,:)-x(i)));
    [ydiff,yj] = min(abs(Y(:,1)-y(i)));
    
    if xdiff <= dx  &&  ydiff <= dy
        % Put on the grid, but check to see if another v value is there
        % already.
        if ( ~isfinite(flag) & isfinite(V(yj,xi)) ) | ...
              ( isfinite(flag) & V(yj,xi)~=flag )
            warning('%s: %g overwrites %g at V(%d,%d)\n',mfilename,v(i),V(yj,xi),yj,xi)
        end
        V(yj,xi) = v(i);
    else
        notOnGrid = [ notOnGrid; x(i),y(i),v(i) ];
    end
end
    
    