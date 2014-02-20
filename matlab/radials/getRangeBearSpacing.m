function [rs,bs] = getRangeBearSpacing( s, n )
% GETRANGEBEARSPACING Get info about spacing of radial grids
%
% This function returns information about the range and bearing spacing
% of a radial grid.  This is useful for interpolation and placing radial
% data on a regular grid.
%
% Usage: [RangeSpacing,BearSpacing] = getRangeBearSpacing( RBH, n )
%
% Inputs:
% ------
% RBH = Can either be a matrix with at least two columns for the range
%       and bearing of each radial grid point, or it can be an array of
%       structures, each of which has a field called RangeBearHead
%       (typically a RADIAL structure).
% n = number of decimals places to round range and bearing to when
%     calculating mode of spacing.  Can either have 1 or 2 elements.
%     Defaults to 10.
%
% Outputs:
% -------
% RangeSpacing, BearSpacing = if RBH was a matrix, then each of these
%    will be a 5 element vector with the min spacing, max spacing, mode
%    spacing (after rounding), min range or bearing, and max range or
%    bearing.  If RBH was a structure array, then this will be a matrix
%    with one row for each structure in the array and 5 columns.
%
% NOTE: Range stats are based on all available ranges.  Bearing stats are
% based on the range bin that had the most bearings in it (i.e., the
% fullest range bin).  Rounding is needed to calculate a mode for a
% potentially continuous variable like range, but is often unnecessary if
% the range and bearing separations are precisely the same.
%
% NOTE: This function will typically return NaN's for bearing spacings
% for elliptical data as range rings don't really exist.  This could
% probably be fixed by replacing the Range column in RangeBearHead with a
% different variable that indicates the total travel distance of the
% signal.
%
% NOTE: Bearing min's and max's should be interpreted with care.  If the set
% of angle bearings runs from 0 to 360 (as opposed to -180 to 180), and the
% angles span the 0 degree banner then the min,max straightforward min will
% typically be close to 0,360.  As an attempt to deal with this, this
% function checks all four cardinal directions to see which "0 degree
% line" gives the smallest angle span.  The min,max for this direction
% (after converting back to the normal 0 degree line) is returned.  As
% such, min > max in the numerical sense is possible, and angleVector
% should always be used to generate angle spans with the limits.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: getRangeBearSpacing.m 429 2007-05-22 18:53:22Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% License: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist( 'n', 'var' )
  n = 10;
end

if numel(n) == 1
  n = [n,n];
end

[ rs, bs ] = deal( [] );

% Deal with multiple structures
if isstruct(s) && numel(s) > 1
  for k = 1:numel(s)
    [rr,bb] = feval( mfilename, s(k) );
    rs = [ rs; rr ];
    bs = [ bs; bb ];
  end
  return
end

% Deal with single structure
if ~isnumeric(s)
  ss = s.RangeBearHead;
  clear s
  s = ss;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Range
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ru = unique( s(:,1) );

% Round range values to certain number of decimals
[rur,rI,rJ] = unique( round(10^n(1) * s(:,1) ) / 10^n(1) );

dr = diff( ru );
drr = diff( rur );

% Min, max and mode spacing
rs(1:3) = [ min(dr), max(dr), mode(drr) ];

% min and max ranges
rs(4:5) = [ min(ru), max(ru) ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bearing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find most common range.
m = mode(rJ);

% Get angles for that range
br = sort( s(rJ == m,2) );
brr = round( 10^n(2) * br ) / 10^n(2);

db = diff(br);
dbr = diff(brr);

% Min, max and mode spacing
bs(1:3) = [ min(db), max(db), mode(dbr) ];

% Min and max angle
n = [0,90,180,270];
ss = mod([ s(:,2) + n(1), s(:,2) + n(2), s(:,2) + n(3), s(:,2) + n(4) ], 360);
m = [ min(ss); max(ss) ];
[mm,I] = min( diff( m ) );
m = mod( m(:,I) - n(I), 360 );
bs(4:5) = m(:)';

