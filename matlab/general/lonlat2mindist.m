function [dd,I] = lonlat2mindist( c1, c2, d )
% LONLAT2MINDIST  Computes minimum distances in kms between points.
%
% Usage: [dist,indices] = lonlat2mindist( coords1, coords2, DIM )
%
% coords1 and coords2 should have the lon, lat coordinates of the points
% you want the distance between.
%
% One of coords1 and coords2 should be a 2xM size matrix and the other
% should be a Nx2 size matrix.  This function will then use lonlat2dist
% to compute the distance between all pairs of points.  Then min will be
% used to find the point with the minimum distance along dimension DIM.
% If DIM is not given, then the short dimension of coords1 will be used.
%
% This function will have problems determining DIM automatically if
% coords1 is a 2x2 matrix.  In that case, specify DIM explicitly and make
% the columns of coords1 longitude and latitude, respectively.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: lonlat2mindist.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 3
  [m,d] = min(size(c1));
end

dd = lonlat2dist( c1, c2 );

[dd,I] = min( dd, [], d );

if nargout < 2
  clear I
end
