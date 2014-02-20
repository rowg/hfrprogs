function [dd,I] = mindist( x1, y1, x2, y2, d )
% MINDIST  Computes minimum distances between points.
%
% Usage: [dist,indices] = mindist( x1, y2, x2, y2, DIM )
%
% x1 and y1 should be of the same size, as should x2 and y2.  One of x1
% and x2 should be a row vector, the other should be a column vector.
%
% DIM is the dimension over which to find the minimum.  If not given, the
% short dimension of x1 will be used.
%
% This function will have problems determining DIM automatically if
% x1 is a scalar.  In that case, specify DIM explicitly.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: mindist.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4
  error( 'This function requires 4 arguments.' );
end

if nargin < 5
  [m,d] = min(size(x1));
end

dd = dist( x1, y1, x2, y2 );

[dd,I] = min( dd, [], d );

if nargout < 2
  clear I
end
