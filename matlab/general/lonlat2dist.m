function d = lonlat2dist( c1, c2 )
% LONLAT2DIST  Computes distance in kms between points.
%
% Usage: dist = lonlat2dist( coords1, coords2 )
%
% coords1 and coords2 should have the lon, lat coordinates of the points
% you want the distance between.
%
% If coords1 and coords2 have the same size and shape, the distances
% between individual points will be computed.  If one of them is a 2xM
% size matrix and the other is a Nx2 size matrix, then the result will be
% a MxN matrix with the distances between all possible combinations of
% points.  Note that this system has problems precisely when one is
% dealing with 2 coordinate pairs.
%
% If coords2 is not given, it will be set to coords1'
%
% NOTE: that this function uses lonlat2km to calculated x,y offsets
% between points.  A single original is used for all such calculations.
% The first grid point of the first argument to the function will be used
% as that origin.  This will generate errors for large spatial
% separations.  In these cases, a more complicated greatest circle
% algorithm should be used instead.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: lonlat2dist.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2
  c2 = c1';
end

% Case with two vectors of coordinates.
if all( size(c1) == size(c2) ) 

  if size(c1,2) == 2 
    tf = 0;
  else % Transpose if there are 2 rows.
    c1 = c1';
    c2 = c2';
    tf = 1;
  end
  
  [ x1, y1 ] = lonlat2km( c1(1,1), c1(1,2), c1(:,1), c1(:,2) );
  [ x2, y2 ] = lonlat2km( c1(1,1), c1(1,2), c2(:,1), c2(:,2) );
    
  d = sqrt( ( x1 - x2 ) .^2 + ( y1 - y2 ) .^2 );

  if tf
    d = d';
  end
elseif ( size(c1,2) == 2 ) & ( size(c2,1) == 2 )
  c2 = c2';
  [ x1, y1 ] = lonlat2km( c1(1,1), c1(1,2), c1(:,1), c1(:,2) );
  
  [ x2, y2 ] = lonlat2km( c1(1,1), c1(1,2), c2(:,1), c2(:,2) );
  
  d = dist( x1, y1, x2', y2' );
  
elseif ( size(c1,1) == 2 ) & ( size(c2,2) == 2 )
  c1 = c1';
  [ x2, y2 ] = lonlat2km( c1(1,1), c1(1,2), c2(:,1), c2(:,2) );
  
  [ x1, y1 ] = lonlat2km( c1(1,1), c1(1,2), c1(:,1), c1(:,2) );
  
  d = dist( x1', y1', x2, y2 );
else
  error( 'HFRC_utility - Don''t know what to do with input arguments.' );
end
