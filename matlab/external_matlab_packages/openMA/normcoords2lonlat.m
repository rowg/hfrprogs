function [ln,lt,xkm,ykm] = normcoords2lonlat( origin, xy, area )
% NORMCOORDS2LONLAT - converts normalized coordinates to lonlat
%
% This function converts between a set of normalized coordinates where
% the domain has unit area to lon,lat coordinates.  These normalized
% coordinates are often used for generating modes as a domain of unit
% area is often numerically easier to deal with and eigenvalues can be
% compared with those of the unit square, which is well understood.
%
% Usage: [ lon, lat, xkm, ykm ] = normcoords2lonlat( origin, xy, area )
%
% where origin is a lonlat pair with the origin of Km coordinate system,
% xy is a column matrix with coordinates in normalized system, and area is the
% area of the OMA domain.
%
% Will also return Km coordinates if desired.
%
% NOTE also that this function requires the km2lonlat function from Mike
% Cook's HFradarmap toolbox.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: normcoords2lonlat.m 70 2007-02-22 02:24:34Z dmk $	
%
% Copyright (C) 2005 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[xkm,ykm] = deal( xy(:,1) * sqrt(area), xy(:,2) * sqrt(area) );
[ln,lt] = km2lonlat( origin(1), origin(2), xkm, ykm );

if nargout < 4
  clear ykm
end

if nargout < 3
  clear xkm
end
