function d = dist( x1, y1, x2, y2 )
% DIST  Computes distance in between points in euclidean space.
%
% Usage: d = dist( x1, y1, x2, y2 )
%        d = dist( x1, x2 )
%
% For the first form, x1 and y1 must have the same size.  The same goes
% for x2 and y2.  x1 and x2 can either have the same size, or one can be a
% row vector and the other a column vector. In the prior case, the
% Euclidean distance in the plane is calculated between [x1,y1] and 
% [x2,y2].  In the second case, the distance between all possible point
% pairs is calculated (ie. if x1 is a row vector of length N and x2 is a
% column vector of length M, the result will be a matrix of size NxM with
% the distance between all possible combinations of [x1, y1] and [x2,y2].  
%
% The second case is computationally equivalent to 
%        d = dist( x1, 0 * x1, x2, 0 * x2 )
% and is a slow, but legitimate way of computing distance on the line.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: dist.m 396 2007-04-02 16:56:29Z mcook $	
%
% Copyright (C) 2001 David M. Kaplan
% Licence: GPL
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin == 2
  x2 = y1;
  y2 = 0 * x2;
  y1 = 0 * x1;
end

if any( size(x1) ~= size(y1) ) | any( size(x2) ~= size(y2) )
  error( 'HFRC_utility - Sizes do not match.' );
end

% Case with two matrices of coordinates.
if all( size(x1) == size(x2) ) 

  d = sqrt( ( x1 - x2 ) .^2 + ( y1 - y2 ) .^2 );

elseif ( size(x1,2) == 1 ) & ( size(x2,1) == 1 ) % Row and column vectors
  x1 = repmat( x1, size(x2) );
  y1 = repmat( y1, size(y2) );
  x2 = repmat( x2, [ size(x1,1), 1 ] );
  y2 = repmat( y2, [ size(y1,1), 1 ] );

  d = sqrt( ( x1 - x2 ) .^2 + ( y1 - y2 ) .^2 );
elseif ( size(x1,1) == 1 ) & ( size(x2,2) == 1 )
  x2 = repmat( x2, size(x1) );
  y2 = repmat( y2, size(y1) );
  x1 = repmat( x1, [ size(x2,1), 1 ] );
  y1 = repmat( y1, [ size(y2,1), 1 ] );
  
  d = sqrt( ( x1 - x2 ) .^2 + ( y1 - y2 ) .^2 );
else
  error( 'HFRC_utility - Don''t know what to do with input arguments.' );
end
