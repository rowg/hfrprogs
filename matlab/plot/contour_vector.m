function [X,Y,Z] = contour_vector( x, y, z, cf, varargin )
% CONTOUR_VECTOR - makes a contour plot of vector data
%
% This function assumes you have data at a set of grid points that form
% an incomplete regular grid.  This data will then be placed on a
% complete rectangular grid and passed to the contour function.  The grid
% points must lie precisely on part of a regular grid to produce reasonable
% results.
%
% Usage: [C,H] = contour_vector( x, y, z, cont_function, ... )
%        [XI,YI,ZI] = contour_vector( x, y, z, cont_function, ... )
%
% C & H are as in the CONTOUR function; XI, YI and ZI are the grid used.
% XI and YI will be row and column vectors respectively.  
%
% cont_function is a string name or function handle of any of the contour
% functions.  It defaults to @contour if not given or empty ([]).  
%
% ... are extra arguments to that contour function.
%
% If the number of output arguments is greater than 2, no plot will be
% made and XI, YI and ZI will be returned.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: contour_vector.m 431 2007-05-28 22:07:33Z dmk $	
%
% Copyright (C) 2003 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
  cf = [];
end

if isempty(cf)
  cf = @contour;
end

x = x(:); y = y(:); z = z(:);

xx = sort(unique(x));
xx = xx(:)';
yy = sort(unique(y));

ZI = NaN * zeros( size(xx) + size(yy) - 1 );

for j = 1:length(x)
  I = find( xx == x(j) );
  J = find( yy == y(j) );
  
  ZI(J,I) = z(j);
end

if nargout < 3
  [XI,YI] = meshgrid(xx,yy);
  [X,Y] = feval( cf, XI, YI, ZI, varargin{:} );
else
  [X,Y,Z] = deal( xx, yy, ZI );
end

if nargout < 2
  clear Y
end

if nargout < 1
  clear X
end
