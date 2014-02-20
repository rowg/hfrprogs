function [I,md,x,y,button] = ginput_grid_point_indices( gp, ginput_func, ...
                                                    dist_func, varargin )
% GINPUT_GRID_POINT_INDICES ginput that returns indices of grid points
% that are closest to selected points.
%
% Usage: [ I, mindist, x, y, button ] = ginput_grid_point_indices(
%                               grid_points, ginput_func, dist_func, ... )
%
% Inputs
% ------
% grid_points = a two column matrix of points.
% ginput_func = name of function to use for searching for points.
%               Typically 'ginput', but could also be 'm_ginput', for
%               example. Defaults to 'ginput' if absent or empty.
%               ginput_func can alternatively be a two column matrix of
%               points that will be used in lieu of calling a function
%               like ginput.
% dist_func = name of function used for calculating distance from selected
%             points to grid points.  Must accept arguments of the form
%             dist_func( x1, y1, x2, y2 ) and must behave similar to the
%             m_idist function. If empty or absent, then the standard
%             Euclidean distance will be used.
% ... = Arguments to ginput_func.  See that function for form of these
%       arguments.
%
% Outputs
% -------
% I = set of indices of closest grid points to each selected point.
% mindist = the distance from selected points to nearest grid point.
% x, y, button = standard set of return arguments from ginput.  These
%                should function similar to ginput itself.
%
% Example
% -------
% [I,mindist,ln,lt] = ginput_grid_point_indices( LonLat, 'm_ginput', ...
%                        'm_idist', 3 );
%
% This will pick three grid points among those in LonLat from an m_map
% plot.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: ginput_grid_point_indices.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2 || isempty( ginput_func )
  ginput_func = 'ginput';
end

if nargin < 3 || isempty( dist_func )
  dist_func = 'norm_dist_subfunc';
end

if isnumeric(ginput_func)
  [x,y,button] = deal( ginput_func(:,1), ginput_func(:,2), ...
                       repmat( NaN, size(ginput_func(:,1)) ) );
else
  [x,y,button] = feval( ginput_func, varargin{:} );
end

[md,I] = min( feval( dist_func, gp(:,1)', gp(:,2)', x(:), y(:) ), [], 2 );

if nargout < 5
  clear button
end

if nargout < 4
  x = [x,y];
  clear y
end

if nargout < 3
  clear x
end

%%%-----SUBFUNCTIONS---%%%
function d = norm_dist_subfunc( x1, y1, x2, y2 )
  d = sqrt( ( repmat( x1, size(x2) ) - repmat( x2, size(x1) ) ).^2 + ...
            ( repmat( y1, size(y2) ) - repmat( y2, size(y1) ) ).^2 );
  